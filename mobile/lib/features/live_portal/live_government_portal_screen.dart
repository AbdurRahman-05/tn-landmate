import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:printing/printing.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../../core/constants/app_colors.dart';
import '../../core/providers.dart';

/// Official entry points. The TN e-Services portal rejects direct deep links into
/// `land/...` pages ("INVALID ACCESS TO THE SITE") because every form page needs a
/// per-session `rno` token that is only issued from the index page.
class OfficialPortalUrls {
  static const String eservicesIndex = 'https://eservices.tn.gov.in/eservicesnew/index.html';
  static const String tnreginet = 'https://tnreginet.gov.in/portal/';

  static String forRecordType(String recordType) {
    return recordType == 'guideline_value' ? tnreginet : eservicesIndex;
  }

  /// Rewrites stale deep links (e.g. land/chitta.html) to the portal's entry page.
  static String normalize(String url) {
    if (url.contains('eservices.tn.gov.in') && url.contains('/land/')) {
      return eservicesIndex;
    }
    return url;
  }
}

class LiveGovernmentPortalScreen extends ConsumerStatefulWidget {
  final String title;
  final String initialUrl;
  final String? districtName;
  final String? talukName;
  final String? villageName;
  final String? surveyNumber;
  final String? subdivisionNumber;

  const LiveGovernmentPortalScreen({
    Key? key,
    required this.title,
    required this.initialUrl,
    this.districtName,
    this.talukName,
    this.villageName,
    this.surveyNumber,
    this.subdivisionNumber,
  }) : super(key: key);

  @override
  ConsumerState<LiveGovernmentPortalScreen> createState() => _LiveGovernmentPortalScreenState();
}

class _LiveGovernmentPortalScreenState extends ConsumerState<LiveGovernmentPortalScreen> {
  WebViewController? _webViewController;
  bool _isLoading = true;
  int _progress = 0;
  bool _supportsWebView = true;
  bool _showAssistant = true;
  bool _savingPdf = false;

  late final String _startUrl = OfficialPortalUrls.normalize(widget.initialUrl);

  // Android WebView ignores window.print(); route the portal's own Print button to our PDF export.
  static const String _printHookJs =
      "window.print = function(){ try { LandMatePrint.postMessage('print'); } catch(e) {} };";

  @override
  void initState() {
    super.initState();
    _initWebView();
  }

