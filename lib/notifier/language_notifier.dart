import 'package:flutter_riverpod/flutter_riverpod.dart';

// Desteklenen diller
enum AppLanguage { english, turkish }

// Dil sağlayıcı (Notifier)
class LanguageNotifier extends StateNotifier<AppLanguage> {
  LanguageNotifier() : super(AppLanguage.turkish); // Varsayılan dil: Türkçe BU kısıma shared preferences değeri gelecek

  void changeLanguage(AppLanguage newLanguage) {
    state = newLanguage;
  }
}

// Riverpod provider
final languageProvider = StateNotifierProvider<LanguageNotifier, AppLanguage>((ref) {
  return LanguageNotifier();
});
