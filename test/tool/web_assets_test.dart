import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:lschmidt_portfolio/config/site_config.dart';

({int width, int height}) pngSize(String path) {
  final bytes = File(path).readAsBytesSync();
  final data = ByteData.sublistView(Uint8List.fromList(bytes));
  const signature = [137, 80, 78, 71, 13, 10, 26, 10];
  expect(bytes.sublist(0, 8), signature, reason: path);
  return (width: data.getUint32(16), height: data.getUint32(20));
}

void main() {
  final manifest =
      jsonDecode(File('web/manifest.json').readAsStringSync())
          as Map<String, Object?>;

  group('manifest', () {
    test('names the site after the owner', () {
      expect(manifest['name'], SiteConfig.name);
      expect(manifest['short_name'], SiteConfig.name);
    });

    test('uses the dark surface for theme and background', () {
      expect(manifest['theme_color'], '#0B0C0E');
      expect(manifest['background_color'], '#0B0C0E');
    });

    test('lists every icon with its real size and purpose', () {
      final icons = (manifest['icons']! as List<Object?>)
          .cast<Map<String, Object?>>();
      expect(icons.map((i) => '${i['src']}|${i['sizes']}|${i['purpose']}'), [
        'icons/Icon-192.png|192x192|null',
        'icons/Icon-512.png|512x512|null',
        'icons/Icon-maskable-192.png|192x192|maskable',
        'icons/Icon-maskable-512.png|512x512|maskable',
      ]);
      for (final icon in icons) {
        final size = pngSize('web/${icon['src']}');
        expect('${size.width}x${size.height}', icon['sizes']);
      }
    });
  });

  group('images', () {
    test('the link preview is 1200x630 and small', () {
      final size = pngSize('web/og-image.png');
      expect((size.width, size.height), (1200, 630));
      expect(File('web/og-image.png').lengthSync(), lessThan(300 * 1024));
    });

    test('the favicon is square', () {
      final size = pngSize('web/favicon.png');
      expect(size.width, size.height);
    });

    test('no CV file is shipped', () {
      expect(Directory('web/cv').existsSync(), isFalse);
    });
  });
}
