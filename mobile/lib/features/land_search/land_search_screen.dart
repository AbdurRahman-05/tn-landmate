import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/l10n/translations.dart';
import '../../core/network/api_client.dart';
import '../../core/providers.dart';
import '../../shared/widgets/custom_app_bar.dart';
import '../../shared/widgets/disclaimer_banner.dart';
import '../../shared/widgets/official_source_card.dart';
import '../calculators/registration_calculator_screen.dart';
import '../live_portal/live_government_portal_screen.dart';

class LandSearchScreen extends ConsumerStatefulWidget {
  const LandSearchScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<LandSearchScreen> createState() => _LandSearchScreenState();
}

class _LandSearchScreenState extends ConsumerState<LandSearchScreen> {
  // Pre-loaded offline hierarchy for instant reliability
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
  final TextEditingController _surveyCtrl = TextEditingController(text: '104');
  final TextEditingController _subdivCtrl = TextEditingController(text: '2B');

  bool _loading = false;
  bool _liveConnecting = false;
  Map<String, dynamic>? _searchResult;
  Map<String, dynamic>? _liveResult;

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

  // --- Real-time Live Government Portal Extraction ---
  void _startLiveGovernmentExtraction() async {
    final survey = _surveyCtrl.text.trim();
    final subdiv = _subdivCtrl.text.trim();

    if (survey.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a Survey Number'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() {
      _liveConnecting = true;
    });

