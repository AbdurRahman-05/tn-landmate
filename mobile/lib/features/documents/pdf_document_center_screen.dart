import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/data/tn_geography_data.dart';
import '../../core/l10n/translations.dart';
import '../../core/providers.dart';
import '../../core/services/document_pdf_service.dart';
import '../../shared/widgets/custom_app_bar.dart';
import 'document_vault_screen.dart';

class PdfDocumentCenterScreen extends ConsumerStatefulWidget {
  final String? initialDocType;
  final Map<String, dynamic>? initialData;

  const PdfDocumentCenterScreen({
    Key? key,
    this.initialDocType,
    this.initialData,
  }) : super(key: key);

  @override
  ConsumerState<PdfDocumentCenterScreen> createState() => _PdfDocumentCenterScreenState();
}

class _PdfDocumentCenterScreenState extends ConsumerState<PdfDocumentCenterScreen> {
  late String _selectedDocType;
  int? _selectedDistrictId = 1;
  int? _selectedTalukId = 1;
  int? _selectedVillageId = 1;

  late TextEditingController _surveyCtrl;
  late TextEditingController _subdivCtrl;
  late TextEditingController _pattaNoCtrl;
  late TextEditingController _ownerNameEnCtrl;
  late TextEditingController _ownerNameTaCtrl;
  late TextEditingController _extentCentsCtrl;
  late TextEditingController _marketValCtrl;
  String _landType = 'நன்செய் (Wet Land)';

  final List<Map<String, dynamic>> _docTypes = [
    {
      'id': 'patta_chitta',
      'label_en': 'Patta / Chitta',
      'label_ta': 'பட்டா / சிட்டா',
      'icon': Icons.description_outlined,
      'color': const Color(0xFF15803D),
      'desc': 'Title ownership & land revenue tax assessment extract.',
    },
    {
      'id': 'a_register',
      'label_en': 'A-Register',
      'label_ta': 'அ-பதிவேடு',
      'icon': Icons.menu_book_outlined,
      'color': const Color(0xFF2563EB),
      'desc': 'Permanent village record verifying Ryotwari vs Poramboke.',
    },
    {
      'id': 'fmb',
      'label_en': 'FMB Sketch',
      'label_ta': 'புல வரைபடம்',
      'icon': Icons.map_outlined,
      'color': const Color(0xFF7C3AED),
      'desc': 'Cadastral parcel map showing boundary ladder offsets.',
    },
    {
      'id': 'registration_valuation',
      'label_en': 'Valuation Cert',
      'label_ta': 'பதிவுக் கட்டணம்',
      'icon': Icons.receipt_long_outlined,
      'color': const Color(0xFFD97706),
      'desc': 'Stamp duty (7%) & registration fee (4%) cost sheet.',
    },
    {
      'id': 'due_diligence',
      'label_en': 'Legal Dossier',
      'label_ta': 'முழு அறிக்கை',
      'icon': Icons.verified_user_outlined,
      'color': const Color(0xFFDC2626),
      'desc': '30-year EC audit, parent deed linkage, and title verification.',
    },
  ];

