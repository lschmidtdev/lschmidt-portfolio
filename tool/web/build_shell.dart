import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';

import 'package:lschmidt_portfolio/config/site_config.dart';

enum ShellLocale {
  en('en', 'en_US', '/'),
  pt('pt-BR', 'pt_BR', '/pt');

  const ShellLocale(this.lang, this.ogLocale, this.path);

  final String lang;

  final String ogLocale;

  final String path;

  ShellLocale get other => this == en ? pt : en;

  String get arbFile => 'lib/l10n/app_$name.arb';
}

class ShellConfig {
  const ShellConfig({
    required this.origin,
    required this.email,
    this.umamiWebsiteId = '',
  });

  ShellConfig.fromSiteConfig()
    : origin = SiteConfig.siteUrl,
      email = SiteConfig.email,
      umamiWebsiteId = SiteConfig.umamiWebsiteId;

  final String origin;
  final String email;
  final String umamiWebsiteId;

  String url(ShellLocale locale) => '$origin${locale.path}';
}

class ShellException implements Exception {
  ShellException(this.message);

  final String message;

  @override
  String toString() => 'build_shell: $message';
}

String escapeHtml(String s) => s
    .replaceAll('&', '&amp;')
    .replaceAll('<', '&lt;')
    .replaceAll('>', '&gt;')
    .replaceAll('"', '&quot;')
    .replaceAll("'", '&#39;');

String text(Map<String, Object?> arb, String key) {
  final value = arb[key];
  if (value is! String || value.trim().isEmpty) {
    throw ShellException('ARB key "$key" is missing or empty');
  }
  return value;
}

String renderShell({
  required String template,
  required Map<String, Object?> arb,
  required ShellLocale locale,
  required ShellConfig config,
}) {
  final jsonLd = jsonEncode({
    '@context': 'https://schema.org',
    '@type': 'Person',
    'name': 'Lucas Schmidt',
    'url': config.url(ShellLocale.en),
    'email': config.email,
  }).replaceAll('</', r'<\/');
  final values = {
    'lang': locale.lang,
    'title': escapeHtml(text(arb, 'metaTitle')),
    'description': escapeHtml(text(arb, 'metaDescription')),
    'canonical': config.url(locale),
    'urlEn': config.url(ShellLocale.en),
    'urlPt': config.url(ShellLocale.pt),
    'ogImage': '${config.origin}/og-image.png',
    'ogImageAlt': escapeHtml(text(arb, 'metaImageAlt')),
    'ogLocale': locale.ogLocale,
    'ogLocaleAlt': locale.other.ogLocale,
    'jsonLd': jsonLd,
    'analytics': analyticsTag(config),
    'fallback': fallbackHtml(arb, locale, config),
  };
  return template.replaceAllMapped(RegExp(r'%%(\w+)%%'), (m) {
    final value = values[m.group(1)];
    if (value == null) throw ShellException('unknown token %%${m.group(1)}%%');
    return value;
  });
}

String analyticsTag(ShellConfig config) => config.umamiWebsiteId.isEmpty
    ? ''
    : '<script defer src="${SiteConfig.umamiScriptUrl}" '
          'data-domains="${Uri.parse(SiteConfig.siteUrl).host}" '
          'data-website-id="${escapeHtml(config.umamiWebsiteId)}"></script>';

String fallbackHtml(
  Map<String, Object?> arb,
  ShellLocale locale,
  ShellConfig config,
) {
  final other = locale.other;
  final otherLabel = other == ShellLocale.en ? 'English' : 'Português';
  final email = escapeHtml(config.email);
  return (StringBuffer()
        ..writeln('<main class="fallback" lang="${locale.lang}">')
        ..writeln('  <h1>${escapeHtml(text(arb, 'fallbackTitle'))}</h1>')
        ..writeln('  <p>${escapeHtml(text(arb, 'fallbackBody'))}</p>')
        ..writeln('  <p><a href="mailto:$email">$email</a></p>')
        ..writeln(
          '  <p><a href="${other.path}" hreflang="${other.lang}" '
          'lang="${other.lang}">$otherLabel</a></p>',
        )
        ..write('</main>'))
      .toString();
}

List<String> inlineScriptHashes(String html) => [
  for (final m in RegExp(
    r'<script\b([^>]*)>([\s\S]*?)</script>',
    caseSensitive: false,
  ).allMatches(html))
    if (!_external.hasMatch(m.group(1)!) && _runsInline(m.group(1)!))
      "'sha256-${base64.encode(sha256.convert(utf8.encode(m.group(2)!.replaceAll('\r\n', '\n'))).bytes)}'",
];

final _external = RegExp(r'(^|\s)src\s*=', caseSensitive: false);

