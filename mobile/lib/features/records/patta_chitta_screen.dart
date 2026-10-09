import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/l10n/translations.dart';
import '../../core/providers.dart';
import '../../shared/widgets/custom_app_bar.dart';
import '../../shared/widgets/disclaimer_banner.dart';
import '../../shared/widgets/official_source_card.dart';
import '../../shared/widgets/live_gov_extractor_sheet.dart';
import '../live_portal/live_government_portal_screen.dart';

class PattaChittaScreen extends ConsumerWidget {
  const PattaChittaScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lang = ref.watch(languageProvider);

    return Scaffold(
      appBar: CustomAppBar(
        title: AppTranslations.get('patta_chitta', lang),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DisclaimerBanner(
              text: lang == 'ta'
                  ? 'பட்டா & சிட்டா விவரங்கள் தமிழ்நாடு வருவாய்த் துறையால் பராமரிக்கப்படுகின்றன. அதிகாரப்பூர்வ நகலை அரசு இ-சேவை மூலம் சரிபார்க்கவும்.'
                  : 'Patta & Chitta are maintained by the Revenue Administration. Official digital copies must be retrieved from TN Revenue e-Services.',
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.forestGreen.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.description, color: AppColors.forestGreen),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            lang == 'ta' ? 'பட்டா / சிட்டா என்றால் என்ன?' : 'What is Patta & Chitta?',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      lang == 'ta'
                          ? 'பட்டா என்பது வட்டாட்சியரால் ஒரு குறிப்பிட்ட நில உரிமைக்காக வழங்கப்படும் முதன்மை ஆவணமாகும். சிட்டா என்பது நிலத்தின் வகைப்பாடு (நன்செய்/புன்செய்) மற்றும் அதற்கான நிலவரி மதிப்பீட்டைக் குறிக்கும்.'
                          : 'A Patta is a legal revenue record issued by the Tahsildar establishing that a particular parcel of land is registered under the holder\'s name. Chitta specifies the classification (Nanjai/Punjai) and tax assessment.',
                      style: const TextStyle(fontSize: 13, height: 1.5, color: AppColors.charcoalLight),
                    ),
                    const Divider(height: 24),
                    Text(
                      lang == 'ta' ? 'அவசியமான புல விவரங்கள்:' : 'Key Fields in Patta:',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.charcoal),
                    ),
                    const SizedBox(height: 8),
                    _buildCheckItem(lang == 'ta' ? 'பட்டா எண் (Patta Number)' : 'Patta Number'),
                    _buildCheckItem(lang == 'ta' ? 'உரிமையாளர் பெயர் (Owner Name)' : 'Registered Owner Name'),
                    _buildCheckItem(lang == 'ta' ? 'புல எண் & உட்பிரிவு (Survey & Sub-division)' : 'Survey & Sub-division No'),
                    _buildCheckItem(lang == 'ta' ? 'பரப்பளவு (ஹெக்டேர் / ஏர்ஸ்)' : 'Extent in Hectares & Cents'),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.forestGreen,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        icon: const Icon(Icons.bolt, color: AppColors.mutedGold),
                        label: Text(
                          lang == 'ta' ? 'அரசு தளத்திலிருந்து நேரடி விவரம் பெறுக' : 'Extract Live Patta/Chitta (Native UI)',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        onPressed: () {
                          LiveGovExtractorSheet.show(
                            context: context,
                            recordType: 'patta_chitta',
                            title: lang == 'ta' ? 'நேரடி பட்டா / சிட்டா விவரம்' : 'Live Patta / Chitta Extraction',
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            OfficialSourceCard(
              title: 'View Online Patta / Chitta (e-Services)',
              description: 'Extract real-time government records directly into the mobile app UI.',
              url: 'https://eservices.tn.gov.in/eservicesnew/land/chitta.html',
              onTap: () {
                LiveGovExtractorSheet.show(
                  context: context,
                  recordType: 'patta_chitta',
                  title: lang == 'ta' ? 'நேரடி பட்டா / சிட்டா விவரம்' : 'Live Patta / Chitta Extraction',
                );
              },
            ),
          ],
        ),
      ),
    );

  }

  Widget _buildCheckItem(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          const Icon(Icons.check_circle_outline, size: 16, color: AppColors.forestGreen),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 12, color: AppColors.charcoal))),
        ],
      ),
    );
  }
}
