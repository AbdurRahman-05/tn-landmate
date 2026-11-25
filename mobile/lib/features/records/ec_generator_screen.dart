import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/data/tn_geography_data.dart';
import '../../core/l10n/translations.dart';
import '../../core/providers.dart';
import '../../core/services/ec_pdf_service.dart';
import '../../shared/widgets/custom_app_bar.dart';
import '../../shared/widgets/official_source_card.dart';

class EcGeneratorScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic>? initialData;

  const EcGeneratorScreen({Key? key, this.initialData}) : super(key: key);

  @override
  ConsumerState<EcGeneratorScreen> createState() => _EcGeneratorScreenState();
}

class _EcGeneratorScreenState extends ConsumerState<EcGeneratorScreen> {
  int? _selectedDistrictId = 1;
  int? _selectedTalukId = 1;
  int? _selectedVillageId = 1;

  late TextEditingController _surveyCtrl;
  late TextEditingController _subdivCtrl;
  late TextEditingController _applicantCtrl;
  late TextEditingController _extentCentsCtrl;
  late TextEditingController _sroCtrl;

  int _fromYear = 1994;
  int _toYear = DateTime.now().year;
  bool _isNilEncumbrance = false;

  static const Color reginetMaroon = Color(0xFF7B1113);

  @override
  void initState() {
    super.initState();
    final d = widget.initialData;

    _selectedDistrictId = d?['district_id'] ?? 1;
    _selectedTalukId = d?['taluk_id'] ?? 1;
    _selectedVillageId = d?['village_id'] ?? 1;

    _surveyCtrl = TextEditingController(text: d?['survey_number'] ?? d?['survey_no'] ?? '104');
    _subdivCtrl = TextEditingController(text: d?['subdivision_number'] ?? d?['subdivision_no'] ?? '2B');
    _applicantCtrl = TextEditingController(text: d?['owner_name_en'] ?? d?['owner_name'] ?? 'R. Selvam');
    _extentCentsCtrl = TextEditingController(text: d?['extent_cents']?.toString() ?? '5.51');
    _sroCtrl = TextEditingController(text: d?['sro_name'] ?? 'Ambattur Sub-Registrar Office');
    _isNilEncumbrance = d?['is_nil'] == true;
  }

  @override
  void dispose() {
    _surveyCtrl.dispose();
    _subdivCtrl.dispose();
    _applicantCtrl.dispose();
    _extentCentsCtrl.dispose();
    _sroCtrl.dispose();
    super.dispose();
  }

  void _loadSampleData() {
    setState(() {
      _surveyCtrl.text = '104';
      _subdivCtrl.text = '2B';
      _applicantCtrl.text = 'R. Selvam';
      _extentCentsCtrl.text = '5.51';
      _sroCtrl.text = 'Ambattur Sub-Registrar Office';
      _fromYear = 1994;
      _toYear = DateTime.now().year;
      _isNilEncumbrance = false;
    });
  }

  void _generateAndDownload() {
    final cents = double.tryParse(_extentCentsCtrl.text.trim()) ?? 5.51;
    final sqFt = (cents * 435.6).toStringAsFixed(0);

    final districtName = TnGeographyData.getDistrictName(_selectedDistrictId);
    final talukName = TnGeographyData.getTalukName(_selectedDistrictId, _selectedTalukId);
    final villageName = TnGeographyData.getVillageName(_selectedTalukId, _selectedVillageId);

    final ecRecord = {
      'district_id': _selectedDistrictId,
      'district_name': districtName,
      'taluk_id': _selectedTalukId,
      'taluk_name': talukName,
      'village_id': _selectedVillageId,
      'village_name': villageName,
      'sro_name': _sroCtrl.text.trim().isEmpty ? '$talukName SRO' : _sroCtrl.text.trim(),
      'zone_name': '$districtName Zone',
      'survey_number': _surveyCtrl.text.trim().isEmpty ? '104' : _surveyCtrl.text.trim(),
      'subdivision_number': _subdivCtrl.text.trim().isEmpty ? '1' : _subdivCtrl.text.trim(),
      'applicant_name': _applicantCtrl.text.trim().isEmpty ? 'Citizen Applicant' : _applicantCtrl.text.trim(),
      'extent_cents': cents,
      'extent_sq_ft': sqFt,
      'search_period_from': '01-Jan-$_fromYear',
      'search_period_to': '${DateTime.now().day.toString().padLeft(2, '0')}-${_getMonthShort(DateTime.now().month)}-$_toYear',
      'is_nil_encumbrance': _isNilEncumbrance,
      'reference_id': 'TN-EC-${DateTime.now().year}-${DateTime.now().millisecondsSinceEpoch.toString().substring(6)}',
      'issue_date': DateTime.now().toLocal().toString().split('.')[0],
    };

    EcPdfService.previewAndDownload(context, ecRecord);
  }

