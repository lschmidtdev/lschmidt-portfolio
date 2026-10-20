import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../../tool/ci/content_guard.dart';

Object? readJson(String locale) =>
    jsonDecode(File('assets/content/$locale.json').readAsStringSync());

void expectSameShape(Object? a, Object? b, String path) {
  if (a is Map && b is Map) {
    expect(a.keys.toSet(), b.keys.toSet(), reason: 'keys at $path');
    for (final key in a.keys) {
      expectSameShape(a[key], b[key], '$path.$key');
    }
  } else if (a is List && b is List) {
    expect(a.length, b.length, reason: 'length at $path');
    for (var i = 0; i < a.length; i++) {
      expectSameShape(a[i], b[i], '$path[$i]');
    }
  } else {
    expect(a?.runtimeType, b?.runtimeType, reason: 'type at $path');
  }
}

List<String> pick(Map<String, dynamic> content, String key, String field) => [
  for (final item in content[key] as List) '${(item as Map)[field]}',
];

void main() {
  test('en.json and pt.json share the same structure and list lengths', () {
    expectSameShape(readJson('en'), readJson('pt'), r'$');
  });

  test('dates, ids, indexes and current flags match across locales', () {
    final en = readJson('en') as Map<String, dynamic>;
    final pt = readJson('pt') as Map<String, dynamic>;
    for (final (key, field) in [
      ('currently', 'date'),
      ('projects', 'id'),
      ('projects', 'index'),
      ('projects', 'featured'),
      ('projects', 'headlineStats'),
      ('projects', 'playStoreUrl'),
      ('roles', 'current'),
    ]) {
      expect(pick(en, key, field), pick(pt, key, field), reason: '$key.$field');
    }
  });

  for (final locale in ['en', 'pt']) {
    test('$locale.json passes the content guard', () {
      final text = File('assets/content/$locale.json').readAsStringSync();
      expect(findViolations(text), isEmpty);
    });
  }
}
