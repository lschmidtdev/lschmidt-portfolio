import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../../tool/ci/smoke.dart';

void main() {
  late HttpServer server;
  late Uri base;
  late HttpClient client;
  late List<Uri> requests;
  late void Function(HttpRequest) handler;

  setUp(() async {
    requests = [];
    server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    base = Uri.parse('http://${server.address.host}:${server.port}/');
    server.listen((request) {
      requests.add(request.uri);
      handler(request);
    });
    client = HttpClient();
  });

  tearDown(() async {
    client.close(force: true);
    await server.close(force: true);
  });

  void site({
    String sha = 'abc',
    bool noindex = true,
    bool hasInfo = true,
    String enLang = 'en',
    String ptLang = 'pt-BR',
    int ptStatus = 200,
    int unknownStatus = 404,
    String unknownBody = '<h1>Página não encontrada.</h1>',
    String wasmType = 'application/wasm',
    String jsType = 'text/javascript',
    int wwwStatus = 301,
    String? wwwLocation,
  }) {
    handler = (request) {
      final response = request.response;
      if (noindex) response.headers.set('x-robots-tag', 'noindex');
      final path = request.uri.path;
      if (path.endsWith('/build-info.json')) {
        if (hasInfo) {
          response.headers.contentType = ContentType.json;
          response.write(jsonEncode({'sha': sha, 'version': '0.1.0'}));
        } else {
          response.headers.contentType = ContentType.html;
          response.write('<!DOCTYPE html><html lang="$enLang"></html>');
        }
      } else if (path == '/' || path == '/index.html') {
        response.headers.contentType = ContentType.html;
        response.write('<!DOCTYPE html><html lang="$enLang"></html>');
      } else if (path == '/pt' || path == '/pt/') {
        response.statusCode = ptStatus;
        response.headers.contentType = ContentType.html;
        response.write('<!DOCTYPE html><html lang="$ptLang"></html>');
      } else if (path.endsWith('main.dart.wasm')) {
        response.headers.set('content-type', wasmType);
        response.add([0x00, 0x61, 0x73, 0x6d, 0x01, 0x00, 0x00, 0x00, 0xff]);
      } else if (path.endsWith('flutter_bootstrap.js')) {
        response.headers.set('content-type', jsType);
        response.write('js');
      } else if (path == '/www/') {
        response.statusCode = wwwStatus;
        if (wwwLocation != null) response.headers.set('location', wwwLocation);
      } else {
        response.statusCode = unknownStatus;
        response.headers.contentType = ContentType.html;
        response.write(unknownBody);
      }
      response.close();
    };
  }

  test('passes a full M5 site', () async {
    site();
    final result = await checkOnce(base, 'abc', Indexing.noindex, client);
    expect(result.ok, isTrue, reason: result.message);
  });

  for (final (name, broken, needle) in [
    (
      'wrong EN lang',
      () => site(enLang: 'pt-BR'),
      'expected <html lang="en"> on',
    ),
    (
      'wrong PT lang',
      () => site(ptLang: 'en'),
      'expected <html lang="pt-BR"> on /pt, got status 200 and lang "en"',
    ),
    (
      'PT not 200',
      () => site(ptStatus: 502),
      'GET /pt returned status 502 (expected 200)',
    ),
    ('soft 404 (SPA fallback)', () => site(unknownStatus: 200), '404'),
    ('unbranded 404', () => site(unknownBody: 'Not Found'), 'branded'),
    (
      'wasm content type',
      () => site(wasmType: 'application/octet-stream'),
      'application/wasm',
    ),
    ('bootstrap content type', () => site(jsType: 'text/plain'), 'javascript'),
  ]) {
    test('fails on $name and says why', () async {
      broken();
      final result = await checkOnce(base, 'abc', Indexing.noindex, client);
      expect(result.ok, isFalse);
      expect(result.message, contains(needle));
    });
  }

  test(
    'the unknown path is random, so a CDN cannot cache a lucky 404',
    () async {
      site();
      await checkOnce(base, 'abc', Indexing.noindex, client);
      await checkOnce(base, 'abc', Indexing.noindex, client);
      final unknown = requests
          .map((u) => u.path)
          .where((p) => p.contains('does-not-exist'))
          .toSet();
      expect(unknown, hasLength(2));
    },
  );

  test('passes when the live SHA matches and noindex is expected', () async {
    site();
    final result = await checkOnce(base, 'abc', Indexing.noindex, client);
    expect(result.ok, isTrue, reason: result.message);
  });

  test('fails on a SHA mismatch and names both SHAs', () async {
    site(sha: 'old');
    final result = await checkOnce(base, 'new', Indexing.noindex, client);
    expect(result.ok, isFalse);
    expect(result.message, allOf(contains('old'), contains('new')));
  });

  test('fails when noindex is expected but missing', () async {
    site(noindex: false);
    final result = await checkOnce(base, 'abc', Indexing.noindex, client);
    expect(result.ok, isFalse);
    expect(result.message, contains('noindex'));
  });

  test('fails when production sends noindex', () async {
    site();
    final result = await checkOnce(base, 'abc', Indexing.indexable, client);
    expect(result.ok, isFalse);
    expect(result.message, contains('indexable'));
  });

  test('passes an indexable site that sends no robots header', () async {
    site(noindex: false);
    final result = await checkOnce(base, 'abc', Indexing.indexable, client);
    expect(result.ok, isTrue, reason: result.message);
  });

  test(
    'fails clearly when build-info.json is missing (SPA fallback)',
    () async {
      site(hasInfo: false);
      final result = await checkOnce(base, 'abc', Indexing.noindex, client);
      expect(result.ok, isFalse);
      expect(result.message, contains('not JSON'));
    },
  );

  test('fails when the page is not HTTP 200', () async {
    handler = (request) {
      request.response.statusCode = HttpStatus.notFound;
      request.response.close();
    };
    final result = await checkOnce(base, 'abc', Indexing.noindex, client);
    expect(result.ok, isFalse);
    expect(result.message, contains('404'));
  });

  test('cache-busts build-info.json', () async {
    site();
    await checkOnce(base, 'abc', Indexing.noindex, client);
    final info = requests.firstWhere(
      (u) => u.path.endsWith('/build-info.json'),
    );
    expect(info.queryParameters, contains('t'));
  });

  test('resolves build-info.json under a base path without a slash', () async {
    site();
    final withPath = base.replace(path: '/pt');
    await checkOnce(withPath, 'abc', Indexing.noindex, client);
    expect(requests.map((u) => u.path), contains("/pt/build-info.json"));
  });

  test('normalizeBase adds a trailing slash', () {
    expect(normalizeBase(Uri.parse('https://x.web.app')).path, '/');
    expect(normalizeBase(Uri.parse('https://x.web.app/pt')).path, '/pt/');
    expect(normalizeBase(Uri.parse('https://x.web.app/')).path, '/');
  });

  test('retries until a stale CDN catches up', () async {
    var infoCalls = 0;
    site(sha: 'old');
    final stale = handler;
    handler = (request) {
      if (request.uri.path.endsWith('/build-info.json')) infoCalls++;
      if (infoCalls >= 3) site(sha: 'new');
      (infoCalls >= 3 ? handler : stale)(request);
    };
    final result = await smoke(
      base,
      'new',
      Indexing.noindex,
      attempts: 5,
      delay: Duration.zero,
      client: client,
    );
    expect(result.ok, isTrue, reason: result.message);
  });

  test('gives up after the configured attempts', () async {
    site(sha: 'old');
    final result = await smoke(
      base,
      'new',
      Indexing.noindex,
      attempts: 3,
      delay: Duration.zero,
      client: client,
    );
    expect(result.ok, isFalse);
    expect(
      requests.where((u) => u.path.endsWith('/build-info.json')),
      hasLength(3),
    );
  });

  test(
    'a server that never answers fails with "timed out", not a hang',
    () async {
      handler = (request) {};
      final result = await smoke(
        base,
        'abc',
        Indexing.noindex,
        attempts: 1,
        delay: Duration.zero,
        requestTimeout: const Duration(milliseconds: 200),
        client: client,
      );
      expect(result.ok, isFalse);
      expect(result.message, contains('timed out'));
    },
    timeout: const Timeout(Duration(seconds: 5)),
  );

  test(
    'checkOnce throws TimeoutException past its timeout',
    () async {
      handler = (request) {};
      await expectLater(
        checkOnce(
          base,
          'abc',
          Indexing.noindex,
          client,
          timeout: const Duration(milliseconds: 200),
        ),
        throwsA(isA<TimeoutException>()),
      );
    },
    timeout: const Timeout(Duration(seconds: 5)),
  );

  group('www redirect', () {
    test('wwwOf builds the www root of a bare domain', () {
      expect(
        wwwOf(Uri.parse('https://zirkon.com.br')),
        Uri.parse('https://www.zirkon.com.br/'),
      );
      expect(
        wwwOf(Uri.parse('https://zirkon.com.br/')),
        Uri.parse('https://www.zirkon.com.br/'),
      );
    });

    test(
      'passes a 301 to the root, with or without a trailing slash',
      () async {
        final withSlash = base.toString();
        final withoutSlash = withSlash.substring(0, withSlash.length - 1);
        for (final location in [withSlash, withoutSlash]) {
          site(noindex: false, wwwLocation: location);
          final result = await checkOnce(
            base,
            'abc',
            Indexing.indexable,
            client,
            redirectFrom: base.resolve('www/'),
          );
          expect(result.ok, isTrue, reason: '$location: $result');
        }
      },
    );

    test('fails when www is served directly instead of redirected', () async {
      site(noindex: false, wwwStatus: 200);
      final result = await checkOnce(
        base,
        'abc',
        Indexing.indexable,
        client,
        redirectFrom: base.resolve('www/'),
      );
      expect(result.ok, isFalse);
      expect(result.message, contains('expected 301'));
      expect(result.message, contains('got 200'));
    });

    test('fails on a temporary (302) redirect', () async {
      site(noindex: false, wwwStatus: 302, wwwLocation: base.toString());
      final result = await checkOnce(
        base,
        'abc',
        Indexing.indexable,
        client,
        redirectFrom: base.resolve('www/'),
      );
      expect(result.ok, isFalse);
      expect(result.message, contains('got 302'));
    });

    test('fails when www redirects somewhere else', () async {
      site(noindex: false, wwwLocation: base.resolve('en').toString());
      final result = await checkOnce(
        base,
        'abc',
        Indexing.indexable,
        client,
        redirectFrom: base.resolve('www/'),
      );
      expect(result.ok, isFalse);
      expect(result.message, contains('expected $base'));
    });

    test('is skipped when no redirect source is given', () async {
      site(noindex: false);
      final result = await checkOnce(base, 'abc', Indexing.indexable, client);
      expect(result.ok, isTrue, reason: '$result');
      expect(requests.map((u) => u.path), isNot(contains('/www/')));
    });
  });

  group('parseArgs', () {
    test('reads the url, sha and indexing flag', () {
      final args = parseArgs(['https://x.test', 'abc', '--expect-noindex'])!;
      expect(args.url, Uri.parse('https://x.test'));
      expect(args.sha, 'abc');
      expect(args.indexing, Indexing.noindex);
      expect(args.expectWwwRedirect, isFalse);
    });

    test('accepts --expect-www-redirect as a fourth argument', () {
      final args = parseArgs([
        'https://x.test',
        'abc',
        '--expect-indexable',
        '--expect-www-redirect',
      ])!;
      expect(args.indexing, Indexing.indexable);
      expect(args.expectWwwRedirect, isTrue);
    });

    test('rejects missing, unknown or misplaced flags', () {
      expect(parseArgs(['u', 's']), isNull);
      expect(parseArgs(['u', 's', '--expect-www-redirect']), isNull);
      expect(parseArgs(['u', 's', '--expect-indexable', '--bogus']), isNull);
      expect(
        parseArgs([
          'u',
          's',
          '--expect-indexable',
          '--expect-www-redirect',
          'extra',
        ]),
        isNull,
      );
    });
  });
}
