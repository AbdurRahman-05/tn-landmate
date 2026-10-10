import 'dart:convert';
import 'tn_geography_raw.dart';

class TnGeographyData {
  static bool _initialized = false;
  static List<Map<String, dynamic>> _districts = [];
  static Map<int, List<Map<String, dynamic>>> _taluks = {};
  static Map<int, List<Map<String, dynamic>>> _villages = {};

  static void ensureInitialized() {
    if (_initialized) return;

    try {
      final decoded = json.decode(TnGeographyRaw.jsonString) as Map<String, dynamic>;

      // 1. Districts
      final rawDistricts = decoded['districts'] as List<dynamic>? ?? [];
      _districts = rawDistricts.map((d) => Map<String, dynamic>.from(d as Map)).toList();

      // 2. Taluks by District ID
      final rawTaluks = decoded['taluks'] as Map<String, dynamic>? ?? {};
      _taluks = {};
      rawTaluks.forEach((distKey, talukList) {
        final distId = int.tryParse(distKey);
        if (distId != null && talukList is List) {
          _taluks[distId] = (talukList)
              .map((t) => Map<String, dynamic>.from(t as Map))
              .toList();
        }
      });

      // 3. Villages by Taluk ID
      final rawVillages = decoded['villages'] as Map<String, dynamic>? ?? {};
      _villages = {};
      rawVillages.forEach((talukKey, villageList) {
        final talukId = int.tryParse(talukKey);
        if (talukId != null && villageList is List) {
          _villages[talukId] = (villageList)
              .map((v) => Map<String, dynamic>.from(v as Map))
              .toList();
        }
      });

      _initialized = true;
    } catch (e) {
      // Fallback safe minimum dataset if decoding ever fails
      _districts = [
        {'id': 1, 'name_en': 'Chennai', 'name_ta': 'சென்னை'},
        {'id': 2, 'name_en': 'Coimbatore', 'name_ta': 'கோயம்புத்தூர்'},
        {'id': 3, 'name_en': 'Madurai', 'name_ta': 'மதுரை'},
        {'id': 4, 'name_en': 'Tiruchirappalli', 'name_ta': 'திருச்சிராப்பள்ளி'},
        {'id': 5, 'name_en': 'Chengalpattu', 'name_ta': 'செங்கல்பட்டு'},
      ];
      _taluks = {
        1: [{'id': 1, 'name_en': 'Ambattur', 'name_ta': 'அம்பத்தூர்'}],
      };
      _villages = {
        1: [{'id': 1, 'name_en': 'Ambattur', 'name_ta': 'அம்பத்தூர்'}],
      };
      _initialized = true;
    }
  }

  /// All 38 Revenue Districts of Tamil Nadu
  static List<Map<String, dynamic>> get districts {
    ensureInitialized();
    return _districts;
  }

  /// All Taluks for the specified district
  static List<Map<String, dynamic>> getTaluksForDistrict(int? districtId) {
    if (districtId == null) return [];
    ensureInitialized();
    return _taluks[districtId] ?? [];
  }

  /// All Revenue Villages for the specified taluk
  static List<Map<String, dynamic>> getVillagesForTaluk(int? talukId) {
    if (talukId == null) return [];
    ensureInitialized();
    return _villages[talukId] ?? [];
  }

  static String getDistrictName(int? districtId, [String lang = 'en']) {
    if (districtId == null) return 'Chennai';
    ensureInitialized();
    final match = _districts.where((d) => d['id'] == districtId);
    if (match.isNotEmpty) {
      final d = match.first;
      return lang == 'ta' ? (d['name_ta'] ?? d['name_en']) : d['name_en'];
    }
    return 'Chennai';
  }

  static String getTalukName(int? districtId, int? talukId, [String lang = 'en']) {
    if (talukId == null) return 'Ambattur';
    ensureInitialized();
    final list = districtId != null ? (_taluks[districtId] ?? []) : [];
    final match = list.where((t) => t['id'] == talukId);
    if (match.isNotEmpty) {
      final t = match.first;
      return lang == 'ta' ? (t['name_ta'] ?? t['name_en']) : t['name_en'];
    }
    // Search across all taluks if districtId not provided or not found
    for (final tList in _taluks.values) {
      for (final t in tList) {
        if (t['id'] == talukId) {
          return lang == 'ta' ? (t['name_ta'] ?? t['name_en']) : t['name_en'];
        }
      }
    }
    return 'Ambattur';
  }

  static String getVillageName(int? talukId, int? villageId, [String lang = 'en']) {
    if (villageId == null) return 'Ambattur';
    ensureInitialized();
    final list = talukId != null ? (_villages[talukId] ?? []) : [];
    final match = list.where((v) => v['id'] == villageId);
    if (match.isNotEmpty) {
      final v = match.first;
      return lang == 'ta' ? (v['name_ta'] ?? v['name_en']) : v['name_en'];
    }
    // Fallback search across all villages
    for (final vList in _villages.values) {
      for (final v in vList) {
        if (v['id'] == villageId) {
          return lang == 'ta' ? (v['name_ta'] ?? v['name_en']) : v['name_en'];
        }
      }
    }
    return 'Ambattur';
  }
}
