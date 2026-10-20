import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:yaml/yaml.dart';

List<String> _allowlists(String toml) {
  final lines = toml.split('\n');
  final entries = <String>[];
  for (var i = 0; i < lines.length; i++) {
    if (lines[i].trim() != '[[allowlists]]') continue;
    final body = StringBuffer();
    for (var k = i + 1; k < lines.length; k++) {
      if (lines[k].trim().startsWith('[')) break;
      body.writeln(lines[k]);
    }
    entries.add(body.toString());
  }
  return entries;
}

void main() {
  final toml = File('.gitleaks.toml').readAsStringSync();

  test('.gitleaks.toml extends the default rules', () {
    expect(
      toml,
      matches(
        RegExp(
          r'^\[extend\]\s*\n(?:.*\n)*?useDefault\s*=\s*true',
          multiLine: true,
        ),
      ),
    );
  });

  test('every allowlist entry is an exact regex, never a path', () {
    final entries = _allowlists(toml);
    expect(
      RegExp(r'^\s*paths\s*=', multiLine: true).hasMatch(toml),
      isFalse,
      reason: 'allow-list paths would exempt whole files',
    );
    for (final entry in entries) {
      expect(entry, contains('regexes'));
      expect(entry, isNot(contains('paths')));
      expect(entry, isNot(contains('commits')));
      expect(entry, isNot(contains('stopwords')));
    }
  });

  test('.gitignore keeps secret-bearing files out', () {
    final lines = File(
      '.gitignore',
    ).readAsLinesSync().map((l) => l.trim()).toSet();
    for (final pattern in [
      'gha-creds-*.json',
      '.env*',
      '*.pem',
      '*.p12',
      'service-account*.json',
      'firebase-debug.log',
    ]) {
      expect(lines, contains(pattern));
    }
  });

  test('firebase.json has no predeploy or postdeploy hooks', () {
    final text = File('firebase.json').readAsStringSync();
    expect(text, isNot(contains('predeploy')));
    expect(text, isNot(contains('postdeploy')));
    final hosting = (loadYaml(text) as YamlMap)['hosting'];
    final entries = hosting is YamlList ? hosting : [hosting];
    for (final entry in entries) {
      expect((entry as YamlMap).containsKey('predeploy'), isFalse);
      expect(entry.containsKey('postdeploy'), isFalse);
    }
  });

  group('pre-commit hook', () {
    test('runs gitleaks git --staged and skips with a warning if absent', () {
      final hook = File('tool/hooks/pre-commit').readAsStringSync();
      expect(hook, startsWith('#!/usr/bin/env sh'));
      expect(hook, contains('gitleaks git --staged --config .gitleaks.toml'));
      expect(hook, contains('command -v gitleaks'));
      expect(hook, contains('exit 0'));
      expect(hook, isNot(contains('\r')));
    });

    test('install.sh points core.hooksPath at tool/hooks', () {
      final script = File('tool/hooks/install.sh').readAsStringSync();
      expect(script, contains('git config core.hooksPath tool/hooks'));
      expect(script, isNot(contains('\r')));
    });
  });
}
