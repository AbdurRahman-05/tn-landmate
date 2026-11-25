import 'dart:async';
import 'dart:convert';

import 'package:webview_flutter/webview_flutter.dart';

/// One entry of a government dropdown (district / taluk / village / subdivision).
class PortalOption {
  final String value;
  final String label;
  const PortalOption(this.value, this.label);
}

/// The official Patta / Chitta result page, as returned by the government portal.
class PortalResult {
  final String html;
  final String url;
  final String text;
  final List<List<List<String>>> tables;
  final DateTime fetchedAt;

  PortalResult({
    required this.html,
    required this.url,
    required this.text,
    required this.tables,
    required this.fetchedAt,
  });
}

class GovPortalException implements Exception {
  final String message;
  GovPortalException(this.message);
  @override
  String toString() => message;
}

/// Drives the official TN e-Services "View Patta / Chitta" form (rural, survey-number mode)
/// in a hidden, on-device WebView so the app can show its own UI while every value comes
/// from the government site.
///
/// It calls the portal's own page functions (from eservicesnew/js/common.js & landform.js):
///   distvilleng → talukrureng → villagerureng → getSubdivNo (via surveyNo onchange)
///   otpgenerate(mobile,'AC01','en') → verify_otp(mobile, otp,'en','AC01') → form submit.
///
/// Runs on the user's phone because the portal requires the citizen's own mobile + OTP and
/// rejects cloud servers.
class GovPortalBridge {
  static const String indexUrl = 'https://eservices.tn.gov.in/eservicesnew/index.html';
  static const Duration _pageTimeout = Duration(seconds: 45);
  static const Duration _ajaxTimeout = Duration(seconds: 30);
  // The result page also loads the FMB sketch from collabland-tn.gov.in, which can be slow.
  static const Duration _resultTimeout = Duration(seconds: 90);
  static const Duration _poll = Duration(milliseconds: 100);

  /// The portal's OTP is valid / resend is locked for 2 minutes (countdown "2:00").
  static const Duration otpValidity = Duration(minutes: 2);

  late final WebViewController controller;
  final List<String> _alerts = [];
  String? _navError;
  String _landType = 'R';

