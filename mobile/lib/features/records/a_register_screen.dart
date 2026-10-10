import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/l10n/translations.dart';
import '../../core/providers.dart';
import '../../shared/widgets/custom_app_bar.dart';
import '../../shared/widgets/disclaimer_banner.dart';
import '../../shared/widgets/official_source_card.dart';
import '../../shared/widgets/live_gov_extractor_sheet.dart';
import '../documents/pdf_document_center_screen.dart';

class ARegisterScreen extends ConsumerWidget {
  const ARegisterScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lang = ref.watch(languageProvider);

    return Scaffold(
      appBar: CustomAppBar(
        title: AppTranslations.get('a_register', lang),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DisclaimerBanner(
              text: lang == 'ta'
                  ? 'அ-பதிவேடு என்பது கிராம நிலங்களின் முதன்மை நிரந்தரப் பதிவேடு. அரசு புறம்போக்கு அல்லது நீர்நிலையா என அறிய இது மிக முக்கியமானது.'
                  : 'A-Register is the master permanent land register. It is essential to ensure land is not classified as Government Poramboke or water course.',
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
                            color: const Color(0xFF3B82F6).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.menu_book, color: Color(0xFF3B82F6)),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            lang == 'ta' ? 'அ-பதிவேட்டின் முக்கியத்துவம்' : 'Why A-Register Matters',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      lang == 'ta'
                          ? 'கிராம நிர்வாக அலுவலரால் (VAO) பராமரிக்கப்படும் இப்பட்டியலில் நிலத்தின் வகைப்பாடு (நன்செய்/புன்செய்), பழைய புல எண், தற்போதைய புல எண், ராயத்துவாரி வகை மற்றும் வரி மதிப்பீடு இருக்கும். சொத்து வாங்குமுன் புறம்போக்கு நிலம் இல்லை என்பதை உறுதிசெய்ய வேண்டும்.'
                          : 'Maintained by the Village Administrative Officer (VAO), the A-Register lists tenure (Ryotwari/Inam), classification (dry/wet/poramboke), soil rate, and water sources. Essential due diligence before buying any plot in Tamil Nadu.',
                      style: const TextStyle(fontSize: 13, height: 1.5, color: AppColors.charcoalLight),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2563EB),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        icon: const Icon(Icons.bolt, color: AppColors.mutedGold),
                        label: Text(
                          lang == 'ta' ? 'அரசு அ-பதிவேடு விவரம் பெறுக (Live)' : 'Extract Live A-Register (Native UI)',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        onPressed: () {
                          LiveGovExtractorSheet.show(
                            context: context,
                            recordType: 'a_register',
                            title: lang == 'ta' ? 'அ-பதிவேடு நேரடி விவரம்' : 'Live A-Register Extraction',
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Color(0xFF2563EB), width: 1.5),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        icon: const Icon(Icons.picture_as_pdf, color: Color(0xFF2563EB)),
                        label: Text(
                          lang == 'ta' ? 'அ-பதிவேடு நகல் பதிவிறக்கம் (PDF)' : 'Generate & Download A-Register (PDF)',
                          style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF2563EB)),
                        ),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const PdfDocumentCenterScreen(initialDocType: 'a_register'),
                            ),
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
              title: 'Verify A-Register on e-Services',
              description: 'Extract master permanent revenue register directly into the mobile app UI.',
              url: 'https://eservices.tn.gov.in/eservicesnew/land/areg.html',
              onTap: () {
                LiveGovExtractorSheet.show(
                  context: context,
                  recordType: 'a_register',
                  title: lang == 'ta' ? 'அ-பதிவேடு நேரடி விவரம்' : 'Live A-Register Extraction',
                );
              },
            ),
          ],
        ),
      ),
    );

  }
}