    try {
      final res = await apiClient.safePost('/land/live/session', data: {
        'district_id': _selectedDistrictId ?? 1,
        'taluk_id': _selectedTalukId ?? 1,
        'village_id': _selectedVillageId ?? 1,
        'survey_number': survey,
        'subdivision_number': subdiv.isEmpty ? '1' : subdiv,
      });

      setState(() {
        _liveConnecting = false;
      });

      if (res != null && res.statusCode == 200 && res.data != null) {
        final sessionData = res.data as Map<String, dynamic>;
        _showCaptchaDialog(sessionData);
      } else {
        // Fallback session if backend unavailable
        _showOfflineFallbackCaptcha();
      }
    } catch (e) {
      setState(() {
        _liveConnecting = false;
      });
      _showOfflineFallbackCaptcha();
    }
  }

  void _showOfflineFallbackCaptcha() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Unable to connect to live server. Please check backend connection.'),
        backgroundColor: AppColors.warning,
      ),
    );
  }

  void _showCaptchaDialog(Map<String, dynamic> sessionData) {
    String currentSessionId = sessionData['session_id'] ?? '';
    String captchaB64 = sessionData['captcha_image_base64'] ?? '';
    String portalName = sessionData['portal_name'] ?? 'TN Revenue Portal';
    bool isLivePortal = sessionData['is_live_portal'] ?? false;
    String challengeMsg = sessionData['challenge_text'] ?? 'Enter CAPTCHA Code';

    final captchaTextCtrl = TextEditingController();
    bool submitting = false;
    String? errorMessage;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (modalCtx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final lang = ref.watch(languageProvider);
            final mediaQuery = MediaQuery.of(context);

            return Padding(
              padding: EdgeInsets.only(bottom: mediaQuery.viewInsets.bottom),
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                ),
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppColors.forestGreen.withOpacity(0.12),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.verified_user, color: AppColors.forestGreen, size: 24),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                AppTranslations.get('live_captcha_title', lang),
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.charcoal),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                isLivePortal ? 'Official TN Revenue e-Services (eservices.tn.gov.in)' : portalName,
                                style: const TextStyle(fontSize: 11, color: AppColors.forestGreen, fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(modalCtx),
                        ),
                      ],
                    ),
                    const Divider(height: 24),

                    Text(
                      AppTranslations.get('live_captcha_desc', lang),
                      style: const TextStyle(fontSize: 12, color: AppColors.charcoalLight),
                    ),
                    const SizedBox(height: 16),

                    // CAPTCHA Image Box with Refresh button
                    Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.outline),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (captchaB64.isNotEmpty)
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.memory(
                                  base64Decode(captchaB64),
                                  height: 48,
                                  fit: BoxFit.contain,
                                  errorBuilder: (_, __, ___) => const Text('CAPTCHA unavailable'),
                                ),
                              ),
                            const SizedBox(width: 14),
                            IconButton(
                              icon: const Icon(Icons.refresh, color: AppColors.forestGreen),
                              tooltip: AppTranslations.get('refresh_captcha', lang),
                              onPressed: () async {
                                final refreshRes = await apiClient.safePost('/land/live/session', data: {
                                  'district_id': _selectedDistrictId ?? 1,
                                  'taluk_id': _selectedTalukId ?? 1,
                                  'village_id': _selectedVillageId ?? 1,
                                  'survey_number': _surveyCtrl.text.trim(),
                                  'subdivision_number': _subdivCtrl.text.trim(),
                                });
                                if (refreshRes != null && refreshRes.statusCode == 200) {
                                  setModalState(() {
                                    currentSessionId = refreshRes.data['session_id'];
                                    captchaB64 = refreshRes.data['captcha_image_base64'];
                                    errorMessage = null;
                                  });
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Error message if any
                    if (errorMessage != null) ...[
                      Container(
                        padding: const EdgeInsets.all(10),
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
                                errorMessage!,
                                style: const TextStyle(fontSize: 12, color: Color(0xFF991B1B)),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],

                    // Input Field
                    TextField(
                      controller: captchaTextCtrl,
                      autofocus: true,
                      textCapitalization: TextCapitalization.characters,
                      decoration: InputDecoration(
                        labelText: AppTranslations.get('enter_captcha', lang),
                        hintText: challengeMsg,
                        prefixIcon: const Icon(Icons.lock_clock_outlined, color: AppColors.forestGreen),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 18),

                    // Submit Action Button
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.forestGreen,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        icon: submitting
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : const Icon(Icons.bolt, color: AppColors.mutedGold),
                        label: Text(
                          submitting
                              ? AppTranslations.get('extracting_from_govt', lang)
                              : AppTranslations.get('verify_and_fetch', lang),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        onPressed: submitting
                            ? null
                            : () async {
                                final enteredCode = captchaTextCtrl.text.trim();
                                if (enteredCode.isEmpty) {
                                  setModalState(() {
                                    errorMessage = 'Please enter the verification code.';
                                  });
                                  return;
                                }

                                setModalState(() {
                                  submitting = true;
                                  errorMessage = null;
                                });

                                final fetchRes = await apiClient.safePost('/land/live/fetch', data: {
                                  'session_id': currentSessionId,
                                  'captcha_value': enteredCode,
                                  'district_id': _selectedDistrictId ?? 1,
                                  'taluk_id': _selectedTalukId ?? 1,
                                  'village_id': _selectedVillageId ?? 1,
                                  'survey_number': _surveyCtrl.text.trim(),
                                  'subdivision_number': _subdivCtrl.text.trim(),
                                  'district_name': _getDistrictName(),
                                  'taluk_name': _getTalukName(),
                                  'village_name': _getVillageName(),
                                });

                                if (fetchRes != null && fetchRes.statusCode == 200) {
                                  final data = fetchRes.data as Map<String, dynamic>;
                                  if (data['success'] == true && data['record'] != null) {
                                    Navigator.pop(modalCtx);
                                    setState(() {
                                      _liveResult = data;
                                      _searchResult = null; // Prioritize live result
                                    });
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Live government record extracted and verified!'),
                                        backgroundColor: AppColors.forestGreen,
                                        behavior: SnackBarBehavior.floating,
                                      ),
                                    );
                                    return;
                                  } else {
                                    setModalState(() {
                                      submitting = false;
                                      errorMessage = data['message'] ?? 'Verification failed.';
                                    });
                                    return;
                                  }
                                }

                                setModalState(() {
                                  submitting = false;
                                  errorMessage = 'Error submitting verification. Please retry.';
                                });
                              },
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // --- Standard Local Search ---
  void _performSearch() async {
    setState(() {
      _loading = true;
      _searchResult = null;
      _liveResult = null;
    });

    final response = await apiClient.safePost('/land/search', data: {
      'district_id': _selectedDistrictId,
      'taluk_id': _selectedTalukId,
      'village_id': _selectedVillageId,
      'survey_number': _surveyCtrl.text.trim(),
      'subdivision_number': _subdivCtrl.text.trim(),
    });

    if (response != null && response.statusCode == 200) {
      setState(() {
        _searchResult = response.data;
        _loading = false;
      });
      return;
    }

    // Offline / Demo Fixture fallback
    await Future.delayed(const Duration(milliseconds: 300));
    final s = _surveyCtrl.text.trim();
    final sub = _subdivCtrl.text.trim();

    if (s == '104' && sub.toUpperCase() == '2B') {
      setState(() {
        _searchResult = {
          'status': 'found',
          'is_demo': true,
          'disclaimer': 'DEMO TEST RECORD: This record is for demonstration validation. Official land title must be verified on https://eservices.tn.gov.in.',
          'official_verification_url': 'https://eservices.tn.gov.in/eservicesnew/land/chitta.html',
          'source_attribution': 'TN LandMate Development Dataset',
          'record': {
            'patta_number': '1420',
            'owner_name_en': 'K. Selvaraj & S. Meenakshi',
            'owner_name_ta': 'கே. செல்வராஜ் & எஸ். மீனாட்சி',
            'land_type': 'நத்தம் மனை (Grama Natham Residential)',
            'extent_cents': 5.51,
            'extent_sq_ft': 2400.0,
            'extent_hectares': 0.0223,
          }
        };
        _loading = false;
      });
    } else {
      setState(() {
        _searchResult = {
          'status': 'official_redirect_available',
          'is_demo': false,
          'disclaimer': 'No local cache for this survey number. You can verify this record directly on the official Tamil Nadu e-Services portal.',
          'official_verification_url': 'https://eservices.tn.gov.in/eservicesnew/land/chitta.html',
          'source_attribution': 'Department of Survey and Settlement, Government of Tamil Nadu',
          'record': null,
        };
        _loading = false;
      });
    }
  }

  void _saveToLocalProperties(Map<String, dynamic> rec) {
    final distName = _getDistrictName();
    final prop = {
      'id': 'local-${DateTime.now().millisecondsSinceEpoch}',
      'nickname': 'Survey ${_surveyCtrl.text}/${_subdivCtrl.text} ($distName)',
      'district_name': distName,
      'taluk_name': _getTalukName(),
      'village_name': _getVillageName(),
      'survey_number': _surveyCtrl.text,
      'subdivision_number': _subdivCtrl.text,
      'extent_value': rec['extent_cents'] ?? 5.0,
      'extent_unit': 'cents',
      'notes': 'Saved from Land Search (Owner: ${rec['owner_name_en']})',
      'created_at': DateTime.now().toIso8601String(),
    };
    ref.read(propertiesProvider.notifier).addProperty(prop);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Property added to personal saved portfolio'),
        duration: Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(languageProvider);
    final availableTaluks = _taluks[_selectedDistrictId] ?? [];
    final availableVillages = _villages[_selectedTalukId] ?? [];

    return Scaffold(
      appBar: CustomAppBar(
        title: AppTranslations.get('land_search', lang),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DisclaimerBanner(
              text: AppTranslations.get('official_redirect_notice', lang),
            ),
            const SizedBox(height: 16),

            // Revenue Administrative Hierarchy Selection Card
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.account_balance, color: AppColors.forestGreen, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          lang == 'ta' ? 'வருவாய் படிநிலை விவரங்கள்' : 'Revenue Administrative Hierarchy',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.charcoal),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // District Dropdown
                    _buildDropdown(
                      label: AppTranslations.get('select_district', lang),
                      value: _selectedDistrictId,
                      items: _districts.map((d) {
                        return DropdownMenuItem<int>(
                          value: d['id'] as int,
                          child: Text(lang == 'ta' ? d['name_ta'] : d['name_en']),
                        );
                      }).toList(),
                      onChanged: (val) {
                        setState(() {
                          _selectedDistrictId = val;
                          final talukList = _taluks[val] ?? [];
                          _selectedTalukId = talukList.isNotEmpty ? talukList.first['id'] : null;
                          final vList = _selectedTalukId != null ? (_villages[_selectedTalukId] ?? []) : [];
                          _selectedVillageId = vList.isNotEmpty ? vList.first['id'] : null;
                        });
                      },
                    ),
                    const SizedBox(height: 12),

                    // Taluk Dropdown
                    _buildDropdown(
                      label: AppTranslations.get('select_taluk', lang),
                      value: _selectedTalukId,
                      items: availableTaluks.map((t) {
                        return DropdownMenuItem<int>(
                          value: t['id'] as int,
                          child: Text(lang == 'ta' ? t['name_ta'] : t['name_en']),
                        );
                      }).toList(),
                      onChanged: (val) {
                        setState(() {
                          _selectedTalukId = val;
                          final vList = val != null ? (_villages[val] ?? []) : [];
                          _selectedVillageId = vList.isNotEmpty ? vList.first['id'] : null;
                        });
                      },
                    ),
                    const SizedBox(height: 12),

                    // Village Dropdown
                    _buildDropdown(
                      label: AppTranslations.get('select_village', lang),
                      value: _selectedVillageId,
                      items: availableVillages.map((v) {
                        return DropdownMenuItem<int>(
                          value: v['id'] as int,
                          child: Text(lang == 'ta' ? v['name_ta'] : v['name_en']),
                        );
                      }).toList(),
                      onChanged: (val) {
                        setState(() {
                          _selectedVillageId = val;
                        });
                      },
                    ),
                    const SizedBox(height: 16),

                    // Survey and Subdivision numbers
                    Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: TextField(
                            controller: _surveyCtrl,
                            decoration: InputDecoration(
                              labelText: AppTranslations.get('survey_no', lang),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: TextField(
                            controller: _subdivCtrl,
                            decoration: InputDecoration(
                              labelText: AppTranslations.get('subdivision_no', lang),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Primary Live Govt Extraction Button
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.forestGreen,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 2,
                        ),
                        icon: _liveConnecting
                            ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : const Icon(Icons.bolt, color: AppColors.mutedGold),
                        label: Text(
                          _liveConnecting
                              ? 'Connecting to Govt Portal...'
                              : AppTranslations.get('fetch_live_govt', lang),
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                        onPressed: (_liveConnecting || _loading) ? null : _startLiveGovernmentExtraction,
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Secondary Quick Offline Search Button
                    SizedBox(
                      width: double.infinity,
                      height: 42,
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: AppColors.outline),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        icon: _loading
                            ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                            : const Icon(Icons.search, size: 18, color: AppColors.charcoalLight),
                        label: Text(
                          AppTranslations.get('search_record', lang),
                          style: const TextStyle(fontSize: 12, color: AppColors.charcoal),
                        ),
                        onPressed: (_liveConnecting || _loading) ? null : _performSearch,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // --- 1. REAL-TIME LIVE GOVERNMENT RECORD CARD ---
            if (_liveResult != null && _liveResult!['record'] != null) ...[
              _buildLiveOfficialRecordCard(_liveResult!, lang),
            ],

            // --- 2. STANDARD SEARCH RESULTS SECTION ---
            if (_searchResult != null && _liveResult == null) ...[
              if (_searchResult!['record'] != null) ...[
                _buildStandardFoundCard(_searchResult!, lang),
              ] else ...[
                _buildRedirectCard(_searchResult!, lang),
              ],
            ],
          ],
        ),
      ),
    );
  }

  // --- Real-time Live Record Card ---
  Widget _buildLiveOfficialRecordCard(Map<String, dynamic> liveData, String lang) {
    final rec = liveData['record'] as Map<String, dynamic>;
    final refNo = liveData['official_reference_number'] ?? 'TN-GOV-LIVE';
    final fetchedAt = liveData['fetched_at'] ?? 'Just now';
    final sourcePortal = liveData['source_portal'] ?? 'eservices.tn.gov.in';

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.forestGreen, width: 2),
        boxShadow: [
          BoxShadow(
            color: AppColors.forestGreen.withOpacity(0.12),
            blurRadius: 14,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Live Government Badge Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xFFDCFCE7),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFF16A34A)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Color(0xFF16A34A),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      AppTranslations.get('live_official_badge', lang),
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF15803D),
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.bookmark_add, color: AppColors.forestGreen),
                tooltip: 'Save to My Properties',
                onPressed: () => _saveToLocalProperties(rec),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Patta and Reference
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                'Patta No: ${rec['patta_number'] ?? 'N/A'}',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: AppColors.forestGreenDark),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Ref: $refNo',
                  style: const TextStyle(fontSize: 11, color: AppColors.charcoalLight),
                  textAlign: TextAlign.end,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          Text(
            'Source: $sourcePortal ($fetchedAt)',
            style: const TextStyle(fontSize: 10, color: AppColors.charcoalLight),
          ),
          const Divider(height: 20),

          // Detailed Fields
          _buildDetailRow(
            lang == 'ta' ? 'உரிமையாளர் (தமிழ்)' : 'Owner Name (Tamil)',
            rec['owner_name_ta'] ?? '-',
          ),
          _buildDetailRow(
            lang == 'ta' ? 'உரிமையாளர் (ஆங்கிலம்)' : 'Owner Name (English)',
            rec['owner_name_en'] ?? '-',
          ),
          _buildDetailRow(
            lang == 'ta' ? 'நில வகைப்பாடு' : 'Classification',
            rec['land_type'] ?? '-',
          ),
          _buildDetailRow(
            lang == 'ta' ? 'பரப்பளவு (சென்ட்)' : 'Extent (Cents)',
            '${rec['extent_cents']} Cents (${rec['extent_sq_ft']} Sq.Ft)',
          ),
          _buildDetailRow(
            lang == 'ta' ? 'ஹெக்டேர் / ஏர்ஸ்' : 'Hectares / Ares',
            '${rec['extent_hectares']} Ha (${rec['extent_ares']} Ares)',
          ),
          const SizedBox(height: 16),

          // Action Buttons: Save & Calculate Registration Fees
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.forestGreen,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
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
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.forestGreen),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  icon: const Icon(Icons.open_in_new, size: 16, color: AppColors.forestGreen),
                  label: const Text('Official Portal', style: TextStyle(fontSize: 12, color: AppColors.forestGreen)),
                  onPressed: () {
                    final distName = _getDistrictName();
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => LiveGovernmentPortalScreen(
                          title: 'TN Revenue e-Services (Live)',
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

  // --- Standard Local/Demo Record Card ---
  Widget _buildStandardFoundCard(Map<String, dynamic> result, String lang) {
    final rec = result['record'] as Map<String, dynamic>;
    final isDemo = result['is_demo'] ?? false;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDemo ? AppColors.warning : AppColors.forestGreen,
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 3),
          )
        ],
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
                  color: isDemo ? const Color(0xFFFEF3C7) : const Color(0xFFDCFCE7),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: isDemo ? const Color(0xFFF59E0B) : const Color(0xFF10B981)),
                ),
                child: Text(
                  isDemo ? 'DEMO TEST RECORD' : 'AUTHORIZED RECORD',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: isDemo ? const Color(0xFFB45309) : const Color(0xFF15803D),
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.bookmark_add_outlined, color: AppColors.forestGreen),
                tooltip: 'Save to My Properties',
                onPressed: () => _saveToLocalProperties(rec),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Patta No: ${rec['patta_number']}',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppColors.forestGreenDark),
          ),
          const Divider(height: 16),
          _buildDetailRow(
            lang == 'ta' ? 'உரிமையாளர் பெயர் (தமிழ்)' : 'Owner Name (Tamil)',
            rec['owner_name_ta'],
          ),
          _buildDetailRow(
            lang == 'ta' ? 'உரிமையாளர் பெயர் (ஆங்கிலம்)' : 'Owner Name (English)',
            rec['owner_name_en'],
          ),
          _buildDetailRow(
            lang == 'ta' ? 'நில வகைப்பாடு' : 'Land Classification',
            rec['land_type'],
          ),
          _buildDetailRow(
            lang == 'ta' ? 'பரப்பளவு (சென்ட்)' : 'Extent (Cents)',
            '${rec['extent_cents']} Cents (${rec['extent_sq_ft']} Sq.Ft)',
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFFEF3C7),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              result['disclaimer'],
              style: const TextStyle(fontSize: 11, color: Color(0xFF92400E)),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.forestGreen),
              icon: const Icon(Icons.bolt, color: AppColors.mutedGold),
              label: Text(
                lang == 'ta' ? 'அரசு தளத்தில் நேரடி சரிபார்ப்பு (Real-time)' : 'Verify on Live Govt Portal (Real-time)',
              ),
              onPressed: () {
                final distName = _getDistrictName();
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => LiveGovernmentPortalScreen(
                      title: 'TN Revenue e-Services (Live Patta)',
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
    );
  }

  // --- Redirect Available Card ---
  Widget _buildRedirectCard(Map<String, dynamic> result, String lang) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.info_outline, color: AppColors.forestGreen),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Official Verification Required',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            result['disclaimer'],
            style: const TextStyle(fontSize: 12, color: AppColors.charcoalLight),
          ),
          const SizedBox(height: 14),
          OfficialSourceCard(
            title: 'Verify on TN Revenue e-Services',
            description: 'Input Survey Number ${_surveyCtrl.text} on the official Tamil Nadu portal.',
            url: result['official_verification_url'],
            onTap: () {
              final distName = _getDistrictName();
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => LiveGovernmentPortalScreen(
                    title: 'TN Revenue e-Services (Live)',
                    initialUrl: result['official_verification_url'],
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
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.forestGreen),
              icon: const Icon(Icons.bolt, color: AppColors.mutedGold),
              label: Text(
                lang == 'ta' ? 'அரசு போர்ட்டலை உடனடியாக திறக்கவும்' : 'Open Live Government Portal Now',
              ),
              onPressed: () {
                final distName = _getDistrictName();
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => LiveGovernmentPortalScreen(
                      title: 'TN Revenue e-Services (Live Patta)',
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
    );
  }

  Widget _buildDropdown({
    required String label,
    required int? value,
    required List<DropdownMenuItem<int>> items,
    required ValueChanged<int?> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.charcoalLight)),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.outline),
            color: Colors.white,
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<int>(
              value: value,
              isExpanded: true,
              items: items,
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 140, child: Text(label, style: const TextStyle(fontSize: 12, color: AppColors.charcoalLight))),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.charcoal))),
        ],
      ),
    );
  }
}
