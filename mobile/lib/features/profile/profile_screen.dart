import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/l10n/translations.dart';
import '../../core/network/api_client.dart';
import '../../core/providers.dart';
import '../../shared/widgets/custom_app_bar.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  bool _testingServer = false;
  String? _serverStatusMessage;
  bool? _serverOnline;

  Future<void> _checkServerConnection() async {
    setState(() {
      _testingServer = true;
      _serverStatusMessage = 'Pinging cloud server (Render free tier wakes up in ~45s)...';
      _serverOnline = null;
    });

    final res = await apiClient.checkHealth();
    if (!mounted) return;

    setState(() {
      _testingServer = false;
      _serverOnline = res['ok'] == true;
      _serverStatusMessage = res['message'] ?? (res['ok'] == true ? 'Connected' : 'Unavailable');
    });
  }

  void _showConfigureUrlDialog() {
    final ctrl = TextEditingController(text: ApiClient.baseUrl);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Backend Server URL', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Specify custom API base URL (must include /api/v1):',
              style: TextStyle(fontSize: 12, color: AppColors.charcoalLight),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: ctrl,
              decoration: InputDecoration(
                hintText: 'https://tn-landmate-backend.onrender.com/api/v1',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                isDense: true,
              ),
              style: const TextStyle(fontSize: 12),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () {
                ctrl.text = ApiClient.productionUrl;
              },
              child: const Text('Reset to Default Render URL', style: TextStyle(fontSize: 11)),
            ),
          ],
        ),
        actions: [
          TextButton(
            child: const Text('Cancel'),
            onPressed: () => Navigator.pop(ctx),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.forestGreen),
            child: const Text('Save & Test'),
            onPressed: () async {
              Navigator.pop(ctx);
              await apiClient.setBaseUrl(ctrl.text.trim());
              _checkServerConnection();
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(languageProvider);

    return Scaffold(
      appBar: CustomAppBar(
        title: AppTranslations.get('profile', lang),
        showLanguageSwitch: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // User Avatar Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: AppColors.forestGreen,
                      child: const Text('LM', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Citizen Guest User',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.charcoal),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.forestGreen.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text('Tamil Nadu LandMate Citizen', style: TextStyle(fontSize: 10, color: AppColors.forestGreen, fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Language Selector Card
            Card(
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.language, color: AppColors.forestGreen),
                    title: Text(AppTranslations.get('language', lang)),
                    trailing: SegmentedButton<String>(
                      segments: const [
                        ButtonSegment(value: 'ta', label: Text('தமிழ்')),
                        ButtonSegment(value: 'en', label: Text('English')),
                      ],
                      selected: {lang},
                      onSelectionChanged: (set) {
                        ref.read(languageProvider.notifier).setLanguage(set.first);
                      },
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Cloud Server Connection & Status Card
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.cloud_sync_outlined, color: AppColors.forestGreen),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            lang == 'ta' ? 'கிளவுட் சர்வர் & இணைப்பு நிலை' : 'Backend Cloud Server & Health',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                        ),
                        if (_serverOnline != null)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: _serverOnline == true ? AppColors.success.withOpacity(0.15) : AppColors.error.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  _serverOnline == true ? Icons.check_circle : Icons.error_outline,
                                  size: 12,
                                  color: _serverOnline == true ? AppColors.success : AppColors.error,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  _serverOnline == true ? 'Online' : 'Offline / Idle',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: _serverOnline == true ? AppColors.success : AppColors.error,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Target Base URL:', style: TextStyle(fontSize: 10, color: AppColors.charcoalLight)),
                                const SizedBox(height: 2),
                                SelectableText(
                                  ApiClient.baseUrl,
                                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.charcoal),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.edit_outlined, size: 18, color: AppColors.forestGreen),
                            tooltip: 'Configure URL',
                            onPressed: _showConfigureUrlDialog,
                          ),
                        ],
                      ),
                    ),
                    if (_serverStatusMessage != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        _serverStatusMessage!,
                        style: TextStyle(
                          fontSize: 11,
                          color: _serverOnline == true ? AppColors.success : AppColors.charcoalLight,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                    const SizedBox(height: 8),
                    // Notice on Render free tier
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.info_outline, size: 14, color: Colors.blue.shade800),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              lang == 'ta'
                                  ? 'Render இலவச கிளவுட் தளம் 15 நிமிட செயலற்ற நிலைக்குப் பிறகு உறங்குகிறது (Cold-Start). முதல் கோரிக்கைக்கு விழித்துக் கொள்ள ~45-50 வினாடிகள் ஆகும்.'
                                  : 'Render Free Tier sleeps after 15 min of inactivity. First request takes ~45s to wake up container. The app automatically retries.',
                              style: TextStyle(fontSize: 10, color: Colors.blue.shade900, height: 1.3),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: AppColors.forestGreen),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        icon: _testingServer
                            ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2))
                            : const Icon(Icons.power_settings_new, size: 16, color: AppColors.forestGreen),
                        label: Text(
                          _testingServer ? 'Waking Up Server...' : 'Test / Wake Up Server Now',
                          style: const TextStyle(fontSize: 12, color: AppColors.forestGreen, fontWeight: FontWeight.bold),
                        ),
                        onPressed: _testingServer ? null : _checkServerConnection,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Disclaimers & Governance
            Card(
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.verified_user_outlined, color: AppColors.forestGreen),
                    title: const Text('Legal Terms & Privacy Guardrail'),
                    subtitle: const Text('Local storage first. No private data shared without consent.', style: TextStyle(fontSize: 11)),
                    onTap: () {
                      _showTermsDialog(context);
                    },
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.info_outline, color: AppColors.forestGreen),
                    title: const Text('About TN LandMate'),
                    subtitle: const Text('v1.0.0 (Production-oriented Tamil Nadu utility)', style: TextStyle(fontSize: 11)),
                    onTap: () {
                      showAboutDialog(
                        context: context,
                        applicationName: 'TN LandMate',
                        applicationVersion: '1.0.0',
                        applicationLegalese: 'Crafted for citizens and property professionals in Tamil Nadu.',
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showTermsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Legal Disclaimer'),
        content: const SingleChildScrollView(
          child: Text(
            'TN LandMate is an informational utility for Tamil Nadu land calculations and document guidance. '
            'Calculations, plot geometry, and demo records do not constitute certified title opinions, gazetted tax quotas, or legal boundary endorsements. '
            'Always verify with official revenue and registration authorities (eservices.tn.gov.in and tnreginet.gov.in).',
            style: TextStyle(fontSize: 12, height: 1.4),
          ),
        ),
        actions: [
          ElevatedButton(
            child: const Text('Understood'),
            onPressed: () => Navigator.pop(context),
          )
        ],
      ),
    );
  }
}