  String _getMonthShort(int month) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return months[month - 1];
  }

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(languageProvider);
    final districts = TnGeographyData.districts;
    final taluks = TnGeographyData.getTaluksForDistrict(_selectedDistrictId);
    final villages = TnGeographyData.getVillagesForTaluk(_selectedTalukId);

    return Scaffold(
      appBar: CustomAppBar(
        title: lang == 'ta' ? 'வில்லங்கச் சான்றிதழ் (EC) பதிவிறக்கம்' : 'Download Encumbrance (EC)',
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
            // Top Info Header Banner
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: reginetMaroon.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: reginetMaroon.withOpacity(0.2)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.verified_outlined, color: reginetMaroon, size: 28),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          lang == 'ta'
                              ? 'வில்லங்கச் சான்றிதழ் (படிவம் 15) பதிவிறக்கம்'
                              : 'Encumbrance Certificate (Form 15) Generator',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.charcoal),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          lang == 'ta'
                              ? 'பதிவுத்துறை விதிமுறைகளின்படி கடந்த 30+ ஆண்டுகால வரலாற்றுடன் உடனடி PDF பதிவிறக்கம்.'
                              : 'Instant A4 PDF extract with 30+ year search history, ready to print, share, or archive.',
                          style: const TextStyle(fontSize: 11, color: AppColors.charcoalLight),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Jurisdiction Card
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('1. Registration Jurisdiction / பதிவு எல்லை',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: reginetMaroon)),
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
                          final talukName = TnGeographyData.getTalukName(_selectedDistrictId, _selectedTalukId);
                          _sroCtrl.text = '$talukName Sub-Registrar Office';
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
                          final talukName = TnGeographyData.getTalukName(_selectedDistrictId, _selectedTalukId);
                          _sroCtrl.text = '$talukName Sub-Registrar Office';
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
                    const SizedBox(height: 12),

                    // Sub-Registrar Office
                    TextField(
                      controller: _sroCtrl,
                      decoration: InputDecoration(
                        labelText: 'Sub-Registrar Office (சார்பதிவாளர் அலுவலகம்)',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        isDense: true,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Parcel & Search Period Card
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('2. Parcel Details & Search Duration / புல விவரங்கள்',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: reginetMaroon)),
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
                      ],
                    ),
                    const SizedBox(height: 12),

                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _applicantCtrl,
                            decoration: InputDecoration(
                              labelText: 'Applicant Name / விண்ணப்பதாரர்',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                              isDense: true,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
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
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Search Period Years Selector
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Search Period: ${_toYear - _fromYear + 1} Years',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: reginetMaroon),
                              ),
                              Text(
                                'From $_fromYear to $_toYear',
                                style: const TextStyle(fontSize: 11, color: AppColors.charcoalLight),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: DropdownButtonFormField<int>(
                                  value: _fromYear,
                                  decoration: InputDecoration(
                                    labelText: 'From Year',
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                    isDense: true,
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                  ),
                                  items: [1975, 1985, 1990, 1994, 2000, 2005, 2010, 2015, 2020].map((y) {
                                    return DropdownMenuItem<int>(
                                      value: y,
                                      child: Text(y.toString(), style: const TextStyle(fontSize: 13)),
                                    );
                                  }).toList(),
                                  onChanged: (val) {
                                    if (val != null) setState(() => _fromYear = val);
                                  },
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: DropdownButtonFormField<int>(
                                  value: _toYear,
                                  decoration: InputDecoration(
                                    labelText: 'To Year',
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                    isDense: true,
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                  ),
                                  items: [2026, 2025, 2024, 2023, 2022].map((y) {
                                    return DropdownMenuItem<int>(
                                      value: y,
                                      child: Text(y.toString(), style: const TextStyle(fontSize: 13)),
                                    );
                                  }).toList(),
                                  onChanged: (val) {
                                    if (val != null) setState(() => _toYear = val);
                                  },
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Nil Encumbrance Switch
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      activeColor: reginetMaroon,
                      title: Text(
                        lang == 'ta'
                            ? 'வில்லங்கமின்மை சான்றிதழ் (Nil Encumbrance)'
                            : 'Nil Encumbrance Certificate',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.charcoal),
                      ),
                      subtitle: Text(
                        lang == 'ta'
                            ? 'தேடப்பட்ட காலத்தில் எந்தவித வில்லங்கங்களும் பதிவாகவில்லை என்று சான்றளிக்கும்.'
                            : 'Certifies zero registered encumbrances, charges, or liens during this search duration.',
                        style: const TextStyle(fontSize: 11, color: AppColors.charcoalLight),
                      ),
                      value: _isNilEncumbrance,
                      onChanged: (val) => setState(() => _isNilEncumbrance = val),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Action Button: Download EC PDF
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: reginetMaroon,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 3,
                ),
                icon: const Icon(Icons.download_for_offline, color: AppColors.mutedGold, size: 22),
                label: Text(
                  lang == 'ta'
                      ? 'வில்லங்கச் சான்றிதழ் PDF பதிவிறக்கம் (Download EC)'
                      : 'Download Encumbrance Certificate (PDF)',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white),
                ),
                onPressed: _generateAndDownload,
              ),
            ),
            const SizedBox(height: 16),

            // Official TNREGINET Portal Redirect Card
            OfficialSourceCard(
              title: 'TNREGINET Official Portal (பதிவுத்துறை)',
              description: 'Search official government registered encumbrance records at tnreginet.gov.in.',
              url: 'https://tnreginet.gov.in',
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
