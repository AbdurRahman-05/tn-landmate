import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'storage/local_storage.dart';

// Language State Notifier
class LanguageNotifier extends StateNotifier<String> {
  LanguageNotifier() : super('ta') {
    _load();
  }

  Future<void> _load() async {
    state = await LocalStorageService.getLanguage();
  }

  Future<void> setLanguage(String code) async {
    state = code;
    await LocalStorageService.setLanguage(code);
  }

  void toggle() {
    final next = state == 'ta' ? 'en' : 'ta';
    setLanguage(next);
  }
}

final languageProvider = StateNotifierProvider<LanguageNotifier, String>((ref) {
  return LanguageNotifier();
});

// Saved Properties State Notifier
class PropertiesNotifier extends StateNotifier<List<Map<String, dynamic>>> {
  PropertiesNotifier() : super([]) {
    load();
  }

  Future<void> load() async {
    state = await LocalStorageService.getSavedProperties();
  }

  Future<void> addProperty(Map<String, dynamic> prop) async {
    await LocalStorageService.saveProperty(prop);
    await load();
  }

  Future<void> deleteProperty(String id) async {
    await LocalStorageService.deleteProperty(id);
    await load();
  }
}

final propertiesProvider = StateNotifierProvider<PropertiesNotifier, List<Map<String, dynamic>>>((ref) {
  return PropertiesNotifier();
});
