import 'dart:async';
import 'dart:convert';
import 'dart:io';

const defaultRequestTimeout = Duration(seconds: 15);

enum Indexing { noindex, indexable }

class SmokeResult {
  const SmokeResult.pass(this.message) : ok = true;
  const SmokeResult.fail(this.message) : ok = false;

  final bool ok;
  final String message;

  @override
  String toString() => '${ok ? 'PASS' : 'FAIL'}: $message';
}

Uri normalizeBase(Uri base) =>
    base.path.endsWith('/') ? base : base.replace(path: '${base.path}/');

Uri wwwOf(Uri base) => Uri(
  scheme: base.scheme,
  host: 'www.${base.host}',
  port: base.hasPort ? base.port : null,
  path: '/',
);

Future<SmokeResult> checkRedirect(
  Uri from,
  Uri to,
  HttpClient client, {
  Duration timeout = defaultRequestTimeout,
}) async {
  final request = await client.getUrl(from).timeout(timeout);
  request.followRedirects = false;
  final response = await request.close().timeout(timeout);
  await response.drain<void>().timeout(timeout);
  if (response.statusCode != HttpStatus.movedPermanently) {
    return SmokeResult.fail(
      'expected 301 from $from, got ${response.statusCode}',
    );
  }
  final location = response.headers.value(HttpHeaders.locationHeader);
  if (location == null || normalizeBase(from.resolve(location)) != to) {
    return SmokeResult.fail('$from redirects to "$location", expected $to');
  }
  return SmokeResult.pass('$from redirects 301 to $to');
}

class _Response {
  const _Response(this.status, this.headers, this.body);

  final int status;
  final HttpHeaders headers;
  final String body;
}

Future<_Response> _get(HttpClient client, Uri uri, Duration timeout) async {
  final request = await client.getUrl(uri).timeout(timeout);
  final response = await request.close().timeout(timeout);
  final body = await response
      .transform(const Utf8Decoder(allowMalformed: true))
      .join()
      .timeout(timeout);
  return _Response(response.statusCode, response.headers, body);
}

Future<SmokeResult> checkOnce(
  Uri base,
  String expectedSha,
  Indexing indexing,
  HttpClient client, {
  Duration timeout = defaultRequestTimeout,
  Uri? redirectFrom,
}) async {
  final root = normalizeBase(base);

  final page = await _get(client, root, timeout);
  if (page.status != HttpStatus.ok) {
    return SmokeResult.fail('GET $root returned ${page.status}');
  }

  final robots = page.headers.value('x-robots-tag') ?? '';
  final hasNoindex = robots.toLowerCase().contains('noindex');
  if (indexing == Indexing.noindex && !hasNoindex) {
    return SmokeResult.fail(
      'expected "X-Robots-Tag: noindex" on $root, got "$robots"',
    );
  }
  if (indexing == Indexing.indexable && hasNoindex) {
    return SmokeResult.fail(
      'site must be indexable but $root sends "X-Robots-Tag: $robots"',
    );
  }

  final infoUri = root
      .resolve('build-info.json')
      .replace(
        queryParameters: {'t': '${DateTime.now().microsecondsSinceEpoch}'},
      );
  final info = await _get(client, infoUri, timeout);
  if (info.status != HttpStatus.ok) {
    return SmokeResult.fail('GET $infoUri returned ${info.status}');
  }

  final Object? decoded;
  try {
    decoded = jsonDecode(info.body);
  } on FormatException {
    return SmokeResult.fail(
      '$infoUri is not JSON; build-info.json is probably missing and the '
      'SPA fallback page was served',
    );
  }
  if (decoded is! Map || decoded['sha'] is! String) {
    return SmokeResult.fail('$infoUri has no "sha" field');
  }
  final liveSha = decoded['sha'] as String;
  if (liveSha != expectedSha) {
    return SmokeResult.fail('live sha $liveSha != expected $expectedSha');
  }

  final langAttr = RegExp(r'<html[^>]*\blang="([^"]*)"');
  String? langOf(String body) => langAttr.firstMatch(body)?.group(1);

  if (langOf(page.body) != 'en') {
    return SmokeResult.fail('expected <html lang="en"> on $root');
  }

  final ptUri = root.resolve('pt');
  final pt = await _get(client, ptUri, timeout);
  if (pt.status != HttpStatus.ok) {
    return SmokeResult.fail(
      'GET /pt returned status ${pt.status} (expected 200)',
    );
  }
  if (langOf(pt.body) != 'pt-BR') {
    return SmokeResult.fail(
      'expected <html lang="pt-BR"> on /pt, got status ${pt.status} and lang '
      '"${langOf(pt.body)}"',
    );
  }

  final unknownUri = root.resolve(
    'does-not-exist-${DateTime.now().microsecondsSinceEpoch}',
  );
  final unknown = await _get(client, unknownUri, timeout);
  if (unknown.status != HttpStatus.notFound) {
    return SmokeResult.fail(
      'expected HTTP 404 for an unknown path, got ${unknown.status}',
    );
  }
  if (!unknown.body.contains('Página não encontrada.')) {
    return SmokeResult.fail('the 404 page is not the branded one');
  }

  final wasm = await _get(client, root.resolve('main.dart.wasm'), timeout);
  final wasmType = wasm.headers.contentType?.mimeType ?? '';
  if (wasm.status != HttpStatus.ok ||
      !wasmType.startsWith('application/wasm')) {
    return SmokeResult.fail(
      'main.dart.wasm must be 200 application/wasm, got ${wasm.status} '
      '"$wasmType"',
    );
  }

  final boot = await _get(
    client,
    root.resolve('flutter_bootstrap.js'),
    timeout,
  );
  final bootType = boot.headers.contentType?.mimeType ?? '';
  if (boot.status != HttpStatus.ok || !bootType.contains('javascript')) {
    return SmokeResult.fail(
      'flutter_bootstrap.js must be 200 with a javascript content type, got '
      '${boot.status} "$bootType"',
    );
  }

  if (redirectFrom != null) {
    final redirect = await checkRedirect(
      redirectFrom,
      root,
      client,
      timeout: timeout,
    );
    if (!redirect.ok) return redirect;
  }

  return SmokeResult.pass(
    '$root serves $expectedSha (version ${decoded['version']}); checked '
    '/ (en), /pt (pt-BR), the branded 404, main.dart.wasm and '
    'flutter_bootstrap.js types'
    '${redirectFrom == null ? '' : ', and $redirectFrom redirects here'}',
  );
}

