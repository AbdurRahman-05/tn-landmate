import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/l10n/translations.dart';
import '../../core/network/api_client.dart';
import '../../core/providers.dart';
import '../../shared/widgets/custom_app_bar.dart';
import '../../shared/widgets/disclaimer_banner.dart';

class AIAssistantScreen extends ConsumerStatefulWidget {
  const AIAssistantScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<AIAssistantScreen> createState() => _AIAssistantScreenState();
}

class _AIAssistantScreenState extends ConsumerState<AIAssistantScreen> {
  final TextEditingController _queryCtrl = TextEditingController();
  final List<Map<String, String>> _messages = [
    {
      'role': 'assistant',
      'text': 'வணக்கம்! நான் TN LandMate AI உதவியாளர். தமிழ்நாடு பட்டா, சிட்டா, FMB வரைபடம், வில்லங்கச் சான்றிதழ் (EC) மற்றும் நில அளவீடு சம்பந்தமான கேள்விகளுக்கு உதவ முடியும்.'
    }
  ];
  bool _loading = false;

  void _sendQuery(String text) async {
    if (text.trim().isEmpty) return;
    final lang = ref.read(languageProvider);
    _queryCtrl.clear();

    setState(() {
      _messages.add({'role': 'user', 'text': text});
      _loading = true;
    });

    final res = await apiClient.safePost('/ai/ask', data: {
      'query': text,
      'language': lang,
    });

    if (res != null && res.statusCode == 200) {
      final answer = res.data['response'] as String;
      setState(() {
        _messages.add({'role': 'assistant', 'text': answer});
        _loading = false;
      });
      return;
    }

    // Offline domain response fallback
    await Future.delayed(const Duration(milliseconds: 300));
    String fallbackAns;
    final q = text.toLowerCase();
    if (q.contains('patta') || q.contains('பட்டா')) {
      fallbackAns = lang == 'ta'
          ? 'பட்டா என்பது வட்டாட்சியரால் வழங்கப்படும் முதன்மை நில உரிமை ஆவணமாகும். இதில் உரிமையாளர் பெயர், புல எண் மற்றும் பரப்பளவு இருக்கும்.'
          : 'A Patta is a primary land revenue title document issued by the Tahsildar in Tamil Nadu containing the owner\'s name, survey parcel, and extent.';
    } else if (q.contains('fmb') || q.contains('வரைபடம்')) {
      fallbackAns = lang == 'ta'
          ? 'புல வரைபடம் (FMB) என்பது நிலத்தின் எல்லை அளவுகள் மற்றும் ஏணி அளவீடுகளைக் காட்டும் வரைபடம்.'
          : 'FMB (Field Measurement Book) is the cadastral map showing boundary measurements, baseline G-lines, and ladder offset points.';
    } else if (q.contains('ec') || q.contains('வில்லங்கம்')) {
      fallbackAns = lang == 'ta'
          ? 'வில்லங்கச் சான்றிதழ் (EC) என்பது சொத்தின் மீது கடந்த 30+ ஆண்டுகளில் நடந்த பத்திரப் பதிவுகள், வங்கி அடமானங்கள் ஆகியவற்றை சரிபார்க்க உதவும்.'
          : 'Encumbrance Certificate (EC) reflects all registered deeds, mortgages, and release deeds over a given period (recommended: 30+ years).';
    } else {
      fallbackAns = lang == 'ta'
          ? 'நிலம் வாங்குமுன்: 1) பட்டா பெயரிலுள்ளதா, 2) 30 ஆண்டுகால EC வில்லங்கம் உள்ளதா, 3) FMB வரைபடத்தோடு கள அளவீடு பொருந்துகிறதா என்பதை சரிபார்க்கவும்.'
          : 'Essential checks: 1) Verified Patta title, 2) 30-year Encumbrance Certificate (EC) on TNREGINET, 3) FMB physical boundary match, 4) Confirming land is not Poramboke in A-Register.';
    }

    setState(() {
      _messages.add({'role': 'assistant', 'text': fallbackAns});
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(languageProvider);

    return Scaffold(
      appBar: CustomAppBar(
        title: AppTranslations.get('ai_assistant', lang),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: DisclaimerBanner(
              text: lang == 'ta'
                  ? 'AI உதவியாளரின் பதில்கள் பொது வழிகாட்டுதலுக்கே. இது சட்டரீதியான சரிபார்ப்பாகவோ வழக்கறிஞர் ஆலோசனையாகவோ கருதப்படக் கூடாது.'
                  : 'AI Assistant answers are educational only. They do not constitute legal title verification or professional survey certification.',
            ),
          ),

          // Suggested Query Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                _buildQuickChip(lang == 'ta' ? 'பட்டா vs சிட்டா?' : 'Patta vs Chitta?'),
                _buildQuickChip(lang == 'ta' ? 'FMB வரைபடம் என்றால் என்ன?' : 'What is FMB?'),
                _buildQuickChip(lang == 'ta' ? 'வில்லங்கம் பார்ப்பது எப்படி?' : 'How to check EC?'),
                _buildQuickChip(lang == 'ta' ? 'புறம்போக்கு நிலம் என்றால் என்ன?' : 'What is Poramboke?'),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // Chat Messages
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final m = _messages[index];
                final isUser = m['role'] == 'user';

                return Align(
                  alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.82),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: isUser ? AppColors.forestGreen : Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: isUser ? AppColors.forestGreen : AppColors.outline),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.02),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        )
                      ],
                    ),
                    child: Text(
                      m['text'] ?? '',
                      style: TextStyle(
                        fontSize: 13,
                        height: 1.4,
                        color: isUser ? Colors.white : AppColors.charcoal,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          if (_loading)
            const Padding(
              padding: EdgeInsets.all(8),
              child: SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.forestGreen),
              ),
            ),

          // Query Input Field
          Container(
            padding: const EdgeInsets.all(12),
            color: Colors.white,
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _queryCtrl,
                      decoration: InputDecoration(
                        hintText: lang == 'ta' ? 'நில ஆவணங்கள் பற்றி கேட்கவும்...' : 'Ask about land records or terms...',
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      ),
                      onSubmitted: _sendQuery,
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.send_rounded, color: AppColors.forestGreen),
                    onPressed: () => _sendQuery(_queryCtrl.text),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickChip(String label) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ActionChip(
        label: Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
        backgroundColor: Colors.white,
        side: const BorderSide(color: AppColors.outline),
        onPressed: () => _sendQuery(label),
      ),
    );
  }
}
