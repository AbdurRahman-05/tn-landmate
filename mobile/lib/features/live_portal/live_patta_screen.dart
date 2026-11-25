import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_auth/smart_auth.dart';
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/constants/app_colors.dart';
import '../../core/providers.dart';
import '../../core/services/chitta_pdf_service.dart';
import '../../core/services/device_files.dart';
import '../../core/services/gov_list_cache.dart';
import '../../core/services/gov_portal_bridge.dart';
import '../../core/services/gov_portal_session.dart';

/// Native Patta / Chitta screen. Every list and the final record come live from
/// eservices.tn.gov.in through [GovPortalBridge]; the government website is never shown.
class LivePattaScreen extends ConsumerStatefulWidget {
  final String? districtName;
  final String? talukName;
  final String? villageName;
  final String? surveyNumber;
  final String? subdivisionNumber;

  const LivePattaScreen({
    super.key,
    this.districtName,
    this.talukName,
    this.villageName,
    this.surveyNumber,
    this.subdivisionNumber,
  });

  @override
  ConsumerState<LivePattaScreen> createState() => _LivePattaScreenState();
}

enum _Phase { connecting, form, result, failed }

class _LivePattaScreenState extends ConsumerState<LivePattaScreen> {
  /// App-wide portal connection, opened when the app starts (see GovPortalHost).
  final GovPortalSession _session = GovPortalSession.instance;
  GovPortalBridge get _bridge => _session.bridge!;

  final TextEditingController _surveyCtrl = TextEditingController();
  final TextEditingController _mobileCtrl = TextEditingController();
  final TextEditingController _otpCtrl = TextEditingController();
  final FocusNode _mobileFocus = FocusNode();
  bool _phoneHintTried = false;
  static const String _kLastMobile = 'gov_portal_last_mobile';

  Uint8List? _pdfBytes;
  String? _savedPdfUri;

  _Phase _phase = _Phase.connecting;
  String? _busy; // label of the action in progress
  String? _error;
  String? _info;

  List<PortalOption> _districts = [];
  List<PortalOption> _taluks = [];
  List<PortalOption> _villages = [];
  List<PortalOption> _subdivs = [];
  PortalOption? _district;
  PortalOption? _taluk;
  PortalOption? _village;
  PortalOption? _subdiv;
  String _landType = 'R';
  bool _otpSent = false;
  PortalResult? _result;

  // Live portal session state. UI selections apply instantly (lists come from the on-device
  // cache of government data); the hidden portal form is synced through a serial queue.
  bool _connected = false;
  bool _loadingTaluks = false;
  bool _loadingVillages = false;
  int _pending = 0; // background sync jobs in flight
  int _gen = 0; // bumps on every reconnect so stale jobs are skipped
  Future<void> _sync = Future.value();

  bool _otpVerified = false;
  DateTime? _otpExpiresAt;
  Timer? _otpTicker;
  bool _listeningSms = false;

  static bool get _isAndroid => !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  /// Exactly six digits in a row — skips the masked mobile number and dates in the SMS.
  static const String _otpMatcher = r'(?<!\d)\d{6}(?!\d)';

  @override
  void initState() {
    super.initState();
    _surveyCtrl.text = widget.surveyNumber ?? '';
    _mobileFocus.addListener(() {
      if (_mobileFocus.hasFocus) _maybeShowPhoneHint();
    });
    _loadSavedMobile();
    Future.microtask(() => _connect());
  }

  @override
  void dispose() {
    _otpTicker?.cancel();
    if (_isAndroid) SmartAuth.instance.removeUserConsentApiListener();
    _session.release(); // prepares a fresh form in the background for next time
    _surveyCtrl.dispose();
    _mobileCtrl.dispose();
    _otpCtrl.dispose();
    _mobileFocus.dispose();
    super.dispose();
  }

  // ------------------------------------------------------- mobile number autofill

