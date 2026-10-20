import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lschmidt_portfolio/core/design/ls_colors.dart';
import 'package:lschmidt_portfolio/core/design/ls_typography.dart';
import 'package:lschmidt_portfolio/core/widgets/ls_button.dart';
import 'package:lschmidt_portfolio/core/widgets/phone_frame.dart';
import 'package:lschmidt_portfolio/core/widgets/section_shell.dart';
import 'package:lschmidt_portfolio/domain/entities/app_locale.dart';
import 'package:lschmidt_portfolio/domain/entities/project.dart';
import 'package:lschmidt_portfolio/presentation/sections/project_tile.dart';
import 'package:lschmidt_portfolio/presentation/sections/work_section.dart';

import '../../helpers/fake_portfolio_repository.dart';
import '../../helpers/pump_ls.dart';

const _order = [
  'zsplit',
  'usisaude-hmc',
  'zirkon-site',
  'meu-tecadi',
  'logi360-checklist',
];

final _playUrl = Uri.parse('https://play.google.com/store/apps/details?id=x');

List<Project> _projects(AppLocale locale, {Uri? playUrl}) => [
  for (final project in FakePortfolioRepository.contentFor(locale).projects)
    project.id == 'zsplit'
        ? Project(
            id: project.id,
            index: project.index,
            eyebrow: project.eyebrow,
            title: project.title,
            summary: project.summary,
            tags: project.tags,
            stats: project.stats,
            featured: project.featured,
            headlineStats: project.headlineStats,
            footnote: project.footnote,
            playStoreUrl: playUrl,
          )
        : project,
];

Widget _work(List<Project> projects) =>
    SingleChildScrollView(child: WorkSection(projects: projects));

Finder _tile(String id) =>
    find.byWidgetPredicate((w) => w is ProjectTile && w.project.id == id);

Offset _origin(WidgetTester tester, String id) => tester.getTopLeft(_tile(id));

