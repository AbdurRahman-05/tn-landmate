import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/l10n/translations.dart';
import '../../core/providers.dart';
import '../../shared/widgets/custom_app_bar.dart';
import '../../shared/widgets/disclaimer_banner.dart';
import 'add_edit_property_screen.dart';
import '../../core/services/patta_pdf_service.dart';

class SavedPropertiesScreen extends ConsumerWidget {
  const SavedPropertiesScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lang = ref.watch(languageProvider);
    final properties = ref.watch(propertiesProvider);

    return Scaffold(
      appBar: CustomAppBar(
        title: AppTranslations.get('saved_properties', lang),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.forestGreen,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
        onPressed: () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const AddEditPropertyScreen()));
        },
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DisclaimerBanner(
              text: lang == 'ta'
                  ? 'சேமிக்கப்பட்ட விவரங்கள் உங்கள் சாதனத்தில் பாதுகாப்பாக உள்ளன. இது சட்டப்பூர்வ உரிமை ஆவணம் அல்ல.'
                  : 'Personal property records are securely stored locally on this device. They do not constitute official government registration.',
            ),
            const SizedBox(height: 16),
            if (properties.isEmpty)
              Container(
                padding: const EdgeInsets.all(32),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.outline),
                ),
                child: Column(
                  children: [
                    const Icon(Icons.bookmark_border, size: 48, color: AppColors.charcoalLight),
                    const SizedBox(height: 12),
                    Text(
                      AppTranslations.get('no_properties', lang),
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 13, color: AppColors.charcoalLight),
                    ),
                  ],
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: properties.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final prop = properties[index];
                  final id = prop['id'] ?? '';
                  final nickname = prop['nickname'] ?? 'Property';
                  final dist = prop['district_name'] ?? '';
                  final survey = prop['survey_number'] ?? '';
                  final sub = prop['subdivision_number'] ?? '';
                  final extent = prop['extent_value'] ?? 0;
                  final unit = prop['extent_unit'] ?? 'cents';
                  final notes = prop['notes'] ?? '';

                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: AppColors.forestGreen.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Icon(Icons.terrain, color: AppColors.forestGreen, size: 20),
                                  ),
                                  const SizedBox(width: 10),
                                  Text(
                                    nickname,
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.charcoal),
                                  ),
                                ],
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline, size: 20, color: AppColors.charcoalLight),
                                onPressed: () {
                                  _showDeleteDialog(context, ref, id, nickname);
                                },
                              ),
                            ],
                          ),
                          const Divider(height: 16),
                          Row(
                            children: [
                              const Icon(Icons.location_on_outlined, size: 16, color: AppColors.forestGreen),
                              const SizedBox(width: 6),
                              Text('$dist • Survey: $survey/$sub', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              const Icon(Icons.square_foot_outlined, size: 16, color: AppColors.mutedGold),
                              const SizedBox(width: 6),
                              Text('Extent: $extent $unit', style: const TextStyle(fontSize: 12, color: AppColors.charcoalLight)),
                            ],
                          ),
                          if (notes.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppColors.surfaceVariant,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                'Note: $notes',
                                style: const TextStyle(fontSize: 11, color: AppColors.charcoal),
                              ),
                            ),
                          ],
                          const SizedBox(height: 10),
                          Align(
                            alignment: Alignment.centerRight,
                            child: OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: AppColors.forestGreen),
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              icon: const Icon(Icons.picture_as_pdf_outlined, size: 14, color: AppColors.forestGreen),
                              label: const Text('Download Patta (PDF)', style: TextStyle(fontSize: 11, color: AppColors.forestGreen, fontWeight: FontWeight.bold)),
                              onPressed: () {
                                PattaPdfService.previewAndDownload(context, {
                                  'patta_number': prop['patta_number'] ?? '1420',
                                  'district_name': dist,
                                  'taluk_name': prop['taluk_name'] ?? 'Ambattur',
                                  'village_name': prop['village_name'] ?? 'Ambattur',
                                  'survey_number': survey,
                                  'subdivision_number': sub,
                                  'owner_name_en': prop['owner_name_en'] ?? nickname,
                                  'extent_cents': extent,
                                });
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  void _showDeleteDialog(BuildContext context, WidgetRef ref, String id, String name) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Property?'),
        content: Text('Are you sure you want to remove "$name" from your saved properties?'),
        actions: [
          TextButton(
            child: const Text('Cancel'),
            onPressed: () => Navigator.pop(context),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Delete'),
            onPressed: () {
              ref.read(propertiesProvider.notifier).deleteProperty(id);
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }
}
