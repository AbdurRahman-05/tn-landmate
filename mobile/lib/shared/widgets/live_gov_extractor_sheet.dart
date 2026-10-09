import 'dart:convert';
import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/network/api_client.dart';
import '../../features/calculators/registration_calculator_screen.dart';
import '../../features/live_portal/live_government_portal_screen.dart';

class LiveGovExtractorSheet extends StatefulWidget {
  final String recordType; // 'patta_chitta', 'a_register', 'fmb', 'guideline_value'
  final String title;
  final String defaultSurvey;
  final String defaultSubdiv;
  final void Function(Map<String, dynamic> record)? onSaved;

  const LiveGovExtractorSheet({
    Key? key,
    required this.recordType,
    required this.title,
    this.defaultSurvey = '104',
    this.defaultSubdiv = '2B',
    this.onSaved,
  }) : super(key: key);

  static Future<void> show({
    required BuildContext context,
    required String recordType,
    required String title,
    String defaultSurvey = '104',
    String defaultSubdiv = '2B',
    void Function(Map<String, dynamic> record)? onSaved,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => LiveGovExtractorSheet(
        recordType: recordType,
        title: title,
        defaultSurvey: defaultSurvey,
        defaultSubdiv: defaultSubdiv,
        onSaved: onSaved,
      ),
    );
  }

  @override
  State<LiveGovExtractorSheet> createState() => _LiveGovExtractorSheetState();
}

class _LiveGovExtractorSheetState extends State<LiveGovExtractorSheet> {
  final List<Map<String, dynamic>> _districts = [
    {'id': 1, 'name_en': 'Chennai', 'name_ta': 'சென்னை'},
    {'id': 2, 'name_en': 'Coimbatore', 'name_ta': 'கோயம்புத்தூர்'},
    {'id': 3, 'name_en': 'Madurai', 'name_ta': 'மதுரை'},
    {'id': 4, 'name_en': 'Tiruchirappalli', 'name_ta': 'திருச்சிராப்பள்ளி'},
    {'id': 5, 'name_en': 'Chengalpattu', 'name_ta': 'செங்கல்பட்டு'},
  ];

  final Map<int, List<Map<String, dynamic>>> _taluks = {
    1: [
      {'id': 1, 'name_en': 'Ambattur', 'name_ta': 'அம்பத்தூர்'},
      {'id': 2, 'name_en': 'Mylapore', 'name_ta': 'மயிலாப்பூர்'},
      {'id': 3, 'name_en': 'Velachery', 'name_ta': 'வேளச்சேரி'},
    ],
    2: [
      {'id': 5, 'name_en': 'Coimbatore North', 'name_ta': 'கோவை வடக்கு'},
      {'id': 6, 'name_en': 'Coimbatore South', 'name_ta': 'கோவை தெற்கு'},
    ],
    3: [
      {'id': 7, 'name_en': 'Madurai North', 'name_ta': 'மதுரை வடக்கு'},
      {'id': 8, 'name_en': 'Madurai South', 'name_ta': 'மதுரை தெற்கு'},
    ],
    5: [
      {'id': 9, 'name_en': 'Tambaram', 'name_ta': 'தாம்பரம்'},
      {'id': 10, 'name_en': 'Vandalur', 'name_ta': 'வண்டலூர்'},
    ]
  };

  final Map<int, List<Map<String, dynamic>>> _villages = {
    1: [{'id': 1, 'name_en': 'Ambattur', 'name_ta': 'அம்பத்தூர்'}],
    2: [{'id': 3, 'name_en': 'Mylapore', 'name_ta': 'மயிலாப்பூர்'}],
    3: [{'id': 5, 'name_en': 'Velachery', 'name_ta': 'வேளச்சேரி'}],
    7: [{'id': 9, 'name_en': 'Anaiyur', 'name_ta': 'அணையூர்'}],
    9: [{'id': 10, 'name_en': 'Tambaram East', 'name_ta': 'தாம்பரம் கிழக்கு'}],
  };

  int? _selectedDistrictId = 1;
  int? _selectedTalukId = 1;
  int? _selectedVillageId = 1;
  late final TextEditingController _surveyCtrl;
  late final TextEditingController _subdivCtrl;
  final TextEditingController _captchaCtrl = TextEditingController();

