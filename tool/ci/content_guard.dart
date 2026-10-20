import 'dart:convert';
import 'dart:io';

import 'package:lschmidt_portfolio/config/site_config.dart';

const scannedRoots = ['lib', 'assets', 'web'];

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

void main() {
  final hits = scanPaths(scannedRoots);
  if (hits.isEmpty) {
    stdout.writeln('content_guard: clean');
    return;
  }
  stderr.writeln('content_guard: forbidden content found');
  hits.forEach(stderr.writeln);
  exitCode = 1;
}
