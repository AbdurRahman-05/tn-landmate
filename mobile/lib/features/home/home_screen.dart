import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/l10n/translations.dart';
import '../../core/providers.dart';
import '../../shared/widgets/custom_app_bar.dart';
import '../../shared/widgets/official_source_card.dart';
import '../calculators/area_converter_screen.dart';
import '../calculators/plot_area_screen.dart';
import '../calculators/registration_calculator_screen.dart';
import '../land_search/land_search_screen.dart';
import '../records/patta_chitta_screen.dart';
import '../records/patta_generator_screen.dart';
import '../records/a_register_screen.dart';
import '../records/fmb_screen.dart';
import '../guideline/guideline_value_screen.dart';
import '../documents/document_guide_list_screen.dart';
import '../ai_assistant/ai_assistant_screen.dart';
import '../properties/saved_properties_screen.dart';
import '../live_portal/live_government_portal_screen.dart';
import '../../shared/widgets/live_gov_extractor_sheet.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lang = ref.watch(languageProvider);
    final savedProps = ref.watch(propertiesProvider);

    return Scaffold(
      appBar: CustomAppBar(
        title: AppTranslations.get('app_title', lang),
        actions: [
          IconButton(
            icon: const Icon(Icons.bookmark_outline),
            tooltip: 'Saved Properties',
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const SavedPropertiesScreen()));
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Hero Banner
            Container(
              width: double.infinity,
              color: AppColors.forestGreen,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.mutedGold.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: AppColors.mutedGold.withOpacity(0.4)),
                          ),
                          child: const Icon(Icons.terrain, color: AppColors.mutedGold, size: 24),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                AppTranslations.get('app_title', lang),
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              Text(
                                AppTranslations.get('tagline', lang),
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFFD1E7DD),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Quick Search Bar Shortcut
                    GestureDetector(
                      onTap: () {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const LandSearchScreen()));
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.08),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.search, color: AppColors.forestGreen, size: 20),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                lang == 'ta'
                                    ? 'புல எண் / நில ஆவணம் தேடவும்...'
                                    : 'Search Survey No, Village, or Land Record...',
                                style: const TextStyle(color: AppColors.charcoalLight, fontSize: 13),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.forestGreen.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                lang == 'ta' ? 'தேடல்' : 'Search',
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.forestGreen,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Feature Quick Action Grid
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppTranslations.get('quick_actions', lang),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.charcoal,
                    ),
                  ),
                  const SizedBox(height: 12),
                  GridView.count(
                    crossAxisCount: 3,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                    childAspectRatio: 0.95,
                    children: [
                      _buildActionCard(
                        context,
                        icon: Icons.calculate_outlined,
                        title: AppTranslations.get('area_converter', lang),
                        color: const Color(0xFF1B4D3E),
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AreaConverterScreen())),
                      ),
                      _buildActionCard(
                        context,
                        icon: Icons.crop_square_outlined,
                        title: AppTranslations.get('plot_calculator', lang),
                        color: const Color(0xFF2B7A5A),
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PlotAreaScreen())),
                      ),
                      _buildActionCard(
                        context,
                        icon: Icons.receipt_long_outlined,
                        title: AppTranslations.get('stamp_reg_calc', lang),
                        color: const Color(0xFFC85A32),
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RegistrationCalculatorScreen())),
                      ),
                      _buildActionCard(
                        context,
                        icon: Icons.description_outlined,
                        title: AppTranslations.get('patta_chitta', lang),
                        color: const Color(0xFF1E5A42),
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PattaChittaScreen())),
                      ),
                      _buildActionCard(
                        context,
                        icon: Icons.picture_as_pdf_outlined,
                        title: lang == 'ta' ? 'பட்டா பதிவிறக்கம்' : 'Download Patta PDF',
                        color: const Color(0xFF0D9488),
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PattaGeneratorScreen())),
                      ),
                      _buildActionCard(
                        context,
                        icon: Icons.menu_book_outlined,
                        title: AppTranslations.get('a_register', lang),
                        color: const Color(0xFF3B82F6),
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ARegisterScreen())),
                      ),
                      _buildActionCard(
                        context,
                        icon: Icons.map_outlined,
                        title: AppTranslations.get('fmb_sketch', lang),
                        color: const Color(0xFF8B5CF6),
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const FmbScreen())),
                      ),
                      _buildActionCard(
                        context,
                        icon: Icons.sell_outlined,
                        title: AppTranslations.get('guideline_value', lang),
                        color: const Color(0xFFD97706),
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const GuidelineValueScreen())),
                      ),
                      _buildActionCard(
                        context,
                        icon: Icons.auto_stories_outlined,
                        title: AppTranslations.get('doc_guides', lang),
                        color: const Color(0xFF0D9488),
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const DocumentGuideListScreen())),
                      ),
                      _buildActionCard(
                        context,
                        icon: Icons.smart_toy_outlined,
                        title: AppTranslations.get('ai_assistant', lang),
                        color: const Color(0xFF4F46E5),
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AIAssistantScreen())),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Saved Properties Mini Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        AppTranslations.get('saved_properties', lang),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.charcoal,
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.push(context, MaterialPageRoute(builder: (_) => const SavedPropertiesScreen()));
                        },
                        child: Text(
                          lang == 'ta' ? 'அனைத்தும் பார்க்க' : 'View All',
                          style: const TextStyle(color: AppColors.forestGreen, fontWeight: FontWeight.bold, fontSize: 12),
                        ),
                      )
                    ],
                  ),
                  if (savedProps.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.outline),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.bookmark_border, color: AppColors.charcoalLight),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              AppTranslations.get('no_properties', lang),
                              style: const TextStyle(fontSize: 12, color: AppColors.charcoalLight),
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    ...savedProps.take(2).map((prop) {
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                          leading: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.forestGreen.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.location_on, color: AppColors.forestGreen),
                          ),
                          title: Text(
                            prop['nickname'] ?? '',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                          subtitle: Text(
                            '${prop['district_name']} • Survey: ${prop['survey_number']}/${prop['subdivision_number']} • ${prop['extent_value']} ${prop['extent_unit']}',
                            style: const TextStyle(fontSize: 12, color: AppColors.charcoalLight),
                          ),
                          trailing: const Icon(Icons.chevron_right, size: 20),
                          onTap: () {
                            Navigator.push(context, MaterialPageRoute(builder: (_) => const SavedPropertiesScreen()));
                          },
                        ),
                      );
                    }).toList(),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Official Tamil Nadu Government Services
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    lang == 'ta' ? 'அங்கீகரிக்கப்பட்ட அரசு இணையதளங்கள்' : 'Authorized Government Portals',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.charcoal,
                    ),
                  ),
                  const SizedBox(height: 10),
                  OfficialSourceCard(
                    title: 'TN Revenue e-Services (Live Native Extraction)',
                    description: 'Extract Patta, Chitta, A-Register & FMB records directly into the app UI.',
                    url: 'https://eservices.tn.gov.in',
                    onTap: () {
                      LiveGovExtractorSheet.show(
                        context: context,
                        recordType: 'patta_chitta',
                        title: 'TN Revenue Live Extraction',
                      );
                    },
                  ),
                  const SizedBox(height: 10),
                  OfficialSourceCard(
                    title: 'TNREGINET (Registration Department Live)',
                    description: 'Extract official Guideline Values & SRO data directly into the app UI.',
                    url: 'https://tnreginet.gov.in',
                    onTap: () {
                      LiveGovExtractorSheet.show(
                        context: context,
                        recordType: 'guideline_value',
                        title: 'TNREGINET Guideline Live Extraction',
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

  Widget _buildActionCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.outline),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.charcoal,
                height: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