  /// Pre-fills the number used last time.
  Future<void> _loadSavedMobile() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_kLastMobile);
    if (mounted && saved != null && _mobileCtrl.text.isEmpty) {
      setState(() => _mobileCtrl.text = saved);
    }
  }

  Future<void> _saveMobile(String mobile) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kLastMobile, mobile.trim());
  }

  /// First time only (no saved number): opens Android's phone-number picker automatically
  /// when the user reaches the mobile step, so the SIM number fills in with one tap.
  Future<void> _maybeShowPhoneHint() async {
    if (!_isAndroid || _phoneHintTried || _mobileCtrl.text.trim().isNotEmpty) return;
    _phoneHintTried = true;
    await _pickPhoneNumber();
  }

  // ------------------------------------------------------------------ actions

  Future<void> _connect({bool force = false}) async {
    final gen = ++_gen;
    setState(() {
      _phase = _Phase.connecting;
      _connected = false;
      _pending = 0;
      _busy = null;
      _error = null;
      _info = null;
      _otpSent = false;
      _otpVerified = false;
      _otpExpiresAt = null;
      _otpTicker?.cancel();
      _stopSmsListener();
      _otpCtrl.clear();
      _taluks = [];
      _villages = [];
      _subdivs = [];
      _district = _taluk = _village = _subdiv = null;
      _loadingTaluks = _loadingVillages = false;
      _result = null;
      _pdfBytes = null;
      _savedPdfUri = null;
    });

    if (_session.bridge == null) {
      setState(() {
        _phase = _Phase.failed;
        _error = 'Live government connection is not supported on this device.';
      });
      return;
    }

    // Show the government district list immediately (from the session opened at app start,
    // or the on-device cache) while the live form is made ready.
    final cached = _session.districts ?? await GovListCache.read(GovListCache.districtsKey());
    if (!mounted || gen != _gen) return;
    if (cached != null) {
      setState(() {
        _districts = cached;
        _phase = _Phase.form;
      });
    }

    final ready = _session.acquire(forceReconnect: force);
    _sync = ready.then((_) {}); // every portal job waits for the live session
    if (cached != null) _autoFillFromApp();

    try {
      final live = await ready;
      await GovListCache.write(GovListCache.districtsKey(), live);
      if (!mounted || gen != _gen) return;
      final firstLoad = cached == null;
      setState(() {
        _districts = live;
        _connected = true;
        _phase = _Phase.form;
      });
      if (firstLoad) await _autoFillFromApp();
    } catch (e) {
      if (!mounted || gen != _gen) return;
      setState(() {
        if (cached == null) {
          _phase = _Phase.failed;
          _error = e.toString();
        } else {
          _error = 'Live connection failed: $e\nTap the refresh icon to retry.';
        }
      });
    }
  }

  /// Pre-selects the district / taluk / village / survey the user already chose in the app.
  Future<void> _autoFillFromApp() async {
    final d = _match(_districts, widget.districtName);
    if (d == null) return;
    await _onDistrict(d);
    final t = _match(_taluks, widget.talukName);
    if (t == null) return;
    await _onTaluk(t);
    final v = _match(_villages, widget.villageName);
    if (v == null) return;
    await _onVillage(v);
    if (_surveyCtrl.text.trim().isNotEmpty) {
      await _loadSubdivs();
      final s = _match(_subdivs, widget.subdivisionNumber, exact: true);
      if (s != null) await _onSubdiv(s);
    }
  }

  /// Runs [job] against the hidden portal form, strictly in order. [label] != null means the
  /// user is waiting on it (shows the progress bar and disables inputs); otherwise it runs
  /// quietly in the background. Jobs from a previous session are skipped.
  Future<void> _enqueue(Future<void> Function() job, {String? label}) {
    final gen = _gen;
    final blocking = label != null;
    setState(() {
      _error = null;
      if (blocking) {
        _busy = label;
      } else {
        _pending++;
      }
    });
    final run = _sync.then((_) async {
      if (gen == _gen) await job();
    });
    _sync = run.catchError((_) {});
    return run.catchError((e) {
      if (mounted && gen == _gen) setState(() => _error = e.toString());
    }).whenComplete(() {
      if (!mounted || gen != _gen) return;
      setState(() {
        if (blocking) {
          _busy = null;
        } else {
          _pending--;
        }
      });
    });
  }

  /// Local, non-portal work (e.g. PDF export) with the progress bar.
  Future<void> _run(String label, Future<void> Function() action) async {
    setState(() {
      _busy = label;
      _error = null;
    });
    try {
      await action();
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _busy = null);
    }
  }

  Future<void> _onDistrict(PortalOption o) async {
    setState(() {
      _district = o;
      _taluk = _village = _subdiv = null;
      _taluks = [];
      _villages = [];
      _subdivs = [];
    });
    final cached = await GovListCache.read(GovListCache.taluksKey(o.value));
    if (!mounted || _district != o) return;
    setState(() {
      _taluks = cached ?? [];
      _loadingTaluks = cached == null;
    });
    final job = _enqueue(() async {
      if (_district != o) return; // user already picked another district
      try {
        final live = await _bridge.selectDistrict(o.value);
        await GovListCache.write(GovListCache.taluksKey(o.value), live);
        if (mounted && _district == o) setState(() => _taluks = live);
      } finally {
        if (mounted && _district == o) setState(() => _loadingTaluks = false);
      }
    });
    if (cached == null) await job; // nothing to show until the portal answers
  }

  Future<void> _onTaluk(PortalOption o) async {
    final d = _district;
    if (d == null) return;
    setState(() {
      _taluk = o;
      _village = _subdiv = null;
      _villages = [];
      _subdivs = [];
    });
    final cached = await GovListCache.read(GovListCache.villagesKey(d.value, o.value));
    if (!mounted || _taluk != o) return;
    setState(() {
      _villages = cached ?? [];
      _loadingVillages = cached == null;
    });
    final job = _enqueue(() async {
      if (_taluk != o) return;
      try {
        final live = await _bridge.selectTaluk(o.value);
        await GovListCache.write(GovListCache.villagesKey(d.value, o.value), live);
        if (mounted && _taluk == o) setState(() => _villages = live);
      } finally {
        if (mounted && _taluk == o) setState(() => _loadingVillages = false);
      }
    });
    if (cached == null) await job;
  }

  Future<void> _onVillage(PortalOption o) async {
    setState(() {
      _village = o;
      _subdiv = null;
      _subdivs = [];
    });
    await _enqueue(() async {
      if (_village == o) await _bridge.selectVillage(o.value);
    });
  }

  Future<void> _onLandType(String type) async {
    setState(() {
      _landType = type;
      _subdiv = null;
      _subdivs = [];
    });
    await _enqueue(() => _bridge.setLandType(type));
  }

  Future<void> _loadSubdivs() async {
    if (_village == null) {
      setState(() => _error = 'Select district, taluk and village first.');
      return;
    }
    if (_surveyCtrl.text.trim().isEmpty) {
      setState(() => _error = 'Enter the survey number.');
      return;
    }
    final survey = _surveyCtrl.text;
    await _enqueue(() async {
      final subs = await _bridge.loadSubdivisions(survey);
      if (subs.length == 1) await _bridge.selectSubdivision(subs.first.value);
      if (!mounted) return;
      setState(() {
        _subdivs = subs;
        _subdiv = subs.length == 1 ? subs.first : null;
      });
    }, label: 'Loading subdivisions from portal…');
  }

  Future<void> _onSubdiv(PortalOption o) async {
    setState(() => _subdiv = o);
    await _enqueue(() => _bridge.selectSubdivision(o.value));
    _maybeShowPhoneHint(); // next step is the mobile number
  }

  /// Seconds until the portal unlocks "Resend OTP" (its own 2-minute countdown).
  int get _otpSecondsLeft {
    final exp = _otpExpiresAt;
    if (exp == null) return 0;
    final s = exp.difference(DateTime.now()).inSeconds;
    return s > 0 ? s : 0;
  }

  String _fmt(int seconds) => '${seconds ~/ 60}:${(seconds % 60).toString().padLeft(2, '0')}';

  void _startOtpTimer() {
    _otpTicker?.cancel();
    _otpTicker = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return t.cancel();
      setState(() {});
      if (_otpSecondsLeft == 0) t.cancel();
    });
  }

  Future<void> _sendOtp() async {
    if (_subdiv == null) {
      setState(() => _error = 'Select the subdivision number first.');
      return;
    }
    if (!RegExp(r'^[6-9]\d{9}$').hasMatch(_mobileCtrl.text.trim())) {
      setState(() => _error = 'Enter a valid 10-digit mobile number.');
      return;
    }
    if (_otpSecondsLeft > 0) {
      setState(() => _error = 'The portal allows a new OTP after ${_fmt(_otpSecondsLeft)}. Use the OTP already sent.');
      return;
    }
    final mobile = _mobileCtrl.text;
    // Start listening BEFORE the portal sends the SMS, so it is not missed.
    _listenForOtpSms();
    var sent = false;
    await _enqueue(() async {
      final msg = await _bridge.requestOtp(mobile);
      if (!mounted) return;
      _otpCtrl.clear();
      setState(() {
        _otpSent = true;
        _otpVerified = false;
        _otpExpiresAt = DateTime.now().add(GovPortalBridge.otpValidity);
        _info = _isAndroid ? '$msg\nWaiting for the SMS — tap "Allow" when Android asks.' : msg;
      });
      _startOtpTimer();
      _saveMobile(mobile);
      sent = true;
    }, label: 'Requesting OTP from portal…');
    if (!sent) _stopSmsListener();
  }

  // ------------------------------------------------------- OTP auto-read (Android)

  /// Android SMS User Consent API: when the next SMS containing a code arrives, Android asks
  /// the user once ("Allow") and hands the message to the app — no SMS permission needed.
  /// The code is then verified and the record fetched automatically.
  Future<void> _listenForOtpSms() async {
    if (!_isAndroid) return;
    await SmartAuth.instance.removeUserConsentApiListener();
    if (!mounted) return;
    setState(() => _listeningSms = true);
    final res = await SmartAuth.instance.getSmsWithUserConsentApi(matcher: _otpMatcher);
    if (!mounted) return;
    setState(() => _listeningSms = false);

    final code = res.data?.code;
    if (!res.isSuccess || code == null) {
      if (res.isSuccess) {
        setState(() => _info = 'Could not find the OTP in that SMS. Please type it.');
      }
      return; // canceled / denied / timed out → user types the OTP manually
    }
    if (_otpVerified || _result != null) return;
    if (_otpCtrl.text.trim() == code && _busy != null) return; // already being verified

    _otpCtrl.text = code;
    setState(() => _info = 'OTP $code read from SMS. Verifying…');

    // The SMS can arrive while the OTP request job is still finishing.
    final until = DateTime.now().add(const Duration(seconds: 30));
    while (mounted && _busy != null && DateTime.now().isBefore(until)) {
      await Future.delayed(const Duration(milliseconds: 200));
    }
    if (mounted && !_otpVerified && _result == null && _busy == null) {
      await _verifyAndFetch();
    }
  }

  void _stopSmsListener() {
    if (!_isAndroid || !_listeningSms) return;
    SmartAuth.instance.removeUserConsentApiListener();
    _listeningSms = false;
  }

  /// Android Phone Number Hint: lets the user pick this phone's SIM number in one tap.
  Future<void> _pickPhoneNumber() async {
    final res = await SmartAuth.instance.requestPhoneNumberHint();
    final number = res.data;
    if (!mounted || !res.isSuccess || number == null) return;
    final digits = number.replaceAll(RegExp(r'\D'), '');
    final ten = digits.length > 10 ? digits.substring(digits.length - 10) : digits;
    setState(() => _mobileCtrl.text = ten);
  }

  /// Verifies the OTP once, then fetches the record. If only the fetch fails, the verified
  /// session is kept so "Retry" works without a new OTP.
  Future<void> _verifyAndFetch() async {
    if (!_otpVerified) {
      if (!RegExp(r'^[0-9A-Za-z]{6}$').hasMatch(_otpCtrl.text.trim())) {
        setState(() => _error = 'Enter the 6-digit OTP sent to your mobile.');
        return;
      }
      if (_otpSecondsLeft == 0) {
        setState(() => _error = 'This OTP has expired. Tap "Get OTP" for a new one.');
        return;
      }
    }
    final otp = _otpCtrl.text;
    await _enqueue(() async {
      if (!_otpVerified) {
        setState(() => _busy = 'Verifying OTP with portal…');
        await _bridge.verifyOtp(otp);
        if (!mounted) return;
        _otpTicker?.cancel();
        _stopSmsListener();
        setState(() {
          _otpVerified = true;
          _otpExpiresAt = null;
          _info = 'OTP verified by the portal.';
        });
      }
      setState(() => _busy = 'Getting Patta / Chitta from portal… (can take up to a minute)');
      try {
        final result = await _bridge.fetchRecord();
        if (!mounted) return;
        setState(() {
          _result = result;
          _pdfBytes = null;
          _savedPdfUri = null;
          _phase = _Phase.result;
          _info = null;
        });
      } catch (e) {
        final canRetry = await _bridge.isVerifiedAndReady();
        if (mounted && !canRetry) {
          setState(() => _otpVerified = false);
          throw GovPortalException('$e\nPlease tap the refresh icon to start a new search.');
        }
        rethrow;
      }
    }, label: 'Verifying OTP with portal…');
  }

  String get _pdfFileName {
    final sub = (_subdiv?.label ?? '').replaceAll(RegExp(r'[^0-9A-Za-z-]'), '');
    final village = (_village?.label ?? '').replaceAll(RegExp(r'[^0-9A-Za-z]'), '');
    return 'Chitta_${village}_${_surveyCtrl.text.trim()}-$sub.pdf';
  }

  /// Builds the PDF on-device from the record the portal returned (same tables, same text).
  /// Cached, so Download / Print / Share don't rebuild it.
  Future<Uint8List> _buildPdf() async {
    final cached = _pdfBytes;
    if (cached != null) return cached;
    final bytes = await ChittaPdfService.build(
      result: _result!,
      title: 'Patta / Chitta',
      details: [
        MapEntry('District', _district?.label ?? ''),
        MapEntry('Taluk', _taluk?.label ?? ''),
        MapEntry('Village', _village?.label ?? ''),
        MapEntry('Land type', _landType == 'N' ? 'Natham' : 'Rural'),
        MapEntry('Survey No / Subdivision', '${_surveyCtrl.text.trim()} / ${_subdiv?.label ?? ''}'),
      ],
    );
    _pdfBytes = bytes;
    return bytes;
  }

  /// Saves the PDF straight into Downloads/TN LandMate (Android 10+) and offers to open it.
  /// Elsewhere (iOS / Android 9 and older) it opens the share sheet to save it.
  Future<void> _downloadPdf() async {
    if (_result == null) return;
    await _run('Creating PDF…', () async {
      final bytes = await _buildPdf();
      final uri = await DeviceFiles.saveToDownloads(bytes, _pdfFileName);
      if (!mounted) return;
      if (uri == null) {
        await Printing.sharePdf(bytes: bytes, filename: _pdfFileName);
        return;
      }
      setState(() => _savedPdfUri = uri);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Saved to Downloads/TN LandMate/$_pdfFileName'),
        backgroundColor: AppColors.forestGreen,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 6),
        action: SnackBarAction(label: 'OPEN', textColor: Colors.white, onPressed: _openSavedPdf),
      ));
    });
  }

  Future<void> _openSavedPdf() async {
    final uri = _savedPdfUri;
    if (uri == null) return;
    final ok = await DeviceFiles.open(uri);
    if (!ok && mounted) {
      setState(() => _error = 'No PDF viewer found. The file is in Downloads/TN LandMate.');
    }
  }

  Future<void> _sharePdf() async {
    if (_result == null) return;
    await _run('Creating PDF…', () async {
      await Printing.sharePdf(bytes: await _buildPdf(), filename: _pdfFileName);
    });
  }

  /// Opens the system print dialog.
  Future<void> _printPdf() async {
    if (_result == null) return;
    await _run('Opening print…', () async {
      final bytes = await _buildPdf();
      await Printing.layoutPdf(name: _pdfFileName, onLayout: (PdfPageFormat _) async => bytes);
    });
  }

  void _saveToProperties() {
    ref.read(propertiesProvider.notifier).addProperty({
      'id': 'gov-${DateTime.now().millisecondsSinceEpoch}',
      'nickname': '${_village?.label ?? ''} ${_surveyCtrl.text.trim()}/${_subdiv?.label ?? ''}',
      'district_name': _district?.label ?? '',
      'taluk_name': _taluk?.label ?? '',
      'village_name': _village?.label ?? '',
      'survey_number': _surveyCtrl.text.trim(),
      'subdivision_number': _subdiv?.label ?? '',
      'extent_value': 0.0,
      'extent_unit': 'cents',
      'notes': 'Chitta fetched from eservices.tn.gov.in on ${_result?.fetchedAt.toString().split('.').first}',
      'created_at': DateTime.now().toIso8601String(),
    });
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text('Saved to My Properties'),
      backgroundColor: AppColors.forestGreen,
      behavior: SnackBarBehavior.floating,
    ));
  }

  // ---------------------------------------------------------------------- UI

  @override
  Widget build(BuildContext context) {
    final ta = ref.watch(languageProvider) == 'ta';
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.forestGreen,
        foregroundColor: Colors.white,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(ta ? 'பட்டா / சிட்டா' : 'Patta / Chitta',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const Text('Live data from eservices.tn.gov.in',
                style: TextStyle(fontSize: 10, color: AppColors.mutedGoldLight)),
          ],
        ),
        actions: [
          if (_phase != _Phase.connecting)
            IconButton(
              tooltip: 'New search',
              icon: const Icon(Icons.refresh),
              onPressed: _busy == null ? () => _connect(force: true) : null,
            ),
        ],
      ),
      body: Stack(
        children: [
          Positioned.fill(child: _buildBody(ta)),
          if (_busy != null)
            Positioned(
              left: 0,
              right: 0,
              top: 0,
              child: Column(
                children: [
                  const LinearProgressIndicator(color: AppColors.mutedGold, minHeight: 3),
                  Container(
                    width: double.infinity,
                    color: AppColors.forestGreenDark,
                    padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
                    child: Text(_busy!, style: const TextStyle(color: Colors.white, fontSize: 12)),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBody(bool ta) {
    switch (_phase) {
      case _Phase.connecting:
        return _centerMessage(
          icon: Icons.account_balance,
          title: ta ? 'அரசு தளத்துடன் இணைக்கிறது…' : 'Connecting to TN e-Services…',
          subtitle: 'Loading official district list',
          loading: true,
        );
      case _Phase.failed:
        return _centerMessage(
          icon: Icons.cloud_off,
          title: 'Could not connect',
          subtitle: _error ?? '',
          action: ElevatedButton.icon(
            onPressed: () => _connect(force: true),
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
          ),
        );
      case _Phase.form:
        return _buildForm(ta);
      case _Phase.result:
        return _buildResult();
    }
  }

  Widget _buildForm(bool ta) {
    final disabled = _busy != null;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 36, 16, 32),
      children: [
        if (_error != null) _banner(_error!, error: true),
        _liveStatus(),
        if (_info != null) _banner(_info!),
        _card(
          title: ta ? 'நில விவரம்' : 'Land details',
          icon: Icons.account_balance,
          children: [
            _picker(ta ? 'மாவட்டம்' : 'District', _district, _districts, disabled ? null : _onDistrict),
            _picker(ta ? 'வட்டம்' : 'Taluk', _taluk, _taluks, disabled ? null : _onTaluk,
                loading: _loadingTaluks),
            _picker(ta ? 'கிராமம்' : 'Village', _village, _villages, disabled ? null : _onVillage,
                loading: _loadingVillages),
            const SizedBox(height: 4),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'R', label: Text('Rural')),
                ButtonSegment(value: 'N', label: Text('Natham')),
              ],
              selected: {_landType},
              onSelectionChanged: disabled ? null : (s) => _onLandType(s.first),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _surveyCtrl,
                    enabled: !disabled,
                    textCapitalization: TextCapitalization.characters,
                    maxLength: 6,
                    decoration: InputDecoration(
                      labelText: ta ? 'புல எண்' : 'Survey Number',
                      counterText: '',
                      border: const OutlineInputBorder(),
                    ),
                    onSubmitted: (_) => _loadSubdivs(),
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  height: 56,
                  child: OutlinedButton(
                    onPressed: disabled ? null : _loadSubdivs,
                    child: const Text('Load\nsubdivisions', textAlign: TextAlign.center, style: TextStyle(fontSize: 11)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _picker(ta ? 'உட்பிரிவு எண்' : 'Subdivision Number', _subdiv, _subdivs, disabled ? null : _onSubdiv),
          ],
        ),
        const SizedBox(height: 12),
        _card(
          title: ta ? 'கைப்பேசி சரிபார்ப்பு' : 'Mobile verification',
          icon: Icons.sms_outlined,
          children: [
            const Text(
              'The government portal sends an OTP to your mobile number before showing the record.',
              style: TextStyle(fontSize: 12, color: AppColors.charcoalLight),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _mobileCtrl,
                    focusNode: _mobileFocus,
                    enabled: !disabled,
                    keyboardType: TextInputType.phone,
                    maxLength: 10,
                    autofillHints: const [AutofillHints.telephoneNumberNational],
                    decoration: InputDecoration(
                      labelText: 'Mobile Number',
                      prefixText: '+91 ',
                      counterText: '',
                      border: const OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  height: 56,
                  child: ElevatedButton(
                    onPressed: disabled ? null : _sendOtp,
                    child: Text(_otpSecondsLeft > 0
                        ? 'Resend\n${_fmt(_otpSecondsLeft)}'
                        : (_otpSent ? 'Resend OTP' : 'Get OTP'),
                        textAlign: TextAlign.center),
                  ),
                ),
              ],
            ),
            if (_otpSent) ...[
              const SizedBox(height: 12),
              if (_otpVerified)
                const Row(
                  children: [
                    Icon(Icons.verified, color: AppColors.success, size: 18),
                    SizedBox(width: 6),
                    Text('OTP verified', style: TextStyle(color: AppColors.success, fontWeight: FontWeight.bold)),
                  ],
                )
              else ...[
                TextField(
                  controller: _otpCtrl,
                  enabled: !disabled,
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  // iOS: keyboard offers "From Messages: 123456"; Android autofill services too.
                  autofillHints: const [AutofillHints.oneTimeCode],
                  decoration: InputDecoration(
                    labelText: '6-digit OTP',
                    suffixIcon: _listeningSms
                        ? const Padding(
                            padding: EdgeInsets.all(14),
                            child: SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.forestGreen),
                            ),
                          )
                        : null,
                    counterText: '',
                    border: const OutlineInputBorder(),
                    helperText: _otpSecondsLeft > 0
                        ? (_listeningSms
                            ? 'Waiting for SMS (auto-read) · valid for ${_fmt(_otpSecondsLeft)}'
                            : 'OTP valid for ${_fmt(_otpSecondsLeft)}')
                        : 'OTP expired — tap "Resend OTP"',
                    helperStyle: TextStyle(color: _otpSecondsLeft > 0 ? AppColors.charcoalLight : AppColors.error),
                  ),
                ),
              ],
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.forestGreen, foregroundColor: Colors.white),
                  onPressed: disabled ? null : _verifyAndFetch,
                  icon: Icon(_otpVerified ? Icons.refresh : Icons.verified_outlined),
                  label: Text(
                    _otpVerified ? 'Retry getting Patta / Chitta' : 'Verify & Get Patta / Chitta',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildResult() {
    final r = _result!;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 36, 16, 32),
      children: [
        if (_error != null) _banner(_error!, error: true),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.forestGreen, width: 1.5),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.verified, color: AppColors.forestGreen, size: 18),
                  SizedBox(width: 6),
                  Text('Official record — eservices.tn.gov.in',
                      style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.forestGreenDark)),
                ],
              ),
              const SizedBox(height: 8),
              Text('${_district?.label} › ${_taluk?.label} › ${_village?.label}',
                  style: const TextStyle(fontSize: 13, color: AppColors.charcoal)),
              Text('Survey ${_surveyCtrl.text.trim()} / ${_subdiv?.label ?? ''}',
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.charcoal)),
              const SizedBox(height: 4),
              Text('Fetched ${r.fetchedAt.toString().split('.').first}',
                  style: const TextStyle(fontSize: 11, color: AppColors.charcoalLight)),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.forestGreen, foregroundColor: Colors.white),
                onPressed: _busy == null ? _downloadPdf : null,
                icon: const Icon(Icons.download),
                label: const Text('Download PDF'),
              ),
            ),
            const SizedBox(width: 6),
            OutlinedButton(
              onPressed: _busy == null ? _sharePdf : null,
              child: const Icon(Icons.share_outlined),
            ),
            const SizedBox(width: 6),
            OutlinedButton(
              onPressed: _busy == null ? _printPdf : null,
              child: const Icon(Icons.print_outlined),
            ),
            const SizedBox(width: 8),
            OutlinedButton(
              onPressed: _saveToProperties,
              child: const Icon(Icons.bookmark_add_outlined),
            ),
          ],
        ),
        const SizedBox(height: 12),
        for (final table in r.tables) ...[
          _buildTable(table),
          const SizedBox(height: 10),
        ],
      ],
    );
  }

  /// Two-column tables are shown as label/value rows; wider tables as a scrollable grid.
  Widget _buildTable(List<List<String>> rows) {
    final isKeyValue = rows.every((r) => r.length <= 2);
    if (isKeyValue) {
      return _card(
        children: rows.map((r) {
          if (r.length == 1) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Text(r.first, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.forestGreenDark)),
            );
          }
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 2, child: Text(r[0], style: const TextStyle(fontSize: 12, color: AppColors.charcoalLight))),
                const SizedBox(width: 8),
                Expanded(flex: 3, child: Text(r[1], style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600))),
              ],
            ),
          );
        }).toList(),
      );
    }

    final cols = rows.map((r) => r.length).reduce((a, b) => a > b ? a : b);
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.outline),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Table(
          defaultColumnWidth: const IntrinsicColumnWidth(),
          border: TableBorder.symmetric(inside: const BorderSide(color: AppColors.outline, width: 0.5)),
          children: [
            for (var i = 0; i < rows.length; i++)
              TableRow(
                decoration: BoxDecoration(color: i == 0 ? AppColors.surfaceVariant : null),
                children: [
                  for (var c = 0; c < cols; c++)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 220),
                        child: Text(
                          c < rows[i].length ? rows[i][c] : '',
                          style: TextStyle(fontSize: 12, fontWeight: i == 0 ? FontWeight.bold : FontWeight.normal),
                        ),
                      ),
                    ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  // ----------------------------------------------------------------- widgets

  /// "● Live: connecting / syncing / connected" — the hidden portal session state.
  Widget _liveStatus() {
    final String text;
    final Color color;
    if (!_connected) {
      text = 'Connecting to eservices.tn.gov.in… you can start selecting';
      color = AppColors.warning;
    } else if (_pending > 0) {
      text = 'Live: syncing with eservices.tn.gov.in…';
      color = AppColors.info;
    } else {
      text = 'Live: connected to eservices.tn.gov.in';
      color = AppColors.success;
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Icon(Icons.circle, size: 9, color: color),
          const SizedBox(width: 6),
          Expanded(child: Text(text, style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600))),
          if (!_connected || _pending > 0)
            SizedBox(width: 12, height: 12, child: CircularProgressIndicator(strokeWidth: 1.5, color: color)),
        ],
      ),
    );
  }

  Widget _picker(String label, PortalOption? value, List<PortalOption> options,
      Future<void> Function(PortalOption)? onSelected, {bool loading = false}) {
    final enabled = onSelected != null && options.isNotEmpty;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: enabled ? () => _openSearchSheet(label, options, onSelected) : null,
        child: InputDecorator(
          decoration: InputDecoration(
            labelText: label,
            border: const OutlineInputBorder(),
            enabled: enabled,
            suffixIcon: const Icon(Icons.arrow_drop_down),
          ),
          child: Text(
            value?.label ??
                (loading ? 'Loading from portal…' : (options.isEmpty ? '—' : 'Select (${options.length})')),
            style: TextStyle(color: value == null ? AppColors.charcoalLight : AppColors.charcoal),
          ),
        ),
      ),
    );
  }

  Future<void> _openSearchSheet(
      String label, List<PortalOption> options, Future<void> Function(PortalOption) onSelected) async {
    final picked = await showModalBottomSheet<PortalOption>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => _OptionSearchSheet(title: label, options: options),
    );
    if (picked != null) await onSelected(picked);
  }

  Widget _card({String? title, IconData? icon, required List<Widget> children}) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (title != null) ...[
            Row(
              children: [
                if (icon != null) Icon(icon, size: 18, color: AppColors.forestGreen),
                if (icon != null) const SizedBox(width: 6),
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              ],
            ),
            const SizedBox(height: 12),
          ],
          ...children,
        ],
      ),
    );
  }

  Widget _banner(String text, {bool error = false}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: error ? const Color(0xFFFEE2E2) : const Color(0xFFE0F2FE),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: error ? AppColors.error : AppColors.info),
      ),
      child: Row(
        children: [
          Icon(error ? Icons.error_outline : Icons.info_outline,
              size: 18, color: error ? AppColors.error : AppColors.info),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 12))),
        ],
      ),
    );
  }

  Widget _centerMessage({
    required IconData icon,
    required String title,
    required String subtitle,
    bool loading = false,
    Widget? action,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: AppColors.forestGreen),
            const SizedBox(height: 16),
            Text(title, textAlign: TextAlign.center, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(subtitle, textAlign: TextAlign.center, style: const TextStyle(fontSize: 12, color: AppColors.charcoalLight)),
            const SizedBox(height: 20),
            if (loading) const CircularProgressIndicator(color: AppColors.forestGreen),
            if (action != null) action,
          ],
        ),
      ),
    );
  }

  static String _norm(String s) => s.toLowerCase().replaceAll(RegExp(r'[^a-z0-9஀-௿]'), '');

  static PortalOption? _match(List<PortalOption> options, String? name, {bool exact = false}) {
    if (name == null || name.trim().isEmpty) return null;
    final n = _norm(name.split('(').first);
    if (n.isEmpty) return null;
    for (final o in options) {
      if (_norm(o.label) == n || _norm(o.value) == n) return o;
    }
    if (exact) return null;
    for (final o in options) {
      final l = _norm(o.label);
      if (l.contains(n) || n.contains(l)) return o;
    }
    return null;
  }
}

class _OptionSearchSheet extends StatefulWidget {
  final String title;
  final List<PortalOption> options;
  const _OptionSearchSheet({required this.title, required this.options});

  @override
  State<_OptionSearchSheet> createState() => _OptionSearchSheetState();
}

class _OptionSearchSheetState extends State<_OptionSearchSheet> {
  String _q = '';

  @override
  Widget build(BuildContext context) {
    final filtered = widget.options
        .where((o) => o.label.toLowerCase().contains(_q.toLowerCase()))
        .toList();
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: SizedBox(
          height: MediaQuery.of(context).size.height * 0.75,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: TextField(
                  autofocus: widget.options.length > 12,
                  decoration: InputDecoration(
                    hintText: 'Search ${widget.title}',
                    prefixIcon: const Icon(Icons.search),
                    border: const OutlineInputBorder(),
                  ),
                  onChanged: (v) => setState(() => _q = v),
                ),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: filtered.length,
                  itemBuilder: (_, i) => ListTile(
                    title: Text(filtered[i].label),
                    onTap: () => Navigator.pop(context, filtered[i]),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
