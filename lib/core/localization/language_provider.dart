import 'package:flutter/material.dart';
import 'app_translations.dart';

class LanguageProvider extends ChangeNotifier {
  Locale _currentLocale = const Locale('en');

  Locale get currentLocale => _currentLocale;
  String get currentLanguageCode => _currentLocale.languageCode;

  void changeLanguage(String langCode) {
    if (langCode == 'English')
      _currentLocale = const Locale('en');
    else if (langCode == 'Hindi')
      _currentLocale = const Locale('hi');
    else if (langCode == 'Gujarati')
      _currentLocale = const Locale('gu');
    else
      _currentLocale = Locale(langCode);

    notifyListeners();
  }

  String translate(String key) {
    return AppTranslations.getText(key, _currentLocale.languageCode);
  }
}
