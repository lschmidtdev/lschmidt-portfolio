import 'package:alchemist/alchemist.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lschmidt_portfolio/core/widgets/section_shell.dart';
import 'package:lschmidt_portfolio/domain/entities/app_locale.dart';
import 'package:lschmidt_portfolio/domain/entities/contact_message.dart';
import 'package:lschmidt_portfolio/domain/repositories/contact_repository.dart';
import 'package:lschmidt_portfolio/presentation/cubits/contact_form_cubit.dart';
import 'package:lschmidt_portfolio/presentation/sections/contact_section.dart';

import '../../helpers/pump_ls.dart';

class _NoRepository implements ContactRepository {
  @override
  Future<void> send(ContactMessage message) async {}
}

class _FailedCubit extends ContactFormCubit {
  _FailedCubit() : super(_NoRepository()) {
    emit(
      const ContactFailed(
        ContactMessage(
          name: 'Ana Recruiter',
          email: 'ana@example.com',
          company: 'Acme',
          message: 'We have a remote Flutter role for you.',
        ),
      ),
    );
  }
}

Widget _section({required bool failed}) => SectionScope(
  keys: SectionKeys(),
  child: BlocProvider<ContactFormCubit>(
    create: (_) => failed ? _FailedCubit() : ContactFormCubit(_NoRepository()),
    child: const ContactSection(locale: AppLocale.en, cvAvailable: true),
  ),
);

List<GoldenTestScenario> _scenarios(double width) => [
  for (final light in [false, true])
    for (final failed in [false, true])
      GoldenTestScenario(
        name:
            '$width ${light ? 'light' : 'dark'} ${failed ? 'failed' : 'idle'}',
        child: atWidth(width, _section(failed: failed), light: light),
      ),
];

void main() {
  goldenTest(
    'contact at 1440',
    fileName: 'contact_desktop',
    builder: () => GoldenTestGroup(
      columns: 1,
      columnWidthBuilder: (_) => const FixedColumnWidth(1440 + 32),
      children: _scenarios(1440),
    ),
  );

  goldenTest(
    'contact at 390',
    fileName: 'contact_phone',
    builder: () => GoldenTestGroup(
      columns: 2,
      columnWidthBuilder: (_) => const FixedColumnWidth(390 + 32),
      children: _scenarios(390),
    ),
  );
}
