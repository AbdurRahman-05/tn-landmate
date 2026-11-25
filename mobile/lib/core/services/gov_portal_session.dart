import 'dart:async';

import 'gov_list_cache.dart';
import 'gov_portal_bridge.dart';

/// App-wide connection to the TN e-Services Patta/Chitta form.
///
/// The connection is opened when the app starts ([warmUp], called by `GovPortalHost`), so
/// the Patta/Chitta screen can show the form immediately. A screen takes the session with
/// [acquire] and gives it back with [release]; after release a fresh, untouched form is
/// prepared in the background for the next visit. While a screen holds the session it is
/// never reset behind its back (e.g. when the user switches to Messages to read the OTP).
class GovPortalSession {
  GovPortalSession._();
  static final GovPortalSession instance = GovPortalSession._();

  /// The portal's form session is reused for at most this long before reconnecting.
  static const Duration freshFor = Duration(minutes: 10);

  GovPortalBridge? _bridge;
  bool _bridgeFailed = false;

  Future<List<PortalOption>>? _connecting;
  List<PortalOption>? _districts;
  DateTime? _connectedAt;
  bool _clean = false; // form untouched since it was opened
  bool _inUse = false; // a screen is currently using the form

  /// The hidden browser, or null where WebView is unavailable (web, desktop, tests).
  GovPortalBridge? get bridge {
    if (_bridge == null && !_bridgeFailed) {
      try {
        _bridge = GovPortalBridge();
      } catch (_) {
        _bridgeFailed = true;
      }
    }
    return _bridge;
  }

  /// Last district list received from the portal in this app run.
  List<PortalOption>? get districts => _districts;

  bool get _isFresh =>
      _districts != null &&
      _connectedAt != null &&
      DateTime.now().difference(_connectedAt!) < freshFor;

  /// Opens (or refreshes) the portal form in the background. Safe to call any time.
  void warmUp() {
    if (_inUse || bridge == null) return;
    if (_clean && _isFresh) return;
    unawaited(_connect().then((_) {}, onError: (_) {}));
  }

  /// Takes the session for a screen. Returns the official district list as soon as the
  /// form is ready — instantly if it was prepared in the background.
  Future<List<PortalOption>> acquire({bool forceReconnect = false}) async {
    _inUse = true;
    if (!forceReconnect && _connecting != null) return _takeAfter(_connecting!);
    if (!forceReconnect && _clean && _isFresh) {
      _clean = false;
      return _districts!;
    }
    return _takeAfter(_connect());
  }

  /// Gives the session back; a fresh form is prepared in the background for next time.
  void release() {
    _inUse = false;
    _clean = false;
    Future.delayed(const Duration(seconds: 2), warmUp);
  }

  Future<List<PortalOption>> _takeAfter(Future<List<PortalOption>> f) async {
    final d = await f;
    _clean = false;
    return d;
  }

  Future<List<PortalOption>> _connect() {
    final existing = _connecting;
    if (existing != null) return existing;
    final b = bridge;
    if (b == null) {
      return Future.error(StateError('Live government connection is not supported on this device.'));
    }
    _clean = false;
    final f = b.start().then((d) async {
      _districts = d;
      _connectedAt = DateTime.now();
      _clean = true;
      await GovListCache.write(GovListCache.districtsKey(), d);
      return d;
    });
    _connecting = f;
    f.then((_) {}, onError: (_) {}).whenComplete(() {
      if (identical(_connecting, f)) _connecting = null;
    });
    return f;
  }
}
