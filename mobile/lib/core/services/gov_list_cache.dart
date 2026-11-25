import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'gov_portal_bridge.dart';

/// On-device cache of the government's own district / taluk / village lists.
///
/// These lists almost never change, so after the first live fetch they are shown instantly
/// while the hidden portal session catches up in the background. Every list is refreshed
/// from eservices.tn.gov.in whenever it is fetched live, and expires after [ttl].
class GovListCache {
  static const String _prefix = 'gov_opts_v1_';
  static const Duration ttl = Duration(days: 30);

  static String districtsKey() => 'districts';
  static String taluksKey(String district) => 'taluks_$district';
  static String villagesKey(String district, String taluk) => 'villages_${district}_$taluk';

  static Future<List<PortalOption>?> read(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString('$_prefix$key');
      if (raw == null) return null;
      final data = jsonDecode(raw) as Map<String, dynamic>;
      final saved = DateTime.fromMillisecondsSinceEpoch(data['t'] as int);
      if (DateTime.now().difference(saved) > ttl) return null;
      final list = (data['o'] as List)
          .map((e) => PortalOption((e as List)[0].toString(), e[1].toString()))
          .toList();
      return list.isEmpty ? null : list;
    } catch (_) {
      return null;
    }
  }

  static Future<void> write(String key, List<PortalOption> options) async {
    if (options.isEmpty) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        '$_prefix$key',
        jsonEncode({
          't': DateTime.now().millisecondsSinceEpoch,
          'o': options.map((o) => [o.value, o.label]).toList(),
        }),
      );
    } catch (_) {}
  }
}