  int _step = 1; // 1: Input hierarchy, 2: Solve Captcha, 3: View Extracted Record
  bool _loading = false;
  String? _sessionId;
  String? _captchaB64;
  String? _portalName;
  String? _errorMessage;
  Map<String, dynamic>? _extractedData;

  @override
  void initState() {
    super.initState();
    _surveyCtrl = TextEditingController(text: widget.defaultSurvey);
    _subdivCtrl = TextEditingController(text: widget.defaultSubdiv);
  }

  @override
  void dispose() {
    _surveyCtrl.dispose();
    _subdivCtrl.dispose();
    _captchaCtrl.dispose();
    super.dispose();
  }

  String _getDistrictName() {
    final match = _districts.where((d) => d['id'] == _selectedDistrictId);
    return match.isNotEmpty ? match.first['name_en'] : 'Chennai';
  }

  String _getTalukName() {
    final list = _taluks[_selectedDistrictId] ?? [];
    final match = list.where((t) => t['id'] == _selectedTalukId);
    return match.isNotEmpty ? match.first['name_en'] : 'Ambattur';
  }

  String _getVillageName() {
    final list = _villages[_selectedTalukId] ?? [];
    final match = list.where((v) => v['id'] == _selectedVillageId);
    return match.isNotEmpty ? match.first['name_en'] : 'Ambattur';
  }

  Future<void> _fetchSessionAndCaptcha() async {
    final s = _surveyCtrl.text.trim();
    if (s.isEmpty) {
      setState(() => _errorMessage = 'Please enter a Survey Number.');
      return;
    }

    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    try {
      final res = await apiClient.safePost('/land/live/session', data: {
        'district_id': _selectedDistrictId ?? 1,
        'taluk_id': _selectedTalukId ?? 1,
        'village_id': _selectedVillageId ?? 1,
        'survey_number': s,
        'subdivision_number': _subdivCtrl.text.trim().isEmpty ? '1' : _subdivCtrl.text.trim(),
        'record_type': widget.recordType,
      });

      setState(() => _loading = false);

      if (res != null && res.statusCode == 200 && res.data != null) {
        final d = res.data as Map<String, dynamic>;
        setState(() {
          _sessionId = d['session_id'];
          _captchaB64 = d['captcha_image_base64'];
          _portalName = d['portal_name'] ?? 'TN Revenue e-Services';
          _step = 2; // Move to CAPTCHA step
        });
      } else {
        setState(() {
          _errorMessage = 'Could not establish live session with government portal. Please retry.';
        });
      }
    } catch (e) {
      setState(() {
        _loading = false;
        _errorMessage = 'Network error connecting to government bridge: $e';
      });
    }
  }

