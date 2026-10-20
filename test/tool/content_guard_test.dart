import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../../tool/ci/content_guard.dart';

void main() {
  group('findViolations', () {
    test('flags "senior" as a whole word, any case and accent', () {
      expect(findViolations('Senior Flutter developer'), isNotEmpty);
      expect(findViolations('um dev S\u00eanior'), isNotEmpty);
      expect(findViolations('SENIOR'), isNotEmpty);
      expect(findViolations('a seniority ladder'), isEmpty);
    });

    test('flags freelance and whatsapp', () {
      expect(findViolations('Available for Freelance work'), isNotEmpty);
      expect(findViolations('freelancer'), isNotEmpty);
      expect(findViolations('Chat on WhatsApp'), isNotEmpty);
    });

    test('flags any email address except the site address', () {
      expect(findViolations('mail someone.else@gmail.com'), isNotEmpty);
      expect(findViolations('mail lschmidt.dev@gmail.com'), isEmpty);
      expect(
        findViolations('mailto:lschmidt.dev@gmail.com?subject=Hi'),
        isEmpty,
      );
      expect(findViolations('mail x-lschmidt.dev@gmail.com'), isNotEmpty);
    });

    test('flags Brazilian phone numbers', () {
      for (final phone in [
        '+55 (11) 91234-5678',
        '+5511912345678',
        '55 11 9 1234-5678',
        '(11) 98765-4321',
        '11 98765-4321',
        '+55 21 9 8765 4321',
        '+55 21 9 8765.4321',
        '+55 21 9 8765-4321',
      ]) {
        expect(findViolations('call $phone'), isNotEmpty, reason: phone);
      }
    });

    test('does not flag year ranges or CSP hashes', () {
      expect(findViolations('2021 — 2023'), isEmpty);
      expect(findViolations('Jul 2023 – Nov 2024'), isEmpty);
      expect(findViolations('2021-2023'), isEmpty);
      expect(findViolations('2021\u20132023'), isEmpty);
      expect(findViolations('Released 2026-10-19'), isEmpty);
      expect(
        findViolations('sha 3f08b09c4e1d7a2b5f6089a1b2c3d4e5f6a7b8c9'),
        isEmpty,
      );
      expect(findViolations('Lighthouse 100, LCP 0.96 s, 2.19 MB'), isEmpty);
      expect(findViolations('id 1234567890123456'), isEmpty);
      expect(
        findViolations(
          "'sha256-4OS4jRSVdIyUgRe46AdYhnZ5ceJmpTJqKL3iTuQ+F98=' "
          "'sha256-ViLKY6d8TdJEw9cl7B3AzGfyJRhXZKDBnjIIowYeVGI='",
        ),
        isEmpty,
      );
    });
  });

  group('scanPaths', () {
    test('returns hits in sorted path order', () {
      final dir = Directory.systemTemp.createTempSync('content_guard_');
      addTearDown(() => dir.deleteSync(recursive: true));
      for (final name in ['c', 'a', 'b']) {
        File('${dir.path}/$name.txt').writeAsStringSync('Senior');
      }
      final hits = scanPaths([dir.path]);
      expect(hits, orderedEquals([...hits]..sort()));
      expect(hits, hasLength(3));
    });

    test('reports file:line for a hit and skips binary files', () {
      final dir = Directory.systemTemp.createTempSync('content_guard_');
      addTearDown(() => dir.deleteSync(recursive: true));
      File('${dir.path}/a.txt').writeAsStringSync('fine\nSenior dev\n');
      File('${dir.path}/b.bin').writeAsBytesSync([0, 1, 2, 0xff, 0xfe]);
      final hits = scanPaths([dir.path]);
      expect(hits, hasLength(1));
      expect(hits.single, contains('a.txt:2'));
    });

    test('lib/, assets/ (if present) and web/ contain no violations', () {
      final roots = [
        'lib',
        'assets',
        'web',
      ].where((p) => Directory(p).existsSync());
      expect(roots, contains('lib'));
      expect(scanPaths(roots), isEmpty);
    });
  });
}
