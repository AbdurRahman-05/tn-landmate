import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../../core/constants/app_colors.dart';
import '../../core/providers.dart';

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

  @override
  void initState() {
    super.initState();
    _initWebView();
  }

  void _initWebView() {
    // Check if platform supports webview_flutter (Android / iOS)
    if (!kIsWeb && (defaultTargetPlatform == TargetPlatform.android || defaultTargetPlatform == TargetPlatform.iOS)) {
      try {
        final controller = WebViewController()
          ..setJavaScriptMode(JavaScriptMode.unrestricted)
          ..setBackgroundColor(Colors.white)
          ..setNavigationDelegate(
            NavigationDelegate(
              onProgress: (int progress) {
                if (mounted) setState(() => _progress = progress);
              },
              onPageStarted: (String url) {
                if (mounted) setState(() => _isLoading = true);
              },
              onPageFinished: (String url) {
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
          ..loadRequest(Uri.parse(widget.initialUrl));
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
    final uri = Uri.parse(widget.initialUrl);
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
                          ? 'வழிமுறை: 1) மாவட்டத்தை தேர்வு செய்க 2) சர்வே எண் உள்ளிடவும் 3) அரசு திரையில் உள்ள 4-எழுத்து கேப்ட்சா (CAPTCHA) தட்டச்சு செய்து சமர்ப்பிக்கவும்.'
                          : 'Steps: 1) Select Taluk/Village 2) Paste Survey No 3) Solve government CAPTCHA and tap Submit to view live signed record.',
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
