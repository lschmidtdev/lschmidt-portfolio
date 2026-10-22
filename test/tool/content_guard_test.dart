import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../../tool/ci/content_guard.dart';

String _escapePdfText(String text) => text
    .replaceAll(r'\', r'\\')
    .replaceAll('(', r'\(')
    .replaceAll(')', r'\)')
    .replaceAll('–', r'\226')
    .replaceAll('\u00ad', r'\202')
    .replaceAll('\u200b', r'\201');

List<int> buildPdf(
  List<String> lines, {
  List<String> links = const [],
  Map<String, String> info = const {},
}) {
  final stream = StringBuffer('BT /F1 12 Tf 72 720 Td 14 TL\n');
  for (final line in lines) {
    stream.writeln('(${_escapePdfText(line)}) Tj T*');
  }
  stream.write('ET');
  final content = stream.toString();
  final annotRefs = [for (var i = 0; i < links.length; i++) '${6 + i} 0 R'];
  final infoRef = 6 + links.length;
  final objects = [
    '<< /Type /Catalog /Pages 2 0 R >>',
    '<< /Type /Pages /Kids [3 0 R] /Count 1 >>',
    '<< /Type /Page /Parent 2 0 R /MediaBox [0 0 612 792] '
        '/Contents 4 0 R /Resources << /Font << /F1 5 0 R >> >> '
        '/Annots [${annotRefs.join(' ')}] >>',
    '<< /Length ${content.length} >>\nstream\n$content\nendstream',
    '<< /Type /Font /Subtype /Type1 /BaseFont /Helvetica '
        '/Encoding << /BaseEncoding /WinAnsiEncoding '
        '/Differences [129 /uni200B /uni00AD] >> '
        '/FirstChar 32 /LastChar 255 '
        '/Widths [${List.filled(224, 556).join(' ')}] >>',
    for (final link in links)
      '<< /Type /Annot /Subtype /Link /Rect [72 700 300 730] '
          '/A << /S /URI /URI (${_escapePdfText(link)}) >> >>',
    '<< ${[for (final e in info.entries) '/${e.key} (${_escapePdfText(e.value)})'].join(' ')} >>',
  ];
  final out = StringBuffer('%PDF-1.4\n');
  final offsets = <int>[];
  for (var i = 0; i < objects.length; i++) {
    offsets.add(out.length);
    out.write('${i + 1} 0 obj\n${objects[i]}\nendobj\n');
  }
  final xref = out.length;
  out.write('xref\n0 ${objects.length + 1}\n0000000000 65535 f \n');
  for (final offset in offsets) {
    out.write('${offset.toString().padLeft(10, '0')} 00000 n \n');
  }
  out.write(
    'trailer\n<< /Size ${objects.length + 1} /Root 1 0 R '
    '/Info $infoRef 0 R >>\n'
    'startxref\n$xref\n%%EOF\n',
  );
  return latin1.encode(out.toString());
}

Directory pdfDir(Map<String, List<String>> files) {
  final dir = Directory.systemTemp.createTempSync('content_guard_pdf_');
  addTearDown(() => dir.deleteSync(recursive: true));
  files.forEach((name, lines) {
    File('${dir.path}/$name').writeAsBytesSync(buildPdf(lines));
  });
  return dir;
}

Directory annotatedPdfDir({
  List<String> lines = const ['Jane Doe'],
  List<String> links = const [],
  Map<String, String> info = const {},
}) {
  final dir = Directory.systemTemp.createTempSync('content_guard_pdf_');
  addTearDown(() => dir.deleteSync(recursive: true));
  File(
    '${dir.path}/cv.pdf',
  ).writeAsBytesSync(buildPdf(lines, links: links, info: info));
  return dir;
}

bool _toolMissing(String executable) {
  try {
    Process.runSync(executable, ['-v']);
    return false;
  } on ProcessException {
    return true;
  }
}

final Object _skipWithoutPdfinfo =
    _toolMissing('pdfinfo') && !Platform.environment.containsKey('CI')
    ? 'pdfinfo is not installed'
    : false;

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

  group('scanPdfs', () {
    test('flags a phone number inside a PDF', () {
      final dir = pdfDir({
        'cv.pdf': ['Jane Doe', 'Phone +55 11 9 8765-4321'],
      });
      final hits = scanPdfs([dir.path]);
      expect(hits, isNotEmpty);
      expect(hits, everyElement(contains('cv.pdf:2')));
      expect(hits, everyElement(contains('phone number')));
    });

    test('flags a foreign email inside a PDF', () {
      final dir = pdfDir({
        'cv.pdf': ['Mail someone@example.com'],
      });
      final hits = scanPdfs([dir.path]);
      expect(hits, isNotEmpty);
      expect(hits, everyElement(contains('email')));
    });

    test('passes a clean PDF', () {
      final dir = pdfDir({
        'cv.pdf': ['Jane Doe', 'Mail lschmidt.dev@gmail.com'],
      });
      expect(scanPdfs([dir.path]), isEmpty);
    });

    test('passes when the directory is missing or holds no PDFs', () {
      final dir = Directory.systemTemp.createTempSync('content_guard_pdf_');
      addTearDown(() => dir.deleteSync(recursive: true));
      File('${dir.path}/note.txt').writeAsStringSync('Senior');
      expect(scanPdfs(['${dir.path}/missing']), isEmpty);
      expect(scanPdfs([dir.path]), isEmpty);
    });

    test('fails loudly when pdftotext is unavailable and PDFs exist', () {
      final dir = pdfDir({
        'cv.pdf': ['Jane Doe'],
      });
      expect(
        () => scanPdfs([dir.path], executable: 'no-such-pdftotext'),
        throwsA(isA<StateError>()),
      );
    });

    test('flags contact details that the layout splits or disguises', () {
      final cases = {
        'wrapped number': ['Call +55 11 9', '8765-4321'],
        'wrapped email': ['Mail someone@', 'example.com'],
        'en-dash number': ['Call (11) 98765–4321'],
        'wide-spaced number': ['Call (11) 98765                    4321'],
        'soft-hyphen number': ['Call (11) 98765\u00ad4321'],
        'zero-width-split number': ['Call (11) 9876\u200b5-4321'],
      };
      cases.forEach((label, lines) {
        final dir = pdfDir({'cv.pdf': lines});
        expect(scanPdfs([dir.path]), isNotEmpty, reason: label);
      });
    });

    test('reports whole-text hits without a line number', () {
      final dir = pdfDir({
        'cv.pdf': ['Mail someone@', 'example.com'],
      });
      final hits = scanPdfs([dir.path]);
      expect(hits, hasLength(1));
      expect(
        hits.single,
        endsWith('cv.pdf: email address other than the site address'),
      );
    });

    test('fails when a PDF has no extractable text', () {
      final dir = pdfDir({'cv.pdf': []});
      expect(() => scanPdfs([dir.path]), throwsA(isA<StateError>()));
    });

    test('does not need pdftotext when there are no PDFs', () {
      expect(
        scanPdfs(['${Directory.systemTemp.path}/none'], executable: 'nope'),
        isEmpty,
      );
    });
  });

  group('scanPdfMetadata', () {
    test('flags a mailto link when the text is clean', () {
      final dir = annotatedPdfDir(links: ['mailto:someone@example.com']);
      expect(scanPdfs([dir.path]), isEmpty);
      final hits = scanPdfMetadata([dir.path]);
      expect(hits, hasLength(1));
      expect(hits.single, contains('cv.pdf (link on page 1)'));
      expect(hits.single, contains('email'));
    }, skip: _skipWithoutPdfinfo);

    test('flags a percent-encoded mailto link', () {
      final dir = annotatedPdfDir(links: ['mailto:someone%40example.com']);
      expect(scanPdfMetadata([dir.path]), isNotEmpty);
    }, skip: _skipWithoutPdfinfo);

    test('flags any tel link', () {
      final dir = annotatedPdfDir(links: ['tel:+15550100']);
      final hits = scanPdfMetadata([dir.path]);
      expect(hits, isNotEmpty);
      expect(hits, everyElement(contains('phone link')));
    }, skip: _skipWithoutPdfinfo);

    test('flags forbidden document metadata', () {
      final cases = {
        'Author': 'Jane Roe someone@example.com',
        'Title': 'Senior Flutter Developer',
        'Subject': 'Call (11) 98765-4321',
        'Keywords': 'flutter, freelance',
      };
      cases.forEach((field, value) {
        final dir = annotatedPdfDir(info: {field: value});
        final hits = scanPdfMetadata([dir.path]);
        expect(hits, isNotEmpty, reason: field);
        expect(hits, everyElement(contains('cv.pdf ($field)')), reason: field);
      });
    }, skip: _skipWithoutPdfinfo);

    test('passes clean links and metadata', () {
      final dir = annotatedPdfDir(
        links: [
          'mailto:lschmidt.dev@gmail.com',
          'https://github.com/lschmidtdev',
        ],
        info: {'Author': 'Jane Doe', 'Title': 'CV', 'Keywords': 'Flutter'},
      );
      expect(scanPdfMetadata([dir.path]), isEmpty);
    }, skip: _skipWithoutPdfinfo);

    test('fails loudly when pdfinfo is unavailable and PDFs exist', () {
      final dir = annotatedPdfDir();
      expect(
        () => scanPdfMetadata([dir.path], executable: 'no-such-pdfinfo'),
        throwsA(isA<StateError>()),
      );
    });

    test('does not need pdfinfo when there are no PDFs', () {
      expect(
        scanPdfMetadata([
          '${Directory.systemTemp.path}/none',
        ], executable: 'nope'),
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
