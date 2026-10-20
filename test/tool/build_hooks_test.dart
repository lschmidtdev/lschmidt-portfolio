import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

const allowedHooks = <String>{};

List<String> packagesWithHooks(
  Map<String, dynamic> packageConfig,
  Uri configUri,
) {
  final found = <String>[];
  for (final package
      in (packageConfig['packages'] as List).cast<Map<String, dynamic>>()) {
    final rootUri = package['rootUri'] as String;
    final root = configUri.resolve(
      rootUri.endsWith('/') ? rootUri : '$rootUri/',
    );
    final hasHook = [
      'build.dart',
      'link.dart',
    ].any((hook) => File.fromUri(root.resolve('hook/$hook')).existsSync());
    if (hasHook) found.add(package['name'] as String);
  }
  return found..sort();
}

void main() {
  group('packagesWithHooks', () {
    late Directory tmp;

    setUp(() => tmp = Directory.systemTemp.createTempSync('hooks'));
    tearDown(() => tmp.deleteSync(recursive: true));

    test('finds build and link hooks, relative or absolute roots', () {
      File('${tmp.path}/b_native/hook/build.dart').createSync(recursive: true);
      File('${tmp.path}/a_linker/hook/link.dart').createSync(recursive: true);
      Directory('${tmp.path}/plain/lib').createSync(recursive: true);
      final configUri = tmp.uri.resolve('.dart_tool/package_config.json');
      final config = {
        'configVersion': 2,
        'packages': [
          {'name': 'plain', 'rootUri': '../plain'},
          {'name': 'b_native', 'rootUri': '../b_native/'},
          {
            'name': 'a_linker',
            'rootUri': tmp.uri.resolve('a_linker').toString(),
          },
        ],
      };
      expect(packagesWithHooks(config, configUri), ['a_linker', 'b_native']);
    });
  });

  test('no dependency ships a build hook (review before allowing one)', () {
    final file = File('.dart_tool/package_config.json');
    if (!file.existsSync()) {
      fail(
        '.dart_tool/package_config.json is missing: run `flutter pub get` '
        'from the repo root first.',
      );
    }
    final config = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
    final unreviewed = packagesWithHooks(
      config,
      file.absolute.uri,
    ).where((name) => !allowedHooks.contains(name));
    expect(
      unreviewed,
      isEmpty,
      reason:
          'These packages run code during `dart run`, `flutter test` and '
          '`flutter build`. Read their hook/ code, then add them to '
          'allowedHooks in this file.',
    );
  });
}