void main() {
  testWidgets('renders the five tiles in canvas order', (tester) async {
    await tester.pumpLs(_work(_projects(AppLocale.en)));

    final ids = tester
        .widgetList<ProjectTile>(find.byType(ProjectTile))
        .map((tile) => tile.project.id)
        .toList();
    expect(ids, _order);
    final origins = [for (final id in _order) _origin(tester, id)];
    expect(origins[0].dy, origins[1].dy);
    expect(origins[0].dx, lessThan(origins[1].dx));
    expect(origins[2].dy, greaterThan(origins[0].dy));
    expect(origins[2].dy, origins[3].dy);
    expect(origins[3].dy, origins[4].dy);
    expect(origins[2].dx, lessThan(origins[3].dx));
    expect(origins[3].dx, lessThan(origins[4].dx));
  });

  testWidgets('stacks the tiles in the same order on a phone', (tester) async {
    await tester.pumpLs(_work(_projects(AppLocale.en)), width: 390);

    final ys = [for (final id in _order) _origin(tester, id).dy];
    expect(ys, [...ys]..sort());
    expect(ys.toSet(), hasLength(5));
  });

  testWidgets('the section header shows the heading and the count', (
    tester,
  ) async {
    await tester.pumpLs(_work(_projects(AppLocale.en)));

    expect(find.text('Selected work'), findsOne);
    expect(find.text('05 PROJECTS · 2023 — 2026'), findsOne);
  });

  testWidgets('the section header is localised', (tester) async {
    await tester.pumpLs(_work(_projects(AppLocale.pt)), locale: AppLocale.pt);

    expect(find.text('Trabalhos selecionados'), findsOne);
    expect(find.text('05 PROJETOS · 2023 — 2026'), findsOne);
  });

  testWidgets('only the Zsplit tile shows phone frames', (tester) async {
    await tester.pumpLs(_work(_projects(AppLocale.en)));

    expect(find.byType(PhoneFrame), findsNWidgets(2));
    expect(
      find.descendant(of: _tile('zsplit'), matching: find.byType(PhoneFrame)),
      findsNWidgets(2),
    );
  });

  testWidgets('the Play button is absent when there is no store link', (
    tester,
  ) async {
    await tester.pumpLs(_work(_projects(AppLocale.en)));

    expect(find.text('Get it on Google Play'), findsNothing);
    expect(find.byType(LsButton), findsNothing);
  });

  testWidgets('the Play button links to the store when the link is set', (
    tester,
  ) async {
    await tester.pumpLs(_work(_projects(AppLocale.en, playUrl: _playUrl)));

    expect(find.text('Get it on Google Play'), findsOne);
    expect(tester.widget<LsButton>(find.byType(LsButton)).href, _playUrl);
  });

  testWidgets('renders tags, stats and footnotes from the content', (
    tester,
  ) async {
    await tester.pumpLs(_work(_projects(AppLocale.en)));

    for (final tag in ['Flutter', 'BLoC', 'Supabase · RLS', 'Gemini API']) {
      expect(find.text(tag), findsOne);
    }
    for (final label in ['USISAÚDE', 'HMC', 'A11Y', 'SEO', 'LCP']) {
      expect(find.text(label), findsWidgets);
    }
    expect(find.text('0.96s'), findsOne);
    expect(find.text('Launched Jan 2025 · Google Play & App Store'), findsOne);
    expect(find.text('Upload wait: up to 5 min → 1 min max'), findsOne);
    expect(find.text('01 — PERSONAL PRODUCT · 2025 — NOW'), findsOne);
  });

  testWidgets('headline stats use the accent colour', (tester) async {
    await tester.pumpLs(_work(_projects(AppLocale.en)));

    expect(
      tester.widget<Text>(find.text('10K+')).style?.color,
      LsColors.dark.accent,
    );
  });

  testWidgets('compact stats use fg and mono', (tester) async {
    await tester.pumpLs(_work(_projects(AppLocale.en)));

    final style = tester.widget<Text>(find.text('0.96s')).style;
    expect(style?.color, LsColors.dark.fg);
    expect(style?.fontFamily, LsFonts.mono);
  });

  testWidgets('the headline flag, not the stat count, picks the style', (
    tester,
  ) async {
    final base = FakePortfolioRepository.contentFor(
      AppLocale.en,
    ).projects.firstWhere((p) => p.id == 'zirkon-site');
    final flipped = Project(
      id: base.id,
      index: base.index,
      eyebrow: base.eyebrow,
      title: base.title,
      summary: base.summary,
      tags: base.tags,
      stats: base.stats,
      featured: base.featured,
      headlineStats: true,
    );
    await tester.pumpLs(_work([flipped]));

    expect(
      tester.widget<Text>(find.text('0.96s')).style?.color,
      LsColors.dark.accent,
    );
  });

  testWidgets('the Play button fills with fg, not the accent', (tester) async {
    await tester.pumpLs(_work(_projects(AppLocale.en, playUrl: _playUrl)));

    final fill = tester
        .widgetList<Container>(
          find.descendant(
            of: find.byType(LsButton),
            matching: find.byType(Container),
          ),
        )
        .map((c) => c.decoration)
        .whereType<BoxDecoration>()
        .single
        .color;
    expect(fill, LsColors.dark.fg);
  });

  testWidgets('gives the header Work link its scroll target', (tester) async {
    await tester.pumpLs(_work(_projects(AppLocale.en)));

    expect(SectionId.work.key.currentContext, isNotNull);
  });

  testWidgets('hovering a tile brightens its border', (tester) async {
    await tester.pumpLs(_work(_projects(AppLocale.en)));
    final gesture = await tester.mouse();

    Color border() {
      final frame = tester.widget<DecoratedBox>(
        find.descendant(
          of: _tile('meu-tecadi'),
          matching: find.byKey(ProjectTile.frameKey),
        ),
      );
      return ((frame.decoration as BoxDecoration).border! as Border).top.color;
    }

    expect(border(), LsColors.dark.line);
    await gesture.moveTo(tester.getCenter(find.text('Meu Tecadi')));
    await tester.pump();
    expect(border(), LsColors.dark.fg3);
  });

  for (final locale in AppLocale.values) {
    for (final width in [360.0, 390.0, 600.0, 768.0, 1024.0, 1440.0]) {
      testWidgets('lays out at ${width.toInt()} px in ${locale.name}', (
        tester,
      ) async {
        await tester.pumpLs(
          _work(_projects(locale, playUrl: _playUrl)),
          width: width,
          height: 740,
          locale: locale,
        );

        expect(tester.takeException(), isNull);
      });
    }
  }
}