  GovPortalBridge() {
    controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onWebResourceError: (error) {
            if (error.isForMainFrame != true) return;
            _navError =
                'Could not reach the government portal (${error.description}). Check your internet and retry.';
          },
        ),
      );
    // The portal reports validation errors / OTP status through alert() dialogs.
    controller.setOnJavaScriptAlertDialog((request) async {
      final msg = request.message.trim();
      if (msg.isNotEmpty) _alerts.add(msg);
    });
    controller.setOnJavaScriptConfirmDialog((request) async {
      final msg = request.message.trim();
      if (msg.isNotEmpty) _alerts.add(msg);
      return true;
    });
  }

  // ---------------------------------------------------------------- session

  /// Opens the portal and the rural Patta/Chitta form. Returns the official district list.
  Future<List<PortalOption>> start() async {
    _alerts.clear();
    _navError = null;

    // 1) Home page: continue as soon as the Chitta link is in the DOM (don't wait for the
    //    banner images / carousel).
    await controller.loadRequest(Uri.parse(indexUrl));
    await _waitFor(
      "return !!document.querySelector('a[href*=\"chittaCheckNewRural_en\"]');",
      what: 'portal home page',
      timeout: _pageTimeout,
    );
    final href = await _js('''
      var a = document.querySelector('a[href*="chittaCheckNewRural_en"]');
      return a ? a.href : null;
    ''');
    if (href is! String) {
      throw GovPortalException('Patta/Chitta service is not available on the portal right now.');
    }

    // 2) Chitta form: navigate from inside the page so the browser sends the Referer the
    //    portal requires. The page only fills the district list in body.onload (after every
    //    image), so as soon as its script is ready we fill it ourselves and make the onload
    //    call a no-op so it cannot reset a selection later.
    await controller.runJavaScript('window.location.href = ${jsonEncode(href)};');
    await _waitFor('''
      if (document.body && /INVALID ACCESS/i.test(document.body.innerText)) return 'INVALID';
      var s = document.getElementById('districtCode');
      if (!s || typeof distvilleng !== 'function') return false;
      if (Array.from(s.options).some(function(o){ return o.value && o.value.trim() !== ''; })) return true;
      if (!window.__lmDist) {
        window.__lmDist = true;
        var f = window.distvilleng;
        window.distvilleng = function(){};
        try { f(); } catch (e) { window.distvilleng = f; }
      }
      return false;
    ''', what: 'district list', timeout: _pageTimeout);

    // "Survey Number (Chitta with FMB)" mode.
    await _js('''
      var r = document.querySelector('input[name=viewOpt][value=sur]'); if (r && !r.checked) r.click();
      return true;
    ''');
    await setLandType(_landType);
    return _options('districtCode');
  }

  // --------------------------------------------------------------- land details

  Future<List<PortalOption>> selectDistrict(String code) =>
      _selectAndLoad('districtCode', code, 'talukCode', 'taluk list');

  Future<List<PortalOption>> selectTaluk(String code) =>
      _selectAndLoad('talukCode', code, 'villageCode', 'village list');

  Future<void> selectVillage(String code) => _setValue('villageCode', code);

  /// 'R' = Rural, 'N' = Natham. Sets the radio directly: the portal's own click handler
  /// (viewlandtype) wipes the survey number and throws a ReferenceError.
  Future<void> setLandType(String type) async {
    _landType = type == 'N' ? 'N' : 'R';
    await _js('''
      var l = document.querySelector('input[name=landtype][value=$_landType]');
      if (l) l.checked = true;
      return true;
    ''');
  }

  /// Enters the survey number and returns the official subdivision list for it.
  Future<List<PortalOption>> loadSubdivisions(String surveyNo) async {
    _alerts.clear();
    await _js('''
      var r = document.querySelector('input[name=viewOpt][value=sur]'); if (r && !r.checked) r.click();
      var l = document.querySelector('input[name=landtype][value=$_landType]'); if (l) l.checked = true;
      var sub = document.getElementById('subdivNo'); if (sub) sub.options.length = 0;
      var s = document.getElementById('surveyNo');
      s.value = ${jsonEncode(surveyNo.trim().toUpperCase())};
      s.dispatchEvent(new Event('change', { bubbles: true }));
      return true;
    ''');
    await _waitFor('''
      var s = document.getElementById('subdivNo');
      return !!s && Array.from(s.options).some(function(o){ return o.value && o.value.trim() !== ''; });
    ''', what: 'subdivision list');
    return _options('subdivNo');
  }

  Future<void> selectSubdivision(String value) => _setValue('subdivNo', value);

  // ------------------------------------------------------------------------ OTP

  /// Asks the portal to send an OTP to [mobile] (portal function `otpgenerate`).
  /// Success = the portal starts its 2-minute countdown. Errors (invalid number, too many
  /// attempts, missing field) come back as the portal's own alert text.
  Future<String> requestOtp(String mobile) async {
    _alerts.clear();
    final m = mobile.trim();
    await _js('''
      var l = document.querySelector('input[name=landtype][value=$_landType]'); if (l) l.checked = true;
      var mob = document.getElementById('mobileno');
      mob.disabled = false;
      mob.value = ${jsonEncode(m)};
      var o = document.getElementById('otpno'); if (o) { o.disabled = false; o.value = ''; }
      var v1 = document.getElementById('otpno_ver'); if (v1) v1.value = '';
      var v2 = document.getElementById('mobileno_ver'); if (v2) v2.value = '';
      var sub = document.getElementById('sub_id'); if (sub) sub.style.display = 'none';
      var c = document.getElementById('countdown'); if (c) c.innerHTML = '';
      if (typeof interval !== 'undefined') { try { clearInterval(interval); } catch (e) {} }
      otpgenerate(mob.value, 'AC01', 'en');
      return true;
    ''');
    await _waitFor('''
      var c = document.getElementById('countdown');
      return !!c && c.innerText.trim() !== '';
    ''', what: 'OTP', timeout: const Duration(seconds: 40), alertGrace: const Duration(seconds: 2));
    final last4 = m.length >= 4 ? m.substring(m.length - 4) : m;
    return 'OTP sent to XXXXXX$last4. It is valid for 2 minutes.';
  }

  /// Verifies [otp] with the portal (portal function `verify_otp`). On success the portal
  /// stores it in the hidden otpno_ver / mobileno_ver fields and shows its Submit button.
  Future<void> verifyOtp(String otp) async {
    final code = otp.trim();
    if (code.length != 6) {
      throw GovPortalException('Enter the 6-digit OTP sent to your mobile.');
    }
    _alerts.clear();
    await _js('''
      var o = document.getElementById('otpno');
      o.disabled = false;
      o.value = ${jsonEncode(code)};
      verify_otp(document.getElementById('mobileno').value, ${jsonEncode(code)}, 'en', 'AC01');
      return true;
    ''');
    // The success alert ("Your OTP has been verified...") is followed by #sub_id showing.
    await _waitFor('''
      var s = document.getElementById('sub_id');
      var v = document.getElementById('otpno_ver');
      return !!s && getComputedStyle(s).display !== 'none' && !!v && v.value === ${jsonEncode(code)};
    ''', what: 'OTP verification', alertGrace: const Duration(seconds: 3));
  }

  /// True when the portal form has a verified OTP and can be submitted (e.g. to retry a
  /// failed fetch without asking for a new OTP).
  Future<bool> isVerifiedAndReady() async {
    try {
      final r = await _js('''
        var s = document.getElementById('sub_id');
        var v = document.getElementById('otpno_ver');
        return !!s && !!v && v.value !== '' && getComputedStyle(s).display !== 'none';
      ''');
      return r == true;
    } catch (_) {
      return false;
    }
  }

  // --------------------------------------------------------------------- result

  /// Submits the verified form and returns the official result page.
  /// Completes as soon as the result document is parsed; it does not wait for the
  /// slow FMB sketch image to finish loading.
  Future<PortalResult> fetchRecord() async {
    _alerts.clear();
    _navError = null;
    await _js('''
      var b = document.querySelector('#sub_id input[type=submit]');
      if (b) b.click(); else document.forms[0].submit();
      return true;
    ''');
    await _waitFor('''
      if (!/chittaExtract/i.test(location.href)) return false;
      if (document.readyState === 'loading') return false;
      return document.querySelectorAll('table').length > 0
          || (document.body && document.body.innerText.trim().length > 40);
    ''', what: 'Patta / Chitta record', timeout: _resultTimeout, alertGrace: const Duration(seconds: 2));

    // Give the page's own scripts a moment to finish filling tables / images (best effort).
    try {
      await _waitFor("return document.readyState === 'complete';",
          what: 'page', timeout: const Duration(seconds: 6));
    } catch (_) {}
    return _readResult();
  }

  /// Stops any activity in the hidden browser.
  Future<void> dispose() async {
    try {
      await controller.loadRequest(Uri.parse('about:blank'));
    } catch (_) {}
  }

  // ------------------------------------------------------------------ helpers

  Future<PortalResult> _readResult() async {
    final data = await _js('''
      var leaf = Array.from(document.querySelectorAll('table'))
        .filter(function(t){ return !t.querySelector('table'); });
      var tables = leaf.map(function(t){
        return Array.from(t.rows).map(function(r){
          return Array.from(r.cells).map(function(c){ return (c.innerText || '').replace(/\\s+/g, ' ').trim(); });
        }).filter(function(r){ return r.some(function(c){ return c !== ''; }); });
      }).filter(function(t){ return t.length > 0; });
      return {
        html: document.documentElement.outerHTML,
        url: location.href,
        text: document.body ? document.body.innerText : '',
        tables: tables
      };
    ''');
    if (data is! Map) throw GovPortalException('Could not read the record from the portal.');

    final tables = (data['tables'] as List? ?? [])
        .map((t) => (t as List).map((r) => (r as List).map((c) => c.toString()).toList()).toList())
        .toList();
    final text = (data['text'] ?? '').toString();
    if (RegExp('INVALID ACCESS', caseSensitive: false).hasMatch(text)) {
      throw GovPortalException('The government portal rejected the request. Please start a new search.');
    }
    if (tables.isEmpty) {
      _throwIfAlert(); // e.g. "No records found" reported by alert on the result page
      final snippet = text.trim().split('\n').where((l) => l.trim().isNotEmpty).take(3).join(' ');
      throw GovPortalException(snippet.isEmpty ? 'No record was returned by the portal.' : snippet);
    }
    return PortalResult(
      html: (data['html'] ?? '').toString(),
      url: (data['url'] ?? indexUrl).toString(),
      text: text,
      tables: tables,
      fetchedAt: DateTime.now(),
    );
  }

  Future<List<PortalOption>> _selectAndLoad(
      String selectId, String value, String dependentId, String what) async {
    _alerts.clear();
    await _js('''
      var dep = document.getElementById(${jsonEncode(dependentId)}); if (dep) dep.options.length = 0;
      var s = document.getElementById(${jsonEncode(selectId)});
      s.value = ${jsonEncode(value)};
      s.dispatchEvent(new Event('change', { bubbles: true }));
      return true;
    ''');
    await _waitFor('''
      var s = document.getElementById(${jsonEncode(dependentId)});
      return !!s && Array.from(s.options).some(function(o){ return o.value && o.value.trim() !== ''; });
    ''', what: what);
    return _options(dependentId);
  }

  Future<void> _setValue(String selectId, String value) async {
    await _js('''
      var s = document.getElementById(${jsonEncode(selectId)});
      if (s) { s.value = ${jsonEncode(value)}; s.dispatchEvent(new Event('change', { bubbles: true })); }
      return true;
    ''');
  }

  Future<List<PortalOption>> _options(String selectId) async {
    final list = await _js('''
      var s = document.getElementById(${jsonEncode(selectId)});
      if (!s) return [];
      return Array.from(s.options)
        .filter(function(o){ return o.value && o.value.trim() !== ''; })
        .map(function(o){ return { v: o.value, t: (o.text || '').trim() }; });
    ''');
    if (list is! List) return [];
    final seen = <String>{};
    return list
        .map((e) => PortalOption(e['v'].toString(), (e['t'] ?? e['v']).toString()))
        .where((o) => seen.add(o.value))
        .toList();
  }

  /// Polls [conditionBody] until true. An alert() aborts the wait with its message, unless
  /// the condition still becomes true within [alertGrace] (success messages). Returns any
  /// alerts that were shown alongside a successful result.
  Future<List<String>> _waitFor(
    String conditionBody, {
    required String what,
    Duration? timeout,
    Duration alertGrace = Duration.zero,
  }) async {
    final deadline = DateTime.now().add(timeout ?? _ajaxTimeout);
    DateTime? alertSeenAt;
    while (true) {
      final navError = _navError;
      if (navError != null) {
        _navError = null;
        throw GovPortalException(navError);
      }
      if (_alerts.isNotEmpty) {
        alertSeenAt ??= DateTime.now();
        if (DateTime.now().difference(alertSeenAt) >= alertGrace) _throwIfAlert();
      }
      dynamic state;
      try {
        state = await _js(conditionBody);
      } catch (_) {
        state = false; // page is mid-navigation; try again on the next tick
      }
      if (state == 'INVALID') {
        throw GovPortalException('The government portal refused the session. Please retry.');
      }
      if (state == true) {
        final shown = List<String>.from(_alerts);
        _alerts.clear();
        return shown;
      }
      if (DateTime.now().isAfter(deadline)) {
        throw GovPortalException('The government portal did not respond in time ($what). Please retry.');
      }
      await Future.delayed(_poll);
    }
  }

  void _throwIfAlert() {
    if (_alerts.isNotEmpty) {
      final msg = _alerts.join('\n');
      _alerts.clear();
      throw GovPortalException(msg);
    }
  }

  /// Runs [body] (a JS function body with a `return`) and decodes its result.
  /// Results are wrapped in an object so Android (JSON-quoted) and iOS (raw) decode the same way.
  Future<dynamic> _js(String body) async {
    final raw = await controller.runJavaScriptReturningResult(
        'JSON.stringify({ v: (function(){ $body })() })');
    var s = raw is String ? raw : raw.toString();
    if (s.startsWith('"')) s = jsonDecode(s) as String;
    if (s.isEmpty || s == 'null') return null;
    final decoded = jsonDecode(s);
    return decoded is Map ? decoded['v'] : null;
  }
}
