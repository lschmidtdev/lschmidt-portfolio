import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lschmidt_portfolio/config/site_config.dart';
import 'package:lschmidt_portfolio/core/design/ls_colors.dart';
import 'package:lschmidt_portfolio/core/design/ls_typography.dart';
import 'package:lschmidt_portfolio/core/widgets/ls_button.dart';
import 'package:lschmidt_portfolio/core/widgets/section_shell.dart';
import 'package:lschmidt_portfolio/l10n/app_localizations.dart';
import 'package:lschmidt_portfolio/presentation/cubits/content_cubit.dart';
import 'package:lschmidt_portfolio/presentation/cubits/locale_cubit.dart';
import 'package:lschmidt_portfolio/presentation/cubits/theme_cubit.dart';
import 'package:lschmidt_portfolio/presentation/sections/contact_section.dart';
import 'package:lschmidt_portfolio/presentation/sections/experience_section.dart';
import 'package:lschmidt_portfolio/presentation/sections/hero.dart';
import 'package:lschmidt_portfolio/presentation/sections/results_strip.dart';
import 'package:lschmidt_portfolio/presentation/sections/site_footer.dart';
import 'package:lschmidt_portfolio/presentation/sections/site_header.dart';
import 'package:lschmidt_portfolio/presentation/sections/skills_section.dart';
import 'package:lschmidt_portfolio/presentation/sections/work_section.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key, this.clock = DateTime.now});

  final DateTime Function() clock;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _scroll = ScrollController();
  final _sectionKeys = SectionKeys();

  @override
  void dispose() {
    _scroll.dispose();
    _sectionKeys.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final locale = context.watch<LocaleCubit>().state;
    return SectionScope(
      keys: _sectionKeys,
      child: Scaffold(
        body: PrimaryScrollController(
          controller: _scroll,
          child: SingleChildScrollView(
            controller: _scroll,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SiteHeader(
                  locale: locale,
                  onLocaleSelected: context.read<LocaleCubit>().select,
                  onToggleTheme: context.read<ThemeCubit>().toggle,
                ),
                BlocBuilder<ContentCubit, ContentState>(
                  builder: (context, state) => switch (state) {
                    ContentLoading() => const SizedBox.shrink(),
                    ContentReady(:final content) => Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        HeroSection(
                          profile: content.profile,
                          currently: content.currently,
                          locale: locale,
                          now: widget.clock(),
                        ),
                        ResultsStrip(metrics: content.metrics),
                        WorkSection(projects: content.projects),
                        ExperienceSection(roles: content.roles),
                        SkillsSection(
                          groups: content.skillGroups,
                          education: content.education,
                          languages: content.languages,
                        ),
                        ContactSection(locale: locale),
                        const SiteFooter(),
                      ],
                    ),
                    ContentError() => const Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [_ContentUnavailable(), SiteFooter()],
                    ),
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ContentUnavailable extends StatelessWidget {
  const _ContentUnavailable();

  @override
  Widget build(BuildContext context) {
    final colors = LsColors.of(context);
    final width = MediaQuery.sizeOf(context).width;
    return SectionShell(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            SiteConfig.name.replaceFirst(' ', '\n'),
            style: LsType.displayFor(width).copyWith(color: colors.fg),
          ),
          const SizedBox(height: 32),
          LsButton.ghost(
            label: AppLocalizations.of(context).heroEmailMe,
            icon: Icons.mail_outline,
            href: SiteConfig.mailto,
          ),
        ],
      ),
    );
  }
}