Future<SmokeResult> smoke(
  Uri base,
  String expectedSha,
  Indexing indexing, {
  int attempts = 5,
  Duration delay = const Duration(seconds: 6),
  Duration requestTimeout = defaultRequestTimeout,
  HttpClient? client,
  bool expectWwwRedirect = false,
}) async {
  final http = client ?? HttpClient();
  var result = const SmokeResult.fail('no attempt was made');
  try {
    for (var i = 1; i <= attempts; i++) {
      try {
        result = await checkOnce(
          base,
          expectedSha,
          indexing,
          http,
          timeout: requestTimeout,
          redirectFrom: expectWwwRedirect ? wwwOf(base) : null,
        );
      } on IOException catch (e) {
        result = SmokeResult.fail('network error: $e');
      } on TimeoutException {
        result = SmokeResult.fail(
          'request timed out after ${requestTimeout.inMilliseconds} ms',
        );
      }
      if (result.ok) return result;
      stderr.writeln('attempt $i/$attempts: $result');
      if (i < attempts) await Future<void>.delayed(delay * i);
    }
    return result;
  } finally {
    if (client == null) http.close(force: true);
  }
}

({Uri url, String sha, Indexing indexing, bool expectWwwRedirect})? parseArgs(
  List<String> args,
) {
  if (args.length < 3 || args.length > 4) return null;
  final indexing = switch (args[2]) {
    '--expect-noindex' => Indexing.noindex,
    '--expect-indexable' => Indexing.indexable,
    _ => null,
  };
  if (indexing == null) return null;
  if (args.length == 4 && args[3] != '--expect-www-redirect') return null;
  return (
    url: Uri.parse(args[0]),
    sha: args[1],
    indexing: indexing,
    expectWwwRedirect: args.length == 4,
  );
}

Future<void> main(List<String> args) async {
  final parsed = parseArgs(args);
  if (parsed == null) {
    stderr.writeln(
      'usage: dart run tool/ci/smoke.dart <url> <sha> '
      '--expect-noindex|--expect-indexable [--expect-www-redirect]',
    );
    exitCode = 64;
    return;
  }
  final result = await smoke(
    parsed.url,
    parsed.sha,
    parsed.indexing,
    expectWwwRedirect: parsed.expectWwwRedirect,
  );
  stdout.writeln(result);
  exitCode = result.ok ? 0 : 1;
}
