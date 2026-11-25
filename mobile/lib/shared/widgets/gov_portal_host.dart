import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../core/services/gov_portal_session.dart';

/// Hosts the hidden government-portal browser for the whole app and opens the
/// Patta/Chitta form as soon as the app starts. Wrap the app with it via
/// `MaterialApp.builder`.
class GovPortalHost extends StatefulWidget {
  final Widget child;
  const GovPortalHost({super.key, required this.child});

  @override
  State<GovPortalHost> createState() => _GovPortalHostState();
}

class _GovPortalHostState extends State<GovPortalHost> with WidgetsBindingObserver {
  final GovPortalSession _session = GovPortalSession.instance;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Start after the first frame so the hidden WebView is attached.
    WidgetsBinding.instance.addPostFrameCallback((_) => _session.warmUp());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Refresh an expired form when the user comes back to the app (no-op while in use).
    if (state == AppLifecycleState.resumed) _session.warmUp();
  }

  @override
  Widget build(BuildContext context) {
    final bridge = _session.bridge;
    if (bridge == null) return widget.child;
    return Stack(
      textDirection: TextDirection.ltr,
      children: [
        Positioned.fill(child: widget.child),
        // Invisible 1×1 browser that talks to eservices.tn.gov.in.
        Positioned(
          left: 0,
          top: 0,
          width: 1,
          height: 1,
          child: IgnorePointer(
            child: Opacity(opacity: 0.01, child: WebViewWidget(controller: bridge.controller)),
          ),
        ),
      ],
    );
  }
}
