import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/data/tn_geography_data.dart';
import '../../core/l10n/translations.dart';
import '../../core/providers.dart';
import '../../core/services/patta_pdf_service.dart';
import '../../shared/widgets/custom_app_bar.dart';

class PattaGeneratorScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic>? initialData;

  const PattaGeneratorScreen({Key? key, this.initialData}) : super(key: key);

  @override
  ConsumerState<PattaGeneratorScreen> createState() => _PattaGeneratorScreenState();
}

class _PattaGeneratorScreenState extends ConsumerState<PattaGeneratorScreen> {
  int? _selectedDistrictId = 1;
  int? _selectedTalukId = 1;
  int? _selectedVillageId = 1;

  late TextEditingController _surveyCtrl;
  late TextEditingController _subdivCtrl;
  late TextEditingController _pattaNoCtrl;
  late TextEditingController _ownerNameEnCtrl;
  late TextEditingController _ownerNameTaCtrl;
  late TextEditingController _extentCentsCtrl;
  String _landType = 'நன்செய் (Wet Land)';

  @override
  void initState() {
    super.initState();
    final d = widget.initialData;

    _selectedDistrictId = d?['district_id'] ?? 1;
    _selectedTalukId = d?['taluk_id'] ?? 1;
    _selectedVillageId = d?['village_id'] ?? 1;

    _surveyCtrl = TextEditingController(text: d?['survey_number'] ?? d?['survey_no'] ?? '104');
    _subdivCtrl = TextEditingController(text: d?['subdivision_number'] ?? d?['subdivision_no'] ?? '2B');
    _pattaNoCtrl = TextEditingController(text: d?['patta_number'] ?? d?['patta_no'] ?? '1420');
    _ownerNameEnCtrl = TextEditingController(text: d?['owner_name_en'] ?? d?['owner_name'] ?? 'R. Selvam');
    _ownerNameTaCtrl = TextEditingController(text: d?['owner_name_ta'] ?? 'ஆர். செல்வம்');
    _extentCentsCtrl = TextEditingController(text: d?['extent_cents']?.toString() ?? '5.51');
    _landType = d?['land_type'] ?? 'நன்செய் (Wet Land)';
  }

  @override
  void dispose() {
    _surveyCtrl.dispose();
    _subdivCtrl.dispose();
    _pattaNoCtrl.dispose();
    _ownerNameEnCtrl.dispose();
    _ownerNameTaCtrl.dispose();
    _extentCentsCtrl.dispose();
    super.dispose();
  }

  void _loadSampleData() {
    setState(() {
      _surveyCtrl.text = '104';
      _subdivCtrl.text = '2B';
      _pattaNoCtrl.text = '1420';
      _ownerNameEnCtrl.text = 'R. Selvam';
      _ownerNameTaCtrl.text = 'ஆர். செல்வம்';
      _extentCentsCtrl.text = '5.51';
      _landType = 'நன்செய் (Wet Land)';
    });
  }

  void _generateAndDownload() {
    final cents = double.tryParse(_extentCentsCtrl.text.trim()) ?? 5.51;
    final sqFt = (cents * 435.6).toStringAsFixed(0);
    final hectares = (cents * 0.00404686).toStringAsFixed(3);
    final ares = (cents * 0.404686).toStringAsFixed(2);

    final pattaRecord = {
      'district_id': _selectedDistrictId,
      'district_name': TnGeographyData.getDistrictName(_selectedDistrictId),
      'taluk_id': _selectedTalukId,
      'taluk_name': TnGeographyData.getTalukName(_selectedDistrictId, _selectedTalukId),
      'village_id': _selectedVillageId,
      'village_name': TnGeographyData.getVillageName(_selectedTalukId, _selectedVillageId),
      'survey_number': _surveyCtrl.text.trim().isEmpty ? '104' : _surveyCtrl.text.trim(),
      'subdivision_number': _subdivCtrl.text.trim().isEmpty ? '1' : _subdivCtrl.text.trim(),
      'patta_number': _pattaNoCtrl.text.trim().isEmpty ? '1420' : _pattaNoCtrl.text.trim(),
      'owner_name_en': _ownerNameEnCtrl.text.trim().isEmpty ? 'Citizen Title Holder' : _ownerNameEnCtrl.text.trim(),
      'owner_name_ta': _ownerNameTaCtrl.text.trim().isEmpty ? 'பட்டாதாரர்' : _ownerNameTaCtrl.text.trim(),
      'land_type': _landType,
      'extent_cents': cents,
      'extent_sq_ft': sqFt,
      'extent_hectares': hectares,
      'extent_ares': ares,
      'reference_id': 'TN-REV-${DateTime.now().year}-${DateTime.now().millisecondsSinceEpoch.toString().substring(6)}',
      'issue_date': DateTime.now().toLocal().toString().split('.')[0],
      'tax_assessment': '₹ 18.50 / Year',
    };

    PattaPdfService.previewAndDownload(context, pattaRecord);
  }

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(languageProvider);
    final districts = TnGeographyData.districts;
    final taluks = TnGeographyData.getTaluksForDistrict(_selectedDistrictId);
    final villages = TnGeographyData.getVillagesForTaluk(_selectedTalukId);

