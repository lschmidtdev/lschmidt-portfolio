import 'package:flutter/semantics.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:lschmidt_portfolio/app.dart';

void main() {
  setUrlStrategy(PathUrlStrategy(BrowserPlatformLocation(), true));
  WidgetsFlutterBinding.ensureInitialized();
  SemanticsBinding.instance.ensureSemantics();
  runApp(const App());
}
