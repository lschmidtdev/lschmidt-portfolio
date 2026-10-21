import 'package:flutter_test/flutter_test.dart';
import 'package:lschmidt_portfolio/config/site_config.dart';
import 'package:lschmidt_portfolio/domain/entities/app_locale.dart';
import 'package:lschmidt_portfolio/presentation/sections/site_footer.dart';

import '../../helpers/pump_ls.dart';

void main() {
  testWidgets('shows the copyright and the CV date when the CV is available', (
    tester,
  ) async {
    await tester.pumpLs(const SiteFooter(cvAvailable: true));

    expect(find.text('© 2026 Lucas Schmidt'), findsOne);
    expect(
      find.text('Built with Flutter Web · CV updated ${SiteConfig.cvUpdated}'),
      findsOne,
    );
  });

  testWidgets('omits the CV date while no CV is published', (tester) async {
    await tester.pumpLs(const SiteFooter(cvAvailable: false));

    expect(find.text('© 2026 Lucas Schmidt'), findsOne);
    expect(find.text('Built with Flutter Web'), findsOne);
    expect(find.textContaining('CV updated'), findsNothing);
  });

  testWidgets('follows SiteConfig by default', (tester) async {
    await tester.pumpLs(const SiteFooter());

    expect(
      find.textContaining('CV updated'),
      SiteConfig.cvAvailable ? findsOne : findsNothing,
    );
  });

  testWidgets('is translated in Portuguese', (tester) async {
    await tester.pumpLs(
      const SiteFooter(cvAvailable: true),
      locale: AppLocale.pt,
    );

    expect(
      find.text(
        'Feito com Flutter Web · CV atualizado em ${SiteConfig.cvUpdated}',
      ),
      findsOne,
    );
  });

  for (final locale in AppLocale.values) {
    for (final width in [360.0, 390.0, 768.0, 1440.0]) {
      testWidgets('lays out without overflow at ${width.toInt()} px in '
          '${locale.name}', (tester) async {
        await tester.pumpLs(
          const SiteFooter(cvAvailable: true),
          width: width,
          height: 740,
          locale: locale,
        );

        expect(tester.takeException(), isNull);
      });
    }
  }
}