    return Scaffold(
      appBar: CustomAppBar(
        title: lang == 'ta' ? 'பட்டா நகல் பதிவிறக்கம்' : 'Download Patta Copy',
        actions: [
          TextButton.icon(
            icon: const Icon(Icons.refresh, size: 16, color: Colors.white),
            label: Text(lang == 'ta' ? 'மாதிரி' : 'Sample', style: const TextStyle(color: Colors.white, fontSize: 12)),
            onPressed: _loadSampleData,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Info Header
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.forestGreen.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.forestGreen.withOpacity(0.2)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.picture_as_pdf, color: AppColors.forestGreen, size: 28),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          lang == 'ta'
                              ? 'அதிகாரப்பூர்வ பட்டா / சிட்டா நகல் உருவாக்கம்'
                              : 'Official Patta / Chitta Certificate Generator',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.charcoal),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          lang == 'ta'
                              ? 'வருவாய் துறை விதிமுறைகளின்படி A4 வடிவத்தில் உடனடி PDF பதிவிறக்கம்.'
                              : 'Instant A4 PDF download ready to print, share, or archive.',
                          style: const TextStyle(fontSize: 11, color: AppColors.charcoalLight),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Administrative Dropdowns Card
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('1. Revenue Jurisdiction / வருவாய் எல்லை',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.forestGreen)),
                    const SizedBox(height: 12),

                    // District
                    DropdownButtonFormField<int>(
                      value: _selectedDistrictId,
                      decoration: InputDecoration(
                        labelText: AppTranslations.get('select_district', lang),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        isDense: true,
                      ),
                      items: districts.map((d) {
                        return DropdownMenuItem<int>(
                          value: d['id'] as int,
                          child: Text(lang == 'ta' ? d['name_ta'] : d['name_en']),
                        );
                      }).toList(),
                      onChanged: (val) {
                        setState(() {
                          _selectedDistrictId = val;
                          final tList = TnGeographyData.getTaluksForDistrict(val);
                          _selectedTalukId = tList.isNotEmpty ? tList.first['id'] : null;
                          final vList = TnGeographyData.getVillagesForTaluk(_selectedTalukId);
                          _selectedVillageId = vList.isNotEmpty ? vList.first['id'] : null;
                        });
                      },
                    ),
                    const SizedBox(height: 12),

                    // Taluk
                    DropdownButtonFormField<int>(
                      value: _selectedTalukId,
                      decoration: InputDecoration(
                        labelText: AppTranslations.get('select_taluk', lang),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        isDense: true,
                      ),
                      items: taluks.map((t) {
                        return DropdownMenuItem<int>(
                          value: t['id'] as int,
                          child: Text(lang == 'ta' ? t['name_ta'] : t['name_en']),
                        );
                      }).toList(),
                      onChanged: (val) {
                        setState(() {
                          _selectedTalukId = val;
                          final vList = TnGeographyData.getVillagesForTaluk(val);
                          _selectedVillageId = vList.isNotEmpty ? vList.first['id'] : null;
                        });
                      },
                    ),
                    const SizedBox(height: 12),

                    // Village
                    DropdownButtonFormField<int>(
                      value: _selectedVillageId,
                      decoration: InputDecoration(
                        labelText: AppTranslations.get('select_village', lang),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        isDense: true,
                      ),
                      items: villages.take(300).map((v) {
                        return DropdownMenuItem<int>(
                          value: v['id'] as int,
                          child: Text(
                            lang == 'ta' ? v['name_ta'] : v['name_en'],
                            overflow: TextOverflow.ellipsis,
                          ),
                        );
                      }).toList(),
                      onChanged: (val) => setState(() => _selectedVillageId = val),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Parcel & Owner Details Card
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('2. Land Parcel & Title Particulars / புல விவரங்கள்',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.forestGreen)),
                    const SizedBox(height: 12),

                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _surveyCtrl,
                            decoration: InputDecoration(
                              labelText: AppTranslations.get('survey_no', lang),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                              isDense: true,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextField(
                            controller: _subdivCtrl,
                            decoration: InputDecoration(
                              labelText: AppTranslations.get('subdivision_no', lang),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                              isDense: true,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextField(
                            controller: _pattaNoCtrl,
                            decoration: InputDecoration(
                              labelText: 'பட்டா எண் / No',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                              isDense: true,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Owner Names
                    TextField(
                      controller: _ownerNameEnCtrl,
                      decoration: InputDecoration(
                        labelText: 'Owner Name (English)',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        isDense: true,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _ownerNameTaCtrl,
                      decoration: InputDecoration(
                        labelText: 'உரிமையாளர் பெயர் (தமிழ்)',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        isDense: true,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Extent & Classification
                    Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: TextField(
                            controller: _extentCentsCtrl,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: InputDecoration(
                              labelText: 'Extent (Cents)',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                              isDense: true,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          flex: 3,
                          child: DropdownButtonFormField<String>(
                            value: _landType,
                            decoration: InputDecoration(
                              labelText: 'Classification',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                              isDense: true,
                            ),
                            items: const [
                              DropdownMenuItem(value: 'நன்செய் (Wet Land)', child: Text('நன்செய் (Wet)')),
                              DropdownMenuItem(value: 'புன்செய் (Dry Land)', child: Text('புன்செய் (Dry)')),
                              DropdownMenuItem(value: 'மானாவாரி (Rainfed)', child: Text('மானாவாரி')),
                              DropdownMenuItem(value: 'நத்தம் மனை (House Site)', child: Text('மனை (Site)')),
                            ],
                            onChanged: (val) {
                              if (val != null) setState(() => _landType = val);
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Download Patta PDF Action Button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.forestGreen,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 3,
                ),
                icon: const Icon(Icons.download_for_offline, color: AppColors.mutedGold, size: 22),
                label: Text(
                  lang == 'ta' ? 'பட்டா PDF பதிவிறக்கம் செய்க (Download)' : 'Download Generated Patta (PDF)',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white),
                ),
                onPressed: _generateAndDownload,
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