  /// Saves exactly what the official portal is currently showing (e.g. the Patta/Chitta
  /// result page) as a PDF, using the portal's own HTML and styles — no re-rendering.
  Future<void> _saveCurrentPageAsPdf() async {
    final controller = _webViewController;
    if (controller == null || _savingPdf) return;
    setState(() => _savingPdf = true);
    try {
      final raw = await controller.runJavaScriptReturningResult('document.documentElement.outerHTML');
      String html = raw is String ? raw : raw.toString();
      // Android returns the string JSON-encoded ("<html>..."); iOS returns it raw.
      if (html.startsWith('"')) {
        html = jsonDecode(html) as String;
      }
      final baseUrl = await controller.currentUrl();
      final stamp = DateTime.now().toIso8601String().split('.').first.replaceAll(':', '-');
      final survey = (widget.surveyNumber ?? '').isNotEmpty
          ? '_${widget.surveyNumber}${(widget.subdivisionNumber ?? '').isNotEmpty ? '-${widget.subdivisionNumber}' : ''}'
          : '';

      await Printing.layoutPdf(
        name: 'TN_eServices${survey}_$stamp',
        // webview_flutter has no native print API; convertHtml is deprecated but still
        // supported on Android/iOS and renders the portal's HTML with its own CSS.
        // ignore: deprecated_member_use
        onLayout: (format) => Printing.convertHtml(format: format, html: html, baseUrl: baseUrl),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not save this page as PDF: $e'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _savingPdf = false);
    }
  }

  void _initWebView() {
    // Check if platform supports webview_flutter (Android / iOS)
    if (!kIsWeb && (defaultTargetPlatform == TargetPlatform.android || defaultTargetPlatform == TargetPlatform.iOS)) {
      try {
        final controller = WebViewController()
          ..setJavaScriptMode(JavaScriptMode.unrestricted)
          ..setBackgroundColor(Colors.white)
          ..addJavaScriptChannel(
            'LandMatePrint',
            onMessageReceived: (_) => _saveCurrentPageAsPdf(),
          )
          ..setNavigationDelegate(
            NavigationDelegate(
              onProgress: (int progress) {
                if (mounted) setState(() => _progress = progress);
              },
              onPageStarted: (String url) {
                if (mounted) setState(() => _isLoading = true);
              },
              onPageFinished: (String url) {
                _webViewController?.runJavaScript(_printHookJs);
                if (mounted) {
                  setState(() {
                    _isLoading = false;
                    _progress = 100;
                  });
                }
              },
              onWebResourceError: (WebResourceError error) {
                if (mounted) setState(() => _isLoading = false);
              },
            ),
          )
          ..loadRequest(Uri.parse(_startUrl));
        _webViewController = controller;
      } catch (e) {
        _supportsWebView = false;
      }
    } else {
      _supportsWebView = false;
      _isLoading = false;
    }
  }

  void _openExternalBrowser() async {
    final uri = Uri.parse(_startUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  void _copyToClipboard(String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$label ($text) copied to clipboard!'),
        duration: const Duration(seconds: 1),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _importToSavedPortfolio() {
    final dist = widget.districtName ?? 'Tamil Nadu';
    final survey = widget.surveyNumber ?? 'Live';
    final sub = widget.subdivisionNumber ?? '';

    final prop = {
      'id': 'live-${DateTime.now().millisecondsSinceEpoch}',
      'nickname': 'Official $dist $survey${sub.isNotEmpty ? "/$sub" : ""}',
      'district_name': dist,
      'taluk_name': widget.talukName ?? '',
      'village_name': widget.villageName ?? '',
      'survey_number': survey,
      'subdivision_number': sub,
      'extent_value': 0.0,
      'extent_unit': 'cents',
      'notes': 'Verified real-time on official portal (${widget.title}) on ${DateTime.now().toString().split('.')[0]}',
      'created_at': DateTime.now().toIso8601String(),
    };

    ref.read(propertiesProvider.notifier).addProperty(prop);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Record successfully imported into your LandMate Portfolio!'),
        backgroundColor: AppColors.forestGreen,
        duration: Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(languageProvider);
    final hasDetails = widget.surveyNumber != null && widget.surveyNumber!.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.forestGreen,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white)),
            const Text(
              'Live Official Government Portal (tn.gov.in)',
              style: TextStyle(fontSize: 10, color: AppColors.mutedGoldLight),
            ),
          ],
        ),
        actions: [
          if (_supportsWebView)
            IconButton(
              icon: _savingPdf
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.picture_as_pdf),
              tooltip: 'Save this page as PDF',
              onPressed: _savingPdf ? null : _saveCurrentPageAsPdf,
            ),
          IconButton(
            icon: const Icon(Icons.bookmark_add, color: AppColors.mutedGold),
            tooltip: 'Import into My Properties',
            onPressed: _importToSavedPortfolio,
          ),
          IconButton(
            icon: const Icon(Icons.open_in_browser),
            tooltip: 'Open in Browser',
            onPressed: _openExternalBrowser,
          ),
          IconButton(
            icon: Icon(_showAssistant ? Icons.visibility_off_outlined : Icons.help_outline),
            tooltip: 'Toggle Assistant',
            onPressed: () {
              setState(() => _showAssistant = !_showAssistant);
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          // Main Body: WebView or Desktop Gateway Fallback
          Positioned.fill(
            child: _supportsWebView && _webViewController != null
                ? WebViewWidget(controller: _webViewController!)
                : _buildDesktopGatewayView(),
          ),

          // Loading Progress Bar
          if (_isLoading && _supportsWebView)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: LinearProgressIndicator(
                value: _progress / 100.0,
                backgroundColor: Colors.transparent,
                valueColor: const AlwaysStoppedAnimation<Color>(AppColors.mutedGold),
              ),
            ),

          // Floating Smart Assistant Drawer (Helps user fill CAPTCHA & Form)
          if (_showAssistant)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.12),
                      blurRadius: 12,
                      offset: const Offset(0, -3),
                    )
                  ],
                  border: Border.all(color: AppColors.outline),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: const [
                            Icon(Icons.assistant, size: 18, color: AppColors.forestGreen),
                            SizedBox(width: 6),
                            Text(
                              'Live Search Assistant (நேரடி உதவி)',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.forestGreenDark),
                            ),
                          ],
                        ),
                        InkWell(
                          onTap: () => setState(() => _showAssistant = false),
                          child: const Icon(Icons.close, size: 18, color: AppColors.charcoalLight),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (hasDetails) ...[
                      // Quick Survey Info Copy Bar
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceVariant,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                '${widget.districtName ?? ""} • ${widget.talukName ?? ""} • Survey: ${widget.surveyNumber}/${widget.subdivisionNumber ?? ""}',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.charcoal),
                              ),
                            ),
                            InkWell(
                              onTap: () => _copyToClipboard(widget.surveyNumber!, 'Survey Number'),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppColors.forestGreen,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Text(
                                  'Copy Survey No',
                                  style: TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 6),
                    ],
                    Text(
                      lang == 'ta'
                          ? 'வழிமுறை: 1) "பட்டா / சிட்டா" இணைப்பைத் தட்டவும் 2) மாவட்டம், வட்டம், கிராமம், சர்வே எண் தேர்வு செய்க 3) கைப்பேசி எண் உள்ளிட்டு OTP பெற்று சமர்ப்பிக்கவும் 4) மேலே உள்ள PDF பொத்தானை அழுத்தி ஆவணத்தைச் சேமிக்கவும்.'
                          : 'Steps: 1) Tap "View Patta & FMB / Chitta" 2) Select District, Taluk, Village, Survey No 3) Enter your mobile no, get OTP and Submit 4) Tap the PDF icon above to save the official document.',
                      style: const TextStyle(fontSize: 11, color: AppColors.charcoalLight, height: 1.3),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDesktopGatewayView() {
    return Container(
      color: AppColors.background,
      padding: const EdgeInsets.all(24),
      alignment: Alignment.center,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.forestGreen.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.account_balance, color: AppColors.forestGreen, size: 40),
              ),
              const SizedBox(height: 16),
              Text(
                widget.title,
                textAlign: TextAlign.center,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppColors.charcoal),
              ),
              const SizedBox(height: 8),
              const Text(
                'Direct Connection to Government of Tamil Nadu Revenue & Registration Server',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: AppColors.charcoalLight),
              ),
              const Divider(height: 32),
              if (widget.surveyNumber != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    children: [
                      Text('Target Property: ${widget.districtName} • ${widget.talukName}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text('Survey Number: ${widget.surveyNumber} / ${widget.subdivisionNumber ?? ""}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.forestGreenDark)),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.open_in_browser),
                  label: const Text('Open Official Portal in Browser'),
                  onPressed: _openExternalBrowser,
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.bookmark_add_outlined),
                  label: const Text('Save Reference to Portfolio'),
                  onPressed: _importToSavedPortfolio,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