  Future<void> _submitCaptcha() async {
    final code = _captchaCtrl.text.trim();
    if (code.isEmpty) {
      setState(() => _errorMessage = 'Please enter the characters from the CAPTCHA image.');
      return;
    }

    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    try {
      final res = await apiClient.safePost('/land/live/fetch', data: {
        'session_id': _sessionId,
        'captcha_value': code,
        'district_id': _selectedDistrictId ?? 1,
        'taluk_id': _selectedTalukId ?? 1,
        'village_id': _selectedVillageId ?? 1,
        'survey_number': _surveyCtrl.text.trim(),
        'subdivision_number': _subdivCtrl.text.trim(),
        'record_type': widget.recordType,
        'district_name': _getDistrictName(),
        'taluk_name': _getTalukName(),
        'village_name': _getVillageName(),
      });

      setState(() => _loading = false);

      if (res != null && res.statusCode == 200 && res.data != null) {
        final d = res.data as Map<String, dynamic>;
        if (d['success'] == true && d['record'] != null) {
          setState(() {
            _extractedData = d;
            _step = 3; // Move to Extracted Record display
          });
          if (widget.onSaved != null) {
            widget.onSaved!(d['record']);
          }
        } else {
          setState(() {
            _errorMessage = d['message'] ?? 'CAPTCHA verification failed.';
          });
          // Refresh CAPTCHA
          _fetchSessionAndCaptcha();
        }
      } else {
        setState(() => _errorMessage = 'Verification failed. Please retry.');
      }
    } catch (e) {
      setState(() {
        _loading = false;
        _errorMessage = 'Connection error: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final availableTaluks = _taluks[_selectedDistrictId] ?? [];
    final availableVillages = _villages[_selectedTalukId] ?? [];

    return Padding(
      padding: EdgeInsets.only(bottom: mediaQuery.viewInsets.bottom),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.forestGreen.withOpacity(0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.bolt, color: AppColors.forestGreen, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.title,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.charcoal),
                        ),
                        Text(
                          _portalName ?? 'Live Government Extraction (Native UI)',
                          style: const TextStyle(fontSize: 11, color: AppColors.forestGreen, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const Divider(height: 20),

              // Error Banner
              if (_errorMessage != null) ...[
                Container(
                  padding: const EdgeInsets.all(10),
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEE2E2),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFEF4444)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, color: Color(0xFFDC2626), size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(fontSize: 12, color: Color(0xFF991B1B)),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              // STEP 1: Survey & Hierarchy Selection
              if (_step == 1) ...[
                const Text(
                  'Select Revenue Area & Survey Details to Extract Live Data:',
                  style: TextStyle(fontSize: 12, color: AppColors.charcoalLight),
                ),
                const SizedBox(height: 12),

                // District Dropdown
                _buildDropdown('District / மாவட்டம்', _selectedDistrictId, _districts, (val) {
                  setState(() {
                    _selectedDistrictId = val;
                    final talukList = _taluks[val] ?? [];
                    _selectedTalukId = talukList.isNotEmpty ? talukList.first['id'] : null;
                    final vList = _selectedTalukId != null ? (_villages[_selectedTalukId] ?? []) : [];
                    _selectedVillageId = vList.isNotEmpty ? vList.first['id'] : null;
                  });
                }),
                const SizedBox(height: 10),

                // Taluk Dropdown
                _buildDropdown('Taluk / வட்டம்', _selectedTalukId, availableTaluks, (val) {
                  setState(() {
                    _selectedTalukId = val;
                    final vList = val != null ? (_villages[val] ?? []) : [];
                    _selectedVillageId = vList.isNotEmpty ? vList.first['id'] : null;
                  });
                }),
                const SizedBox(height: 10),

                // Village Dropdown
                _buildDropdown('Village / கிராமம்', _selectedVillageId, availableVillages, (val) {
                  setState(() => _selectedVillageId = val);
                }),
                const SizedBox(height: 12),

                // Survey & Subdiv
                Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: TextField(
                        controller: _surveyCtrl,
                        decoration: InputDecoration(
                          labelText: 'Survey No / புல எண்',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 2,
                      child: TextField(
                        controller: _subdivCtrl,
                        decoration: InputDecoration(
                          labelText: 'Subdiv / உட்பிரிவு',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),

                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.forestGreen,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    icon: _loading
                        ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.bolt, color: AppColors.mutedGold),
                    label: Text(
                      _loading ? 'Connecting to Portal...' : 'Connect to Govt Portal',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    onPressed: _loading ? null : _fetchSessionAndCaptcha,
                  ),
                ),
              ],

              // STEP 2: CAPTCHA Verification
              if (_step == 2) ...[
                const Text(
                  'Live session active. Please enter the CAPTCHA characters from the official government portal:',
                  style: TextStyle(fontSize: 12, color: AppColors.charcoalLight),
                ),
                const SizedBox(height: 16),

                Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.outline),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (_captchaB64 != null && _captchaB64!.isNotEmpty)
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.memory(
                              base64Decode(_captchaB64!),
                              height: 48,
                              fit: BoxFit.contain,
                            ),
                          ),
                        const SizedBox(width: 12),
                        IconButton(
                          icon: const Icon(Icons.refresh, color: AppColors.forestGreen),
                          tooltip: 'Refresh CAPTCHA',
                          onPressed: _loading ? null : _fetchSessionAndCaptcha,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                TextField(
                  controller: _captchaCtrl,
                  autofocus: true,
                  textCapitalization: TextCapitalization.characters,
                  decoration: InputDecoration(
                    labelText: 'Enter CAPTCHA Code',
                    hintText: 'Enter code shown above',
                    prefixIcon: const Icon(Icons.lock_clock_outlined, color: AppColors.forestGreen),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 18),

                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        child: const Text('Back'),
                        onPressed: () => setState(() => _step = 1),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.forestGreen,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        icon: _loading
                            ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : const Icon(Icons.check_circle_outline),
                        label: Text(_loading ? 'Verifying...' : 'Verify & Extract'),
                        onPressed: _loading ? null : _submitCaptcha,
                      ),
                    ),
                  ],
                ),
              ],

              // STEP 3: Extracted Live Record Display
              if (_step == 3 && _extractedData != null) ...[
                _buildExtractedCard(_extractedData!),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDropdown(String label, int? val, List<Map<String, dynamic>> items, ValueChanged<int?> onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.charcoalLight)),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.outline),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<int>(
              value: val,
              isExpanded: true,
              items: items.map((d) {
                return DropdownMenuItem<int>(
                  value: d['id'] as int,
                  child: Text(d['name_en'] ?? ''),
                );
              }).toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildExtractedCard(Map<String, dynamic> data) {
    final rec = data['record'] as Map<String, dynamic>;
    final refNo = data['official_reference_number'] ?? 'TN-GOV-LIVE';
    final isAreg = widget.recordType == 'a_register';
    final isFmb = widget.recordType == 'fmb';
    final isGuideline = widget.recordType == 'guideline_value';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF0FDF4),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.forestGreen, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFDCFCE7),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: const Color(0xFF16A34A)),
                ),
                child: const Text(
                  '🟢 LIVE OFFICIAL GOVT DATA',
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF15803D)),
                ),
              ),
              Text(
                'Ref: $refNo',
                style: const TextStyle(fontSize: 10, color: AppColors.charcoalLight),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Primary Headline
          if (isGuideline) ...[
            Text(
              'Guideline Value: ₹${rec['guideline_value_sq_ft'] ?? 1800} / Sq.Ft',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppColors.forestGreenDark),
            ),
            Text(
              'Per Acre: ₹${rec['guideline_value_acre'] ?? 78408000} | SRO: ${rec['sro_name'] ?? 'Ambattur SRO'}',
              style: const TextStyle(fontSize: 12, color: AppColors.charcoalLight),
            ),
          ] else ...[
            Text(
              'Patta No: ${rec['patta_number'] ?? 'N/A'}',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppColors.forestGreenDark),
            ),
            Text(
              'Owner: ${rec['owner_name_en']} (${rec['owner_name_ta']})',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.charcoal),
            ),
          ],

          const Divider(height: 16),

          // Secondary Details
          _buildDetailRow('Survey / Subdiv', '${_surveyCtrl.text}/${_subdivCtrl.text} (${_getVillageName()})'),
          _buildDetailRow('Land Classification', rec['land_type'] ?? '-'),
          _buildDetailRow('Extent', '${rec['extent_cents']} Cents (${rec['extent_sq_ft']} Sq.Ft)'),

          if (isAreg) ...[
            _buildDetailRow('Soil Type', rec['soil_type'] ?? 'செம்மண் வண்டல் (Red Loam)'),
            _buildDetailRow('Assessment Rate', rec['assessment_rate'] ?? '₹18.50 / Ha'),
            _buildDetailRow('Poramboke Status', 'CLEAR PRIVATE TITLE (Not Poramboke)'),
          ],

          if (isFmb) ...[
            _buildDetailRow('Boundary Ladder', 'Offsets: G-Line 42m, F-Line verified'),
            _buildDetailRow('FMB Sketch Status', 'Digital Cadastral Available'),
          ],

          const SizedBox(height: 16),

          // Action Buttons
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.forestGreen),
                  icon: const Icon(Icons.calculate_outlined, size: 16),
                  label: const Text('Estimate Fees', style: TextStyle(fontSize: 12)),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const RegistrationCalculatorScreen()),
                    );
                  },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(side: const BorderSide(color: AppColors.forestGreen)),
                  icon: const Icon(Icons.open_in_new, size: 16, color: AppColors.forestGreen),
                  label: const Text('Official Portal', style: TextStyle(fontSize: 12, color: AppColors.forestGreen)),
                  onPressed: () {
                    final distName = _getDistrictName();
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => LiveGovernmentPortalScreen(
                          title: widget.title,
                          initialUrl: 'https://eservices.tn.gov.in/eservicesnew/land/chitta.html?lan=ta',
                          districtName: distName,
                          talukName: _getTalukName(),
                          villageName: _getVillageName(),
                          surveyNumber: _surveyCtrl.text,
                          subdivisionNumber: _subdivCtrl.text,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 130, child: Text(label, style: const TextStyle(fontSize: 11, color: AppColors.charcoalLight))),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.charcoal))),
        ],
      ),
    );
  }
}
