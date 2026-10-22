import 'dart:convert';
import 'dart:io';

import 'package:lschmidt_portfolio/config/site_config.dart';

const scannedRoots = ['lib', 'assets', 'web'];
const pdfRoots = ['web/cv'];

final _rules = <String, RegExp>{
  'the word "senior"': RegExp(r'\bs[eê]nior\b', caseSensitive: false),
  'freelance copy': RegExp(r'freelanc', caseSensitive: false),
  'WhatsApp': RegExp(r'whatsapp', caseSensitive: false),
  'phone number (+55)': RegExp(
    r'(?<!\d)\+?55\s?\(?\d{2}\)?\s?9?\s?\d{4}[-.\s]?\d{4}(?!\d)',
  ),
  'phone number (local)': RegExp(
    r'(?<!\d)\(?\d{2}\)?\s?9?\s?\d{4}[-.\s]\d{4}(?!\d)',
  ),
};

final _email = RegExp(r'[\w.+-]+@[\w-]+(?:\.[\w-]+)+');

bool _hasForeignEmail(String text) => _email
    .allMatches(text)
    .any((m) => m.group(0)!.toLowerCase() != SiteConfig.email);

List<String> findViolations(String text) => [
  for (final rule in _rules.entries)
    if (rule.value.hasMatch(text)) rule.key,
  if (_hasForeignEmail(text)) 'email address other than the site address',
];

List<String> scanPaths(Iterable<String> roots) {
  final hits = <String>[];
  for (final root in roots) {
    final dir = Directory(root);
    if (!dir.existsSync()) continue;
    final files =
        dir
            .listSync(recursive: true, followLinks: false)
            .whereType<File>()
            .toList()
          ..sort((a, b) => a.path.compareTo(b.path));
    for (final file in files) {
      final String text;
      try {
        text = utf8.decode(file.readAsBytesSync());
      } on FormatException {
        continue;
      }
      if (text.contains('\u0000')) continue;
      final lines = text.split('\n');
      for (var i = 0; i < lines.length; i++) {
        for (final violation in findViolations(lines[i])) {
          hits.add('${file.path.replaceAll(r'\', '/')}:${i + 1}: $violation');
        }
      }
    }
  }
  return hits;
}

String _normalizeSeparators(String text) => text
    .replaceAll(RegExp('[\u200b-\u200d\u2060\ufeff]'), '')
    .replaceAll(RegExp('[\u00ad\u2010-\u2015\u2212]'), '-');

String _normalizeText(String text) =>
    _normalizeSeparators(text).replaceAll(RegExp(r'\s+'), ' ').trim();

String _joinWrappedAddresses(String text) => text
    .replaceAll(RegExp(r'\s*@\s*'), '@')
    .replaceAll(RegExp(r'\s*\.\s*'), '.');

List<String> _wholeTextViolations(String text) {
  final normalized = _normalizeText(text);
  return {
    ...findViolations(normalized),
    ...findViolations(_joinWrappedAddresses(normalized)),
  }.toList();
}

List<File> _listPdfs(Iterable<String> roots) => [
  for (final root in roots)
    if (Directory(root).existsSync())
      ...(Directory(root)
          .listSync(recursive: true, followLinks: false)
          .whereType<File>()
          .where((f) => f.path.toLowerCase().endsWith('.pdf'))
          .toList()
        ..sort((a, b) => a.path.compareTo(b.path))),
];

String _runPdfTool(String executable, List<String> arguments, File pdf) {
  final ProcessResult result;
  try {
    result = Process.runSync(
      executable,
      arguments,
      stdoutEncoding: utf8,
      stderrEncoding: utf8,
    );
  } on ProcessException catch (e) {
    throw StateError(
      'cannot scan ${pdf.path}: $executable is not available (${e.message})',
    );
  }
  if (result.exitCode != 0) {
    throw StateError(
      'cannot scan ${pdf.path}: $executable exited with '
      '${result.exitCode}: ${(result.stderr as String).trim()}',
    );
  }
  return result.stdout as String;
}

List<String> scanPdfs(
  Iterable<String> roots, {
  String executable = 'pdftotext',
}) {
  final hits = <String>[];
  for (final pdf in _listPdfs(roots)) {
    final text = _runPdfTool(executable, [
      '-layout',
      '-enc',
      'UTF-8',
      pdf.path,
      '-',
    ], pdf);
    final name = pdf.path.replaceAll(r'\', '/');
    if (text.trim().isEmpty) {
      throw StateError('cannot scan $name: the PDF contains no text');
    }
    final lineViolations = <String>{};
    final lines = text.split('\n');
    for (var i = 0; i < lines.length; i++) {
      for (final violation in findViolations(_normalizeSeparators(lines[i]))) {
        lineViolations.add(violation);
        hits.add('$name:${i + 1}: $violation');
      }
    }
    for (final violation in _wholeTextViolations(text)) {
      if (!lineViolations.contains(violation)) hits.add('$name: $violation');
    }
  }
  return hits;
}

const _metadataFields = ['Title', 'Author', 'Subject', 'Keywords'];

final _urlRow = RegExp(r'^\s*(\d+)\s+\S+\s+(\S.*?)\s*$');

String _decodeUri(String uri) {
  try {
    return Uri.decodeFull(uri);
  } on ArgumentError {
    return uri;
  }
}

List<String> _uriViolations(String uri) {
  final decoded = _decodeUri(uri);
  return [
    if (decoded.trimLeft().toLowerCase().startsWith('tel:')) 'phone link',
    ...findViolations(_normalizeSeparators(decoded)),
  ];
}

List<String> scanPdfMetadata(
  Iterable<String> roots, {
  String executable = 'pdfinfo',
}) {
  final hits = <String>[];
  for (final pdf in _listPdfs(roots)) {
    final name = pdf.path.replaceAll(r'\', '/');
    final info = _runPdfTool(executable, ['-enc', 'UTF-8', pdf.path], pdf);
    for (final line in info.split('\n')) {
      for (final field in _metadataFields) {
        if (!line.startsWith('$field:')) continue;
        final value = line.substring(field.length + 1).trim();
        for (final violation in _wholeTextViolations(value)) {
          hits.add('$name ($field): $violation');
        }
      }
    }
    final urls = _runPdfTool(executable, ['-url', pdf.path], pdf);
    for (final line in urls.split('\n')) {
      final row = _urlRow.firstMatch(line);
      if (row == null) continue;
      for (final violation in _uriViolations(row.group(2)!)) {
        hits.add('$name (link on page ${row.group(1)}): $violation');
      }
    }
  }
  return hits;
}

void main() {
  final List<String> hits;
  try {
    hits = [
      ...scanPaths(scannedRoots),
      ...scanPdfs(
        pdfRoots,
        executable: Platform.environment['PDFTOTEXT'] ?? 'pdftotext',
      ),
      ...scanPdfMetadata(
        pdfRoots,
        executable: Platform.environment['PDFINFO'] ?? 'pdfinfo',
      ),
    ];
  } on StateError catch (e) {
    stderr.writeln('content_guard: ${e.message}');
    exitCode = 1;
    return;
  }
  if (hits.isEmpty) {
    stdout.writeln('content_guard: clean');
    return;
  }
  stderr.writeln('content_guard: forbidden content found');
  hits.forEach(stderr.writeln);
  exitCode = 1;
}