const _inlineTypes = {
  'application/ecmascript',
  'application/javascript',
  'application/x-ecmascript',
  'application/x-javascript',
  'text/ecmascript',
  'text/javascript',
  'text/javascript1.0',
  'text/javascript1.1',
  'text/javascript1.2',
  'text/javascript1.3',
  'text/javascript1.4',
  'text/javascript1.5',
  'text/jscript',
  'text/livescript',
  'text/x-ecmascript',
  'text/x-javascript',
  'module',
  'importmap',
  'speculationrules',
};

bool _runsInline(String attributes) {
  final type = RegExp(
    r"""(^|\s)type\s*=\s*["']([^"']*)["']""",
    caseSensitive: false,
  ).firstMatch(attributes)?.group(2)?.trim().toLowerCase();
  return type == null || type.isEmpty || _inlineTypes.contains(type);
}

Set<String> scriptSrcHashes(String policy) {
  for (final directive in policy.split(';')) {
    final parts = directive.trim().split(RegExp(r'\s+'));
    if (parts.first == 'script-src') {
      return {
        for (final p in parts.skip(1))
          if (p.startsWith("'sha256-")) p,
      };
    }
  }
  return {};
}

String? _cspOf(Map<String, Object?> target) {
  String? enforced;
  String? reportOnly;
  for (final rule
      in (target['headers'] as List<Object?>? ?? [])
          .cast<Map<String, Object?>>()) {
    for (final header
        in (rule['headers'] as List<Object?>? ?? [])
            .cast<Map<String, Object?>>()) {
      final key = header['key'];
      if (key == 'Content-Security-Policy') {
        enforced ??= header['value'] as String?;
      } else if (key == 'Content-Security-Policy-Report-Only') {
        reportOnly ??= header['value'] as String?;
      }
    }
  }
  return enforced ?? reportOnly;
}

void checkCspHashes(
  Map<String, Object?> firebaseJson,
  Iterable<String> shells,
) {
  final expected = {for (final s in shells) ...inlineScriptHashes(s)};
  final targets = (firebaseJson['hosting'] as List<Object?>)
      .cast<Map<String, Object?>>();
  for (final target in targets) {
    final name = target['target'];
    final policy = _cspOf(target);
    if (policy == null) {
      throw ShellException(
        'hosting target "$name" has no Content-Security-Policy header',
      );
    }
    final listed = scriptSrcHashes(policy);
    if (listed.length != expected.length || !listed.containsAll(expected)) {
      throw ShellException(
        'hosting target "$name": firebase.json script-src lists '
        '${(listed.toList()..sort()).join(' ')} but the shells\' inline '
        'scripts need ${(expected.toList()..sort()).join(' ')}',
      );
    }
  }
}

Map<String, Object?> _readArb(String path) {
  final file = File(path);
  if (!file.existsSync()) throw ShellException('missing $path');
  final data = jsonDecode(file.readAsStringSync());
  if (data is! Map<String, Object?>) {
    throw ShellException('$path is not a JSON object');
  }
  return data;
}

void _write(String path, String content) {
  File(path)
    ..parent.createSync(recursive: true)
    ..writeAsStringSync(content.replaceAll('\r\n', '\n'));
}

Future<void> main(List<String> args) async {
  try {
    var web = 'build/web';
    var firebase = 'firebase.json';
    for (var i = 0; i < args.length; i++) {
      if (args[i] == '--web' && i + 1 < args.length) {
        web = args[++i];
      } else if (args[i] == '--firebase' && i + 1 < args.length) {
        firebase = args[++i];
      } else {
        throw ShellException(
          'unknown argument "${args[i]}"; usage: '
          'build_shell.dart [--web <dir>] [--firebase <file>]',
        );
      }
    }
    final templateFile = File('$web/index.html');
    if (!templateFile.existsSync()) {
      throw ShellException(
        'missing ${templateFile.path}; run flutter build web',
      );
    }
    final template = templateFile.readAsStringSync();
    final config = ShellConfig.fromSiteConfig();
    final shells = {
      for (final locale in ShellLocale.values)
        locale: renderShell(
          template: template,
          arb: _readArb(locale.arbFile),
          locale: locale,
          config: config,
        ),
    };
    final firebaseFile = File(firebase);
    if (!firebaseFile.existsSync()) throw ShellException('missing $firebase');
    final firebaseJson = jsonDecode(firebaseFile.readAsStringSync());
    if (firebaseJson is! Map<String, Object?>) {
      throw ShellException('$firebase is not a JSON object');
    }
    checkCspHashes(firebaseJson, shells.values);
    _write('$web/index.html', shells[ShellLocale.en]!);
    _write('$web/pt/index.html', shells[ShellLocale.pt]!);
    stdout.writeln('build_shell: wrote $web/index.html and $web/pt/index.html');
  } on ShellException catch (e) {
    stderr.writeln(e);
    exitCode = 1;
  } on FormatException catch (e) {
    stderr.writeln('build_shell: invalid ARB JSON: ${e.message}');
    exitCode = 1;
  }
}