  @override
  void initState() {
    super.initState();
    _selectedDocType = widget.initialDocType ?? 'patta_chitta';

    final d = widget.initialData;
    _selectedDistrictId = d?['district_id'] ?? 1;
    _selectedTalukId = d?['taluk_id'] ?? 1;
    _selectedVillageId = d?['village_id'] ?? 1;

    _surveyCtrl = TextEditingController(text: (d?['survey_number'] ?? d?['survey_no'] ?? '104').toString());
    _subdivCtrl = TextEditingController(text: (d?['subdivision_number'] ?? d?['subdivision_no'] ?? '2B').toString());
    _pattaNoCtrl = TextEditingController(text: (d?['patta_number'] ?? d?['patta_no'] ?? '1420').toString());
    _ownerNameEnCtrl = TextEditingController(text: (d?['owner_name_en'] ?? d?['owner_name'] ?? 'R. Selvam').toString());
    _ownerNameTaCtrl = TextEditingController(text: (d?['owner_name_ta'] ?? 'ஆர். செல்வம்').toString());
    _extentCentsCtrl = TextEditingController(text: (d?['extent_cents'] ?? '5.51').toString());
    _marketValCtrl = TextEditingController(text: (d?['market_value'] ?? '2400000').toString());
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
    _marketValCtrl.dispose();
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
      _marketValCtrl.text = '2400000';
      _landType = 'நன்செய் (Wet Land)';
    });
  }

  void _fillFromSavedProperty(Map<String, dynamic> prop) {
    setState(() {
      _surveyCtrl.text = (prop['survey_number'] ?? '104').toString();
      _subdivCtrl.text = (prop['subdivision_number'] ?? '1').toString();
      _pattaNoCtrl.text = (prop['patta_number'] ?? '1420').toString();
      _ownerNameEnCtrl.text = (prop['owner_name_en'] ?? prop['nickname'] ?? 'Citizen Owner').toString();
      _extentCentsCtrl.text = (prop['extent_value'] ?? prop['extent_cents'] ?? 5.51).toString();
      if (prop['estimated_market_value'] != null) {
        _marketValCtrl.text = prop['estimated_market_value'].toString();
      }
    });
  }

  void _generateAndPreview() {
    final cents = double.tryParse(_extentCentsCtrl.text.trim()) ?? 5.51;
    final sqFt = (cents * 435.6).toStringAsFixed(0);
    final hectares = (cents * 0.00404686).toStringAsFixed(3);
    final ares = (cents * 0.404686).toStringAsFixed(2);
    final guideVal = double.tryParse(_marketValCtrl.text.trim()) ?? 2400000.0;

    final parcelData = {
      'district_id': _selectedDistrictId,
      'district_name': TnGeographyData.getDistrictName(_selectedDistrictId),
      'taluk_id': _selectedTalukId,
      'taluk_name': TnGeographyData.getTalukName(_selectedDistrictId, _selectedTalukId),
      'village_id': _selectedVillageId,
      'village_name': TnGeographyData.getVillageName(_selectedTalukId, _selectedVillageId),
      'survey_number': _surveyCtrl.text.trim().isEmpty ? '104' : _surveyCtrl.text.trim(),
      'subdivision_number': _subdivCtrl.text.trim().isEmpty ? '1' : _subdivCtrl.text.trim(),
      'patta_number': _pattaNoCtrl.text.trim().isEmpty ? '1420' : _pattaNoCtrl.text.trim(),
      'owner_name_en': _ownerNameEnCtrl.text.trim().isEmpty ? 'Title Holder' : _ownerNameEnCtrl.text.trim(),
      'owner_name_ta': _ownerNameTaCtrl.text.trim().isEmpty ? 'உரிமையாளர்' : _ownerNameTaCtrl.text.trim(),
      'land_type': _landType,
      'extent_cents': cents,
      'extent_sq_ft': sqFt,
      'extent_hectares': hectares,
      'extent_ares': ares,
      'guideline_value': guideVal,
      'reference_id': 'TN-REV-${DateTime.now().year}-${DateTime.now().millisecondsSinceEpoch.toString().substring(6)}',
      'issue_date': DateTime.now().toLocal().toString().split('.')[0],
      'tax_assessment': 'Rs. 18.50 / Year',
    };

    DocumentPdfService.previewAndDownload(
      context: context,
      docType: _selectedDocType,
      data: parcelData,
    );
  }

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(languageProvider);
    final savedProps = ref.watch(propertiesProvider);
    final districts = TnGeographyData.districts;
    final taluks = TnGeographyData.getTaluksForDistrict(_selectedDistrictId);
    final villages = TnGeographyData.getVillagesForTaluk(_selectedTalukId);

    final currentMeta = _docTypes.firstWhere((t) => t['id'] == _selectedDocType, orElse: () => _docTypes.first);

    return Scaffold(
      appBar: CustomAppBar(
        title: lang == 'ta' ? 'ஆவண மையம் & PDF பதிவிறக்கம்' : 'Revenue Document & PDF Center',
        actions: [
          IconButton(
            icon: const Icon(Icons.folder_special_outlined),
            tooltip: 'Document Vault',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const DocumentVaultScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh, size: 20),
            tooltip: 'Fill Sample',
            onPressed: _loadSampleData,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Document Type Selector Carousel / Chips
            Text(
              lang == 'ta' ? 'தேர்ந்தெடுக்கப்பட்ட ஆவணம்:' : 'Select Document Type to Generate:',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.charcoal),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 44,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _docTypes.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, i) {
                  final item = _docTypes[i];
                  final isSel = item['id'] == _selectedDocType;
                  final Color c = item['color'];

                  return ChoiceChip(
                    avatar: Icon(item['icon'], size: 16, color: isSel ? Colors.white : c),
                    label: Text(lang == 'ta' ? item['label_ta'] : item['label_en']),
                    selected: isSel,
                    selectedColor: c,
                    labelStyle: TextStyle(
                      color: isSel ? Colors.white : AppColors.charcoal,
                      fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                      fontSize: 12,
                    ),
                    onSelected: (val) {
                      if (val) setState(() => _selectedDocType = item['id']);
                    },
                  );
                },
              ),
            ),
            const SizedBox(height: 12),

            // Active Doc Description Banner
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: (currentMeta['color'] as Color).withOpacity(0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: (currentMeta['color'] as Color).withOpacity(0.2)),
              ),
              child: Row(
                children: [
                  Icon(currentMeta['icon'], color: currentMeta['color'], size: 22),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      currentMeta['desc'],
                      style: TextStyle(fontSize: 11, color: Colors.grey.shade800, height: 1.3),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Quick-fill from saved properties (if any exist)
            if (savedProps.isNotEmpty) ...[
              Card(
                color: Colors.amber.shade50,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                  side: BorderSide(color: Colors.amber.shade200),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  child: Row(
                    children: [
                      const Icon(Icons.bookmark, color: AppColors.mutedGold, size: 18),
                      const SizedBox(width: 8),
                      const Text('Quick Fill From Saved:', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                      const SizedBox(width: 10),
                      Expanded(
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            isDense: true,
                            hint: const Text('Pick property', style: TextStyle(fontSize: 11)),
                            items: savedProps.map((p) {
                              return DropdownMenuItem<String>(
                                value: p['id'].toString(),
                                child: Text(p['nickname'] ?? 'Plot', style: const TextStyle(fontSize: 11)),
                              );
                            }).toList(),
                            onChanged: (id) {
                              final prop = savedProps.firstWhere((e) => e['id'].toString() == id);
                              _fillFromSavedProperty(prop);
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],

            // 1. Administrative Jurisdiction
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('1. Revenue Administrative Jurisdiction',
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

            // 2. Parcel & Title Particulars
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('2. Land Parcel & Title Holder Particulars',
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
                        const SizedBox(width: 8),
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
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: _pattaNoCtrl,
                            decoration: InputDecoration(
                              labelText: 'Patta No',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                              isDense: true,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Owner Names
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _ownerNameEnCtrl,
                            decoration: InputDecoration(
                              labelText: 'Owner (English)',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                              isDense: true,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextField(
                            controller: _ownerNameTaCtrl,
                            decoration: InputDecoration(
                              labelText: 'உரிமையாளர் (தமிழ்)',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                              isDense: true,
                            ),
                          ),
                        ),
                      ],
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
                    if (_selectedDocType == 'registration_valuation') ...[
                      const SizedBox(height: 12),
                      TextField(
                        controller: _marketValCtrl,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'Estimated Market Value (Rs)',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          isDense: true,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Primary Generate & Preview Action Button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: currentMeta['color'],
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 2,
                ),
                icon: const Icon(Icons.picture_as_pdf, color: Colors.white, size: 20),
                label: Text(
                  lang == 'ta'
                      ? '${currentMeta['label_ta']} சான்றிதழ் உருவாக்கு (PDF)'
                      : 'Generate & Preview ${currentMeta['label_en']} (PDF)',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white),
                ),
                onPressed: _generateAndPreview,
              ),
            ),
            const SizedBox(height: 10),

            // Vault Shortcut Button
            SizedBox(
              width: double.infinity,
              height: 44,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: currentMeta['color']),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                icon: Icon(Icons.folder_open_outlined, color: currentMeta['color'], size: 18),
                label: Text(
                  lang == 'ta' ? 'பதிவிறக்கிய ஆவணங்கள் வரலாறு (Vault)' : 'Open Document Vault & Offline Archive',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: currentMeta['color']),
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const DocumentVaultScreen()),
                  );
                },
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
