import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:lschmidt_portfolio/config/site_config.dart';

void main() {
  final firebase =
      jsonDecode(File('firebase.json').readAsStringSync())
          as Map<String, Object?>;
  final hosting = (firebase['hosting']! as List<Object?>)
      .cast<Map<String, Object?>>();

  Map<String, String> headers() => {
    for (final rule
        in (hosting.single['headers']! as List<Object?>)
            .cast<Map<String, Object?>>()
            .where((r) => r['source'] == '**'))
      for (final h
          in (rule['headers']! as List<Object?>).cast<Map<String, Object?>>())
        h['key']! as String: h['value']! as String,
  };

  test(
    'one hosting entry: target site, public build/web, no trailing slash',
    () {
      expect(hosting, hasLength(1));
      final t = hosting.single;
      expect(t['target'], 'site');
      expect(t['public'], 'build/web');
      expect(t['trailingSlash'], isFalse);
    },
  );

  test('/pt rewrite, index redirects, no catch-all', () {
    final t = hosting.single;
    final rewrites = (t['rewrites'] as List<Object?>? ?? [])
        .cast<Map<String, Object?>>();
    expect(rewrites.where((r) => r['source'] == '**'), isEmpty);
    expect(rewrites, [
      {'source': '/pt', 'destination': '/pt/index.html'},
    ]);
    expect(t['redirects'], [
      {'source': '/index.html', 'destination': '/', 'type': 301},
      {'source': '/pt/index.html', 'destination': '/pt', 'type': 301},
    ]);
  });

  test('security headers on **, indexable, CSP report-only in M1', () {
    final h = headers();
    expect(h['Cache-Control'], 'no-cache');
    expect(h['X-Content-Type-Options'], 'nosniff');
    expect(h['Referrer-Policy'], 'strict-origin-when-cross-origin');
    expect(h, contains('Content-Security-Policy-Report-Only'));
    expect(h, isNot(contains('Content-Security-Policy')));
    expect(h, isNot(contains('X-Robots-Tag')));
    expect(jsonEncode(firebase), isNot(contains('noindex')));
  });

  test('CSP keeps its sources (hashes are checked by build_shell_test)', () {
    const withoutHashes =
        "default-src 'self'; "
        "script-src 'self' 'wasm-unsafe-eval' https://www.gstatic.com/flutter-canvaskit/ https://cloud.umami.is; "
        "style-src 'self' 'unsafe-inline'; "
        "connect-src 'self' https://www.gstatic.com/flutter-canvaskit/ https://fonts.gstatic.com/s/ https://api.web3forms.com https://gateway.umami.is; "
        "frame-ancestors 'none'; base-uri 'self'; form-action 'none'; object-src 'none'";
    final value = headers()['Content-Security-Policy-Report-Only']!.replaceAll(
      RegExp(r" 'sha256-[A-Za-z0-9+/=]+'"),
      '',
    );
    expect(value, withoutHashes);
  });

  test('.firebaserc maps the default project and the site target', () {
    final rc =
        jsonDecode(File('.firebaserc').readAsStringSync())
            as Map<String, Object?>;
    expect((rc['projects']! as Map)['default'], 'myportfolio-f0271');
    final targets = rc['targets']! as Map<String, Object?>;
    expect(
      ((targets['myportfolio-f0271']! as Map)['hosting']! as Map)['site'],
      ['myportfolio-f0271'],
    );
  });

  test('404.html: branded, bilingual, links home, noindex, no Flutter', () {
    final html = File('web/404.html').readAsStringSync();
    expect(html, contains('Page not found'));
    expect(html, contains('Página não encontrada'));
    expect(html, contains('href="/"'));
    expect(html, contains('href="/pt"'));
    expect(html, contains('<meta name="robots" content="noindex">'));
    expect(html, isNot(contains('flutter_bootstrap.js')));
    expect(html, isNot(contains('%%')));
  });

  test('shell, 404 and manifest use the spec dark tokens', () {
    const tokens = {'#0B0C0E', '#E9EAEC', '#A3A8AF', '#24282E', '#6FB1E8'};
    for (final file in ['web/index.html', 'web/404.html']) {
      final used = RegExp(r'#[0-9A-Fa-f]{6}\b')
          .allMatches(File(file).readAsStringSync())
          .map((m) => m.group(0)!.toUpperCase())
          .toSet();
      expect(tokens.containsAll(used), isTrue, reason: '$file: $used');
    }
    final m =
        jsonDecode(File('web/manifest.json').readAsStringSync())
            as Map<String, Object?>;
    expect(m['name'], 'Lucas Schmidt');
    expect(m['short_name'], 'Lucas Schmidt');
    expect(m['background_color'], '#0B0C0E');
    expect(m['theme_color'], '#0B0C0E');
    final en =
        jsonDecode(File('lib/l10n/app_en.arb').readAsStringSync())
            as Map<String, Object?>;
    expect(m['description'], en['metaDescription']);
  });

  test('template tokens are not Flutter web-defines', () {
    expect(File('web/index.html').readAsStringSync(), isNot(contains('{{')));
  });

  test('robots.txt allows all and names the sitemap', () {
    final robots = File('web/robots.txt').readAsStringSync();
    expect(robots, contains('User-agent: *'));
    expect(robots, contains('Allow: /'));
    expect(robots, contains('Sitemap: ${SiteConfig.siteUrl}/sitemap.xml'));
  });

  test('sitemap.xml lists / and /pt with hreflang alternates', () {
    final xml = File('web/sitemap.xml').readAsStringSync();
    const o = SiteConfig.siteUrl;
    expect(xml, contains('<loc>$o/</loc>'));
    expect(xml, contains('<loc>$o/pt</loc>'));
    expect(xml, contains('hreflang="en" href="$o/"'));
    expect(xml, contains('hreflang="pt-BR" href="$o/pt"'));
    expect(xml, contains('hreflang="x-default" href="$o/"'));
  });
}
