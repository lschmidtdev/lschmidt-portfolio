import 'package:web/web.dart' as web;

void setDocumentLang(String lang) =>
    web.document.documentElement?.setAttribute('lang', lang);
