import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:lschmidt_portfolio/config/site_config.dart';

import '../../tool/web/build_shell.dart';

Map<String, Object?> realArb(ShellLocale locale) =>
    jsonDecode(File(locale.arbFile).readAsStringSync()) as Map<String, Object?>;

String realTemplate() => File('web/index.html').readAsStringSync();

const config = ShellConfig(
  origin: 'https://lschmidt.tech',
  email: 'lschmidt.dev@gmail.com',
);

String shell(
  ShellLocale locale, {
  Map<String, Object?>? arb,
  ShellConfig shellConfig = config,
}) => renderShell(
  template: realTemplate(),
  arb: arb ?? realArb(locale),
  locale: locale,
  config: shellConfig,
);

void main() {
  test('fills every token', () {
    for (final locale in ShellLocale.values) {
      expect(shell(locale), isNot(contains('%%')), reason: locale.name);
    }
  });

  group('analytics tag', () {
    const withId = ShellConfig(
      origin: 'https://lschmidt.tech',
      email: 'lschmidt.dev@gmail.com',
      umamiWebsiteId: 'aaaaaaaa-1111-2222-3333-bbbbbbbbbbbb',
    );

    test('renders the deferred Umami script with the configured id', () {
      for (final locale in ShellLocale.values) {
        final html = shell(locale, shellConfig: withId);
        expect(
          html,
          contains(
            '<script defer src="${SiteConfig.umamiScriptUrl}" '
            'data-domains="lschmidt.tech" '
            'data-website-id="aaaaaaaa-1111-2222-3333-bbbbbbbbbbbb"></script>',
          ),
        );
        expect(html, isNot(contains('%%')));
        expect('data-website-id'.allMatches(html), hasLength(1));
      }
    });

    test('renders nothing when the id is empty', () {
      for (final locale in ShellLocale.values) {
        final html = shell(locale);
        expect(html, isNot(contains('umami')));
        expect(html, isNot(contains('data-website-id')));
        expect(html, isNot(contains('%%')));
      }
    });

    test('escapes the id as an attribute value', () {
      final html = shell(
        ShellLocale.en,
        shellConfig: const ShellConfig(
          origin: 'https://lschmidt.tech',
          email: 'lschmidt.dev@gmail.com',
          umamiWebsiteId: 'a"b<c',
        ),
      );
      expect(html, contains('data-website-id="a&quot;b&lt;c"'));
    });

    test('the external tag adds no inline-script hash', () {
      expect(
        inlineScriptHashes(shell(ShellLocale.en, shellConfig: withId)),
        inlineScriptHashes(shell(ShellLocale.en)),
      );
    });

    test('fromSiteConfig carries the configured id', () {
      expect(
        ShellConfig.fromSiteConfig().umamiWebsiteId,
        SiteConfig.umamiWebsiteId,
      );
    });
  });

  test('locales: EN at /, PT at /pt', () {
    expect(ShellLocale.en.lang, 'en');
    expect(ShellLocale.en.ogLocale, 'en_US');
    expect(ShellLocale.en.path, '/');
    expect(ShellLocale.pt.lang, 'pt-BR');
    expect(ShellLocale.pt.ogLocale, 'pt_BR');
    expect(ShellLocale.pt.path, '/pt');
    expect(ShellLocale.en.arbFile, 'lib/l10n/app_en.arb');
  });

  test('EN shell: lang, canonical, hreflang, og locale', () {
    final html = shell(ShellLocale.en);
    expect(html, contains('<html lang="en">'));
    expect(
      html,
      contains('<link rel="canonical" href="https://lschmidt.tech/">'),
    );
    expect(
      html,
      contains('<meta property="og:url" content="https://lschmidt.tech/">'),
    );
    expect(html, contains('<meta property="og:locale" content="en_US">'));
    expect(
      html,
      contains('<meta property="og:locale:alternate" content="pt_BR">'),
    );
  });

  test('PT shell: lang, canonical, og locale', () {
    final html = shell(ShellLocale.pt);
    expect(html, contains('<html lang="pt-BR">'));
    expect(
      html,
      contains('<link rel="canonical" href="https://lschmidt.tech/pt">'),
    );
    expect(html, contains('<meta property="og:locale" content="pt_BR">'));
    expect(
      html,
      contains('<meta property="og:locale:alternate" content="en_US">'),
    );
  });

  test('hreflang alternates in both shells', () {
    for (final locale in ShellLocale.values) {
      final html = shell(locale);
      expect(
        html,
        contains(
          '<link rel="alternate" hreflang="en" href="https://lschmidt.tech/">',
        ),
      );
      expect(
        html,
        contains(
          '<link rel="alternate" hreflang="pt-BR" '
          'href="https://lschmidt.tech/pt">',
        ),
      );
      expect(
        html,
        contains(
          '<link rel="alternate" hreflang="x-default" '
          'href="https://lschmidt.tech/">',
        ),
      );
    }
  });

  test('canonical points at the real origin, never a channel URL', () {
    for (final locale in ShellLocale.values) {
      final html = shell(locale);
      final canonical = RegExp(
        r'<link rel="canonical" href="([^"]+)">',
      ).firstMatch(html)!.group(1)!;
      expect(canonical, startsWith(SiteConfig.siteUrl));
      expect(html, isNot(contains('web.app')));
      expect(html, isNot(contains('firebaseapp.com')));
    }
  });

  test('Open Graph, Twitter and viewport tags in both shells', () {
    for (final locale in ShellLocale.values) {
      final html = shell(locale);
      final arb = realArb(locale);
      final title = escapeHtml(arb['metaTitle']! as String);
      final description = escapeHtml(arb['metaDescription']! as String);
      expect(html, contains('<title>$title</title>'));
      expect(html, contains('<meta property="og:title" content="$title">'));
      expect(
        html,
        contains('<meta property="og:description" content="$description">'),
      );
      expect(
        html,
        contains(
          '<meta property="og:image" '
          'content="https://lschmidt.tech/og-image.png">',
        ),
      );
      expect(
        html,
        contains('<meta name="twitter:card" content="summary_large_image">'),
      );
      expect(
        html,
        contains(
          '<meta name="viewport" content="width=device-width, initial-scale=1">',
        ),
      );
    }
  });

  test('no-JS fallback has the heading, body and a mailto link', () {
    for (final locale in ShellLocale.values) {
      final html = shell(locale);
      final arb = realArb(locale);
      expect(html, contains('<main class="fallback" lang="${locale.lang}">'));
      expect(
        html,
        contains('<h1>${escapeHtml(arb['fallbackTitle']! as String)}</h1>'),
      );
      expect(html, contains(escapeHtml(arb['fallbackBody']! as String)));
      expect(html, contains('href="mailto:lschmidt.dev@gmail.com"'));
    }
  });

  test('the fallback links to the other language and has no ids', () {
    expect(
      fallbackHtml(realArb(ShellLocale.en), ShellLocale.en, config),
      contains('<a href="/pt" hreflang="pt-BR" lang="pt-BR">Português</a>'),
    );
    expect(
      fallbackHtml(realArb(ShellLocale.pt), ShellLocale.pt, config),
      contains('<a href="/" hreflang="en" lang="en">English</a>'),
    );
    for (final locale in ShellLocale.values) {
      expect(
        fallbackHtml(realArb(locale), locale, config),
        isNot(contains(' id=')),
      );
    }
  });

  test('ARB text is HTML-escaped', () {
    final arb = {
      ...realArb(ShellLocale.en),
      'metaTitle': 'A & B <script>"x"',
      'metaDescription': "it's </script> <b>",
    };
    final html = shell(ShellLocale.en, arb: arb);
    expect(
      html,
      contains('<title>A &amp; B &lt;script&gt;&quot;x&quot;</title>'),
    );
    expect(html, isNot(contains("it's </script> <b>")));
    expect(html, contains('it&#39;s &lt;/script&gt; &lt;b&gt;'));
    expect(
      escapeHtml('a & b <c> "d" \'e\''),
      'a &amp; b &lt;c&gt; &quot;d&quot; &#39;e&#39;',
    );
  });

  test('JSON-LD is valid JSON with the person data', () {
    final html = shell(ShellLocale.en);
    final match = RegExp(
      r'<script type="application/ld\+json">(.*?)</script>',
      dotAll: true,
    ).firstMatch(html)!;
    final data =
        jsonDecode(match.group(1)!.replaceAll(r'<\/', '</'))
            as Map<String, Object?>;
    expect(data['@type'], 'Person');
    expect(data['name'], 'Lucas Schmidt');
    expect(data['url'], 'https://lschmidt.tech/');
    expect(data['email'], 'lschmidt.dev@gmail.com');
  });

  test('a missing or empty key fails with its name', () {
    for (final broken in [
      {...realArb(ShellLocale.en)}..remove('metaTitle'),
      {...realArb(ShellLocale.en), 'metaTitle': '  '},
    ]) {
      expect(
        () => shell(ShellLocale.en, arb: broken),
        throwsA(
          isA<ShellException>().having(
            (e) => e.message,
            'message',
            contains('metaTitle'),
          ),
        ),
      );
    }
  });

  test('an unknown token in the template fails', () {
    expect(
      () => renderShell(
        template: '${realTemplate()}%%nope%%',
        arb: realArb(ShellLocale.en),
        locale: ShellLocale.en,
        config: config,
      ),
      throwsA(isA<ShellException>()),
    );
  });

  test('ShellConfig.fromSiteConfig uses SiteConfig', () {
    final c = ShellConfig.fromSiteConfig();
    expect(c.origin, SiteConfig.siteUrl);
    expect(c.email, SiteConfig.email);
  });

  test('site_config.dart stays plain Dart (the CLI imports it)', () {
    final source = File('lib/config/site_config.dart').readAsStringSync();
    expect(source, isNot(contains('package:flutter')));
    expect(source, isNot(contains('dart:ui')));
  });

  test('the ARB files carry the shell keys, within SEO limits', () {
    for (final locale in ShellLocale.values) {
      final arb = realArb(locale);
      for (final key in [
        'metaTitle',
        'metaDescription',
        'fallbackTitle',
        'fallbackBody',
      ]) {
        expect(arb[key], isA<String>(), reason: '${locale.name}.$key');
      }
      expect(
        (arb['metaDescription']! as String).length,
        lessThanOrEqualTo(160),
      );
      final all = jsonEncode(arb).toLowerCase();
      expect(all, isNot(contains('senior')));
      expect(all, isNot(contains('whatsapp')));
      expect(all, isNot(contains('freelanc')));
    }
    expect(
      realArb(ShellLocale.en)['metaTitle'],
      'Lucas Schmidt — Mobile Engineer (Flutter)',
    );
    expect(
      realArb(ShellLocale.pt)['metaTitle'],
      'Lucas Schmidt — Engenheiro Mobile (Flutter)',
    );
    expect(
      realArb(ShellLocale.en)['fallbackBody'],
      contains('lschmidt.dev@gmail.com'),
    );
  });

  test(
    'the CLI writes / and /pt and fails cleanly on a bad build dir',
    () async {
      final dir = Directory.systemTemp.createTempSync('shell');
      addTearDown(() => dir.deleteSync(recursive: true));
      File('${dir.path}/index.html').writeAsStringSync(realTemplate());
      final ok = await Process.run('dart', [
        'run',
        'tool/web/build_shell.dart',
        '--web',
        dir.path,
      ], runInShell: Platform.isWindows);
      expect(ok.exitCode, 0, reason: '${ok.stdout}${ok.stderr}');
      expect(
        File('${dir.path}/index.html').readAsStringSync(),
        contains('<html lang="en">'),
      );
      expect(
        File('${dir.path}/pt/index.html').readAsStringSync(),
        contains('<html lang="pt-BR">'),
      );

      final bad = await Process.run('dart', [
        'run',
        'tool/web/build_shell.dart',
        '--web',
        '${dir.path}/nope',
      ], runInShell: Platform.isWindows);
      expect(bad.exitCode, isNot(0));
      expect(bad.stderr, contains('build_shell: missing'));
    },
    timeout: const Timeout(Duration(minutes: 2)),
  );

  test('splash: JS only, removed on first frame or after 10s, '
      'still under reduced motion', () {
    expect(realTemplate(), isNot(contains('inset:0')));
    for (final locale in ShellLocale.values) {
      final html = shell(locale);
      expect(html, contains('id="splash"'));
      expect(
        html,
        contains('<noscript><style>#splash{display:none}</style></noscript>'),
      );
      expect(html, contains("addEventListener('flutter-first-frame'"));
      expect(html, contains('10000'));
      expect(html, contains("root.style.overflow = 'hidden'"));
      expect(
        RegExp(r"root\.style\.overflow = ''").allMatches(html),
        hasLength(2),
      );
      expect(html, contains('@media (prefers-reduced-motion: reduce)'));
    }
  });

  test('zoom: a script strips user-scalable=no / maximum-scale from the '
      'viewport meta the engine injects', () {
    final html = shell(ShellLocale.en);
    expect(html, contains('new MutationObserver'));
    expect(html, contains('.observe(document.head'));
    expect(html, contains('user-scalable=no'));
    expect(html, contains('maximum-scale'));
  });

  group('CSP hash guard', () {
    test('hashes inline JavaScript only, in order', () {
      const html =
          '<script>alert(1)</script>'
          '<script type="application/ld+json">{"a":1}</script>'
          '<script src="flutter_bootstrap.js" async></script>'
          '<script type="module">console.log("zk")\r\n</script>';
      expect(inlineScriptHashes(html), [
        "'sha256-bhHHL3z2vDgxUt0W3dWQOrprscmda2Y5pLsLg4GF+pI='",
        "'sha256-fugnoIvyvWD8DFTCa1wywrEPpQY+JETmHI9f1bVBDWo='",
      ]);
    });

    test(
      'hashes every script a browser runs inline, whatever the spelling',
      () {
        const run = "'sha256-bhHHL3z2vDgxUt0W3dWQOrprscmda2Y5pLsLg4GF+pI='";
        for (final tag in [
          '<script data-src="x">',
          '<script TYPE="Module">',
          '<script type="application/javascript">',
          '<script type=" text/JavaScript ">',
          '<script type="importmap">',
        ]) {
          expect(inlineScriptHashes('${tag}alert(1)</script>'), [
            run,
          ], reason: tag);
        }
        for (final tag in [
          '<script SRC = "a.js">',
          '<script type="application/ld+json">',
        ]) {
          expect(
            inlineScriptHashes('${tag}alert(1)</script>'),
            isEmpty,
            reason: tag,
          );
        }
      },
    );

    test('reads the hashes of script-src only', () {
      expect(
        scriptSrcHashes(
          "default-src 'self' 'sha256-x='; "
          "script-src 'self' 'sha256-a=' 'sha256-b='; style-src 'sha256-c='",
        ),
        {"'sha256-a='", "'sha256-b='"},
      );
      expect(scriptSrcHashes("default-src 'self'"), isEmpty);
    });

    Map<String, Object?> hosting(
      List<String?> policies, {
      String key = 'Content-Security-Policy',
    }) => {
      'hosting': [
        for (final (i, policy) in policies.indexed)
          {
            'target': 't$i',
            'headers': [
              {
                'source': '**',
                'headers': [
                  if (policy != null) {'key': key, 'value': policy},
                ],
              },
            ],
          },
      ],
    };
    const shellHtml = '<script>alert(1)</script>';
    const good =
        "script-src 'self' 'sha256-bhHHL3z2vDgxUt0W3dWQOrprscmda2Y5pLsLg4GF+pI='";
    const reportOnly = 'Content-Security-Policy-Report-Only';

    Matcher fails(String text) => throwsA(
      isA<ShellException>().having((e) => e.message, 'message', contains(text)),
    );

    test('passes when every target lists exactly the shell hashes', () {
      expect(
        () => checkCspHashes(hosting([good, good]), [shellHtml]),
        returnsNormally,
      );
      expect(
        () => checkCspHashes(hosting([good], key: reportOnly), [shellHtml]),
        returnsNormally,
      );
    });

    test('fails on a missing hash, a stale hash or no header', () {
      expect(
        () => checkCspHashes(hosting([good, "script-src 'self'"]), [shellHtml]),
        fails('"t1"'),
      );
      expect(
        () => checkCspHashes(hosting(["$good 'sha256-stale='"]), [shellHtml]),
        fails('sha256-stale='),
      );
      expect(
        () => checkCspHashes(hosting([null]), [shellHtml]),
        fails('no Content-Security-Policy'),
      );
    });

    test('stale hashes still fail the build under the Report-Only header', () {
      expect(
        () => checkCspHashes(
          hosting(["$good 'sha256-stale='"], key: reportOnly),
          [shellHtml],
        ),
        fails('sha256-stale='),
      );
      expect(
        () => checkCspHashes(hosting(["script-src 'self'"], key: reportOnly), [
          shellHtml,
        ]),
        fails('"t0"'),
      );
    });

    test('the enforced header takes precedence over Report-Only', () {
      final json = {
        'hosting': [
          {
            'target': 't0',
            'headers': [
              {
                'source': '**',
                'headers': [
                  {'key': reportOnly, 'value': good},
                  {
                    'key': 'Content-Security-Policy',
                    'value': "script-src 'self'",
                  },
                ],
              },
            ],
          },
        ],
      };
      expect(() => checkCspHashes(json, [shellHtml]), fails('"t0"'));
    });

    test('the real shells match firebase.json (drift guard)', () {
      final shells = [for (final l in ShellLocale.values) shell(l)];
      final firebase =
          jsonDecode(File('firebase.json').readAsStringSync())
              as Map<String, Object?>;
      expect(inlineScriptHashes(shells.first), hasLength(2));
      expect(() => checkCspHashes(firebase, shells), returnsNormally);
    });
  });
}
