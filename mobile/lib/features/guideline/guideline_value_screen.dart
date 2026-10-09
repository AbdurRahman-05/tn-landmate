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

class GuidelineValueScreen extends ConsumerStatefulWidget {
  const GuidelineValueScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<GuidelineValueScreen> createState() => _GuidelineValueScreenState();
}

class _GuidelineValueScreenState extends ConsumerState<GuidelineValueScreen> {
  String _selectedDistrict = 'Chennai';
  String _selectedSRO = 'Mylapore SRO';
  String _searchQuery = '';

  final List<Map<String, dynamic>> _sampleValues = [
    {
      'district': 'Chennai',
      'sro': 'Mylapore SRO',
      'village': 'Mylapore',
      'street': 'Luz Church Road',
      'class': 'Commercial Special Class',
      'value': 14500.0,
      'unit': 'Sq.Ft',
      'effective_from': '01-07-2024',
      'source': 'TN Registration Department Public Portal',
    },
    {
      'district': 'Chennai',
      'sro': 'Mylapore SRO',
      'village': 'Alwarpet',
      'street': 'TTK Road (Alwarpet Junction)',
      'class': 'Residential Class I',
      'value': 12000.0,
      'unit': 'Sq.Ft',
      'effective_from': '01-07-2024',
      'source': 'TN Registration Department Public Portal',
    },
    {
      'district': 'Chennai',
      'sro': 'Velachery SRO',
      'village': 'Velachery',
      'street': '100 Feet Inner Ring Road',
      'class': 'Residential Class I',
      'value': 7200.0,
      'unit': 'Sq.Ft',
      'effective_from': '01-07-2024',
      'source': 'TN Registration Department Public Portal',
    },
    {
      'district': 'Coimbatore',
      'sro': 'Gandhipuram SRO',
      'village': 'RS Puram',
      'street': 'Diwan Bahadur Road (DB Road)',
      'class': 'Commercial Prime',
      'value': 11000.0,
      'unit': 'Sq.Ft',
      'effective_from': '01-07-2024',
      'source': 'TN Registration Department Public Portal',
    },
  ];

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(languageProvider);

    final filtered = _sampleValues.where((item) {
      final matchesDist = item['district'] == _selectedDistrict;
      final matchesQuery = _searchQuery.isEmpty ||
          item['street'].toString().toLowerCase().contains(_searchQuery.toLowerCase()) ||
          item['village'].toString().toLowerCase().contains(_searchQuery.toLowerCase());
      return matchesDist && matchesQuery;
    }).toList();

    return Scaffold(
      appBar: CustomAppBar(
        title: AppTranslations.get('guideline_value', lang),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DisclaimerBanner(
              text: lang == 'ta'
                  ? 'வழிகாட்டி மதிப்பு என்பது முத்திரைத்தாள் கணக்கீட்டிற்கான பதிவுத் துறை மதிப்பீடாகும். அதிகாரப்பூர்வ மதிப்பை TNREGINET தளத்தில் சரிபார்க்கவும்.'
                  : 'Guideline values represent the base rate for stamp duty fixed by the Registration Department. Check TNREGINET for officially revised gazetted values.',
            ),
            const SizedBox(height: 16),

            // Filter Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      lang == 'ta' ? 'மாவட்டம் மற்றும் சார்பதிவாளர் அலுவலகம்' : 'District & Sub-Registrar Office',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.charcoal),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: _selectedDistrict,
                            decoration: const InputDecoration(labelText: 'District', contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 10)),
                            items: const [
                              DropdownMenuItem(value: 'Chennai', child: Text('Chennai')),
                              DropdownMenuItem(value: 'Coimbatore', child: Text('Coimbatore')),
                            ],
                            onChanged: (val) {
                              if (val != null) setState(() => _selectedDistrict = val);
                            },
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: _selectedSRO,
                            decoration: const InputDecoration(labelText: 'SRO Office', contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 10)),
                            items: const [
                              DropdownMenuItem(value: 'Mylapore SRO', child: Text('Mylapore SRO')),
                              DropdownMenuItem(value: 'Velachery SRO', child: Text('Velachery SRO')),
                              DropdownMenuItem(value: 'Gandhipuram SRO', child: Text('Gandhipuram SRO')),
                            ],
                            onChanged: (val) {
                              if (val != null) setState(() => _selectedSRO = val);
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.search, size: 18),
                        hintText: lang == 'ta' ? 'தெரு அல்லது கிராமத்தின் பெயர்...' : 'Filter street or village name...',
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                      onChanged: (val) {
                        setState(() => _searchQuery = val.trim());
                      },
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            Text(
              lang == 'ta' ? 'வழிகாட்டி மதிப்பு முடிவுகள்' : 'Registered Guideline Values',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.charcoal),
            ),
            const SizedBox(height: 10),

            if (filtered.isEmpty)
              Container(
                padding: const EdgeInsets.all(24),
                alignment: Alignment.center,
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.outline)),
                child: Text(
                  lang == 'ta' ? 'தேடலுக்கான பதிவுகள் கிடைக்கவில்லை' : 'No records found matching query in local cached directory.',
                  style: const TextStyle(fontSize: 12, color: AppColors.charcoalLight),
                ),
              )
            else
              ...filtered.map((item) {
                return Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              item['village'],
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.forestGreen),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.mutedGold.withOpacity(0.18),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                item['class'],
                                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF92400E)),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          item['street'],
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.charcoal),
                        ),
                        const Divider(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Guideline Rate:', style: TextStyle(fontSize: 12, color: AppColors.charcoalLight)),
                            Text(
                              '₹${item['value'].toStringAsFixed(0)} / ${item['unit']}',
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.forestGreenDark),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Effective: ${item['effective_from']}', style: const TextStyle(fontSize: 10, color: AppColors.charcoalLight)),
                            Text(item['source'], style: const TextStyle(fontSize: 10, color: AppColors.charcoalLight, fontStyle: FontStyle.italic)),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),

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
                  lang == 'ta' ? 'அரசு வழிகாட்டி மதிப்பு பெறுக (TNREGINET Live)' : 'Extract Live Guideline Value (Native UI)',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                onPressed: () {
                  LiveGovExtractorSheet.show(
                    context: context,
                    recordType: 'guideline_value',
                    title: lang == 'ta' ? 'அரசு வழிகாட்டி மதிப்பு நேரடி விவரம்' : 'Live TNREGINET Guideline Value',
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
            OfficialSourceCard(
              title: 'Official TNREGINET Guideline Portal',
              description: 'Extract official street-wise value directly into the mobile app UI.',
              url: 'https://tnreginet.gov.in',
              onTap: () {
                LiveGovExtractorSheet.show(
                  context: context,
                  recordType: 'guideline_value',
                  title: lang == 'ta' ? 'அரசு வழிகாட்டி மதிப்பு நேரடி விவரம்' : 'Live TNREGINET Guideline Value',
                );
              },
            ),
          ],
        ),
      ),
    );

  }
}
