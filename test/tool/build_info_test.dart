import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../../tool/ci/build_info.dart';

void main() {
  group('readPubspecVersion', () {
    test('reads a version with a build number', () {
      expect(readPubspecVersion('name: x\nversion: 0.1.0+1\n'), '0.1.0+1');
    });

    test('handles CRLF line endings', () {
      expect(readPubspecVersion('name: x\r\nversion: 0.2.0\r\n'), '0.2.0');
    });

    test('throws FormatException when the version line is missing', () {
      expect(() => readPubspecVersion('name: x\n'), throwsFormatException);
    });
  });

  group('writeBuildInfo', () {
    late Directory outDir;

    setUp(() => outDir = Directory.systemTemp.createTempSync('build_info'));
    tearDown(() => outDir.deleteSync(recursive: true));

    Map<String, dynamic> read(File file) =>
        jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;

    test('writes sha, version, runId and a UTC timestamp', () {
      final file = writeBuildInfo(
        outDir: outDir,
        env: {'GITHUB_SHA': 'abc123', 'GITHUB_RUN_ID': '42'},
        pubspecContent: 'version: 0.2.0+3\n',
        now: DateTime.utc(2026, 10, 9, 12),
      );

      expect(file.path, endsWith('build-info.json'));
      expect(read(file), {
        'sha': 'abc123',
        'version': '0.2.0+3',
        'runId': '42',
        'builtAt': '2026-10-09T12:00:00.000Z',
      });
    });

    test('prefers BUILD_SHA over GITHUB_SHA', () {
      final file = writeBuildInfo(
        outDir: outDir,
        env: {'BUILD_SHA': 'head', 'GITHUB_SHA': 'merge'},
        pubspecContent: 'version: 1.0.0\n',
      );

      expect(read(file)['sha'], 'head');
      expect(read(file)['runId'], 'local');
    });

    test('fails clearly when no SHA is set', () {
      expect(
        () => writeBuildInfo(
          outDir: outDir,
          env: const {},
          pubspecContent: 'version: 1.0.0\n',
        ),
        throwsA(
          isA<StateError>().having(
            (e) => e.message,
            'message',
            contains('SHA'),
          ),
        ),
      );
    });

    test('fails clearly when the build directory does not exist', () {
      final missing = Directory('${outDir.path}/nope');
      expect(
        () => writeBuildInfo(
          outDir: missing,
          env: const {'GITHUB_SHA': 'abc'},
          pubspecContent: 'version: 1.0.0\n',
        ),
        throwsA(
          isA<StateError>().having(
            (e) => e.message,
            'message',
            contains('flutter build web'),
          ),
        ),
      );
    });
  });
}
