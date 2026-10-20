import 'dart:convert';
import 'dart:io';

final _versionLine = RegExp(r'^version:\s*(\S+)\s*$', multiLine: true);

String readPubspecVersion(String pubspecContent) {
  final match = _versionLine.firstMatch(pubspecContent);
  if (match == null) {
    throw const FormatException('pubspec.yaml has no "version:" line');
  }
  return match.group(1)!;
}

File writeBuildInfo({
  required Directory outDir,
  required Map<String, String> env,
  required String pubspecContent,
  DateTime? now,
}) {
  final sha = env['BUILD_SHA'] ?? env['GITHUB_SHA'];
  if (sha == null || sha.isEmpty) {
    throw StateError('BUILD_SHA or GITHUB_SHA must be set to the commit SHA');
  }
  if (!outDir.existsSync()) {
    throw StateError(
      '${outDir.path} does not exist; run `flutter build web` first',
    );
  }
  final info = {
    'sha': sha,
    'version': readPubspecVersion(pubspecContent),
    'runId': env['GITHUB_RUN_ID'] ?? 'local',
    'builtAt': (now ?? DateTime.now()).toUtc().toIso8601String(),
  };
  final file = File('${outDir.path}/build-info.json')
    ..writeAsStringSync(const JsonEncoder.withIndent('  ').convert(info));
  return file;
}

void main() {
  try {
    final file = writeBuildInfo(
      outDir: Directory('build/web'),
      env: Platform.environment,
      pubspecContent: File('pubspec.yaml').readAsStringSync(),
    );
    stdout.writeln('Wrote ${file.path}');
  } on StateError catch (e) {
    stderr.writeln('build_info: ${e.message}');
    exitCode = 1;
  } on FormatException catch (e) {
    stderr.writeln('build_info: ${e.message}');
    exitCode = 1;
  }
}
