import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class LocalStorageService {
  static const String _keyLang = 'app_language';
  static const String _keyProperties = 'local_saved_properties';
  static const String _keyServerUrl = 'custom_backend_url';

  static Future<String> getLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyLang) ?? 'ta'; // Tamil by default for TN local affinity
  }

  static Future<void> setLanguage(String code) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyLang, code);
  }

  static Future<String?> getServerUrl() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyServerUrl);
  }

  static Future<void> setServerUrl(String? url) async {
    final prefs = await SharedPreferences.getInstance();
    if (url == null || url.trim().isEmpty) {
      await prefs.remove(_keyServerUrl);
    } else {
      await prefs.setString(_keyServerUrl, url.trim());
    }
  }

  static Future<List<Map<String, dynamic>>> getSavedProperties() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_keyProperties);
    if (raw == null) {
      // Seed default demo property if empty
      final initial = [
        {
          'id': 'local-1',
          'nickname': 'Chennai Ambattur Plot',
          'district_name': 'Chennai',
          'taluk_name': 'Ambattur',
          'village_name': 'Ambattur',
          'survey_number': '104',
          'subdivision_number': '2B',
          'extent_value': 5.51,
          'extent_unit': 'cents',
          'notes': 'Verified clear boundary matching FMB offset',
          'estimated_market_value': 2400000.0,
          'created_at': DateTime.now().toIso8601String(),
        }
      ];
      await prefs.setString(_keyProperties, jsonEncode(initial));
      return initial;
    }
    try {
      final List decoded = jsonDecode(raw);
      return decoded.map((e) => Map<String, dynamic>.from(e)).toList();
    } catch (_) {
      return [];
    }
  }

  static Future<void> saveProperty(Map<String, dynamic> property) async {
    final list = await getSavedProperties();
    list.insert(0, property);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyProperties, jsonEncode(list));
  }

  static Future<void> deleteProperty(String id) async {
    final list = await getSavedProperties();
    list.removeWhere((item) => item['id'] == id);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyProperties, jsonEncode(list));
  }
}
