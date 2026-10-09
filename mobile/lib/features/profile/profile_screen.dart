import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/l10n/translations.dart';
import '../../core/providers.dart';
import '../../shared/widgets/custom_app_bar.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
                            child: const Text('Offline Local Mode Active', style: TextStyle(fontSize: 10, color: AppColors.forestGreen, fontWeight: FontWeight.bold)),
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
