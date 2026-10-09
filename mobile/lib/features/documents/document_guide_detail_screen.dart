import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/providers.dart';
import '../../shared/widgets/custom_app_bar.dart';
import '../../shared/widgets/disclaimer_banner.dart';
import '../../shared/widgets/official_source_card.dart';

class DocumentGuideDetailScreen extends ConsumerWidget {
  final Map<String, dynamic> guide;

  const DocumentGuideDetailScreen({Key? key, required this.guide}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lang = ref.watch(languageProvider);
    final isTa = lang == 'ta';

    final title = isTa ? guide['title_ta'] : guide['title_en'];
    final what = isTa ? guide['what_ta'] : guide['what_en'];
    final why = isTa ? guide['why_ta'] : guide['why_en'];
    final checklist = (isTa ? guide['checklist_ta'] : guide['checklist_en']) as List;
    final color = guide['color'] as Color;

    return Scaffold(
      appBar: CustomAppBar(title: title),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DisclaimerBanner(
              text: isTa
                  ? 'இக்கையேடு தகவல் விழிப்புணர்வுக்கானது. சட்டப்பூர்வ வழிகாட்டுதலுக்கு வழக்கறிஞரை அணுகவும்.'
                  : 'This educational guide is for informational awareness. Consult a property lawyer for legal execution.',
            ),
            const SizedBox(height: 16),

            // What It Is Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info_outline, color: color, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          isTa ? 'ஆவணம் பற்றிய விளக்கம்' : 'What is this document?',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.charcoal),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(what, style: const TextStyle(fontSize: 13, height: 1.5, color: AppColors.charcoalLight)),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 12),

            // Why It Matters Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: const [
                        Icon(Icons.shield_outlined, color: AppColors.forestGreen, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'Why It Matters (முக்கியத்துவம்)',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.charcoal),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(why, style: const TextStyle(fontSize: 13, height: 1.5, color: AppColors.charcoalLight)),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 12),

            // Verification Checklist Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: const [
                        Icon(Icons.checklist, color: AppColors.mutedGold, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'Citizen Verification Checklist',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.charcoal),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ...checklist.map((item) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.check_box_outlined, size: 18, color: AppColors.forestGreen),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                item.toString(),
                                style: const TextStyle(fontSize: 12, color: AppColors.charcoal, height: 1.3),
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            OfficialSourceCard(
              title: 'Official Verification Portal',
              description: 'Access Government of Tamil Nadu Land Records portal directly.',
              url: guide['url'],
            ),
          ],
        ),
      ),
    );
  }
}
