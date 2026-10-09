import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/l10n/translations.dart';
import '../../core/providers.dart';
import '../../shared/widgets/custom_app_bar.dart';
import '../../shared/widgets/disclaimer_banner.dart';
import 'document_guide_detail_screen.dart';

class DocumentGuideListScreen extends ConsumerWidget {
  const DocumentGuideListScreen({Key? key}) : super(key: key);

  static const List<Map<String, dynamic>> guidesData = [
    {
      'slug': 'patta-chitta',
      'title_en': 'Patta & Chitta',
      'title_ta': 'பட்டா மற்றும் சிட்டா',
      'desc_en': 'Primary revenue ownership and land tax assessment record.',
      'desc_ta': 'முதன்மை வருவாய் உரிமை மற்றும் நிலவரி மதிப்பீட்டு ஆவணம்.',
      'icon': Icons.description_outlined,
      'color': Color(0xFF1B4D3E),
      'what_en': 'A Patta is a legal revenue record issued by the Tahsildar establishing that a particular parcel of land is registered under the holder\'s name. Chitta indicates the land type (Wet or Dry) and revenue assessment.',
      'what_ta': 'பட்டா என்பது வட்டாட்சியரால் வழங்கப்படும் முதன்மை நில உரிமை ஆவணமாகும். சிட்டா என்பது நன்செய் அல்லது புன்செய் வகைப்பாடு மற்றும் வரி மதிப்பீட்டைக் குறிக்கும்.',
      'why_en': 'Without a Patta in your name, you cannot prove lawful revenue possession in Tamil Nadu or apply for bank mortgages and building plan permissions.',
      'why_ta': 'பட்டா இல்லாவிட்டால் வருவாய்த்துறை ஆவணங்களில் உரிமை கோர முடியாது. வங்கி கடன் மற்றும் கட்டிட அனுமதிக்கு இது கட்டாயம்.',
      'checklist_en': [
        'Patta Number matches Taluk registers',
        'Owner Name spelling matches Sale Deed',
        'Survey & Subdivision match FMB sketch',
        'Land type (Natham vs Poramboke) confirmed'
      ],
      'checklist_ta': [
        'பட்டா எண் வட்டாட்சியர் பதிவேட்டில் பொருந்துகிறது',
        'உரிமையாளர் பெயர் பத்திரத்தில் உள்ளபடி உள்ளது',
        'புல எண் மற்றும் உட்பிரிவு FMB வரைபடத்துடன் பொருந்துகிறது',
        'நில வகைப்பாடு நத்தம்/புன்செய் என உறுதி செய்யப்பட்டது'
      ],
      'url': 'https://eservices.tn.gov.in/eservicesnew/land/chitta.html',
    },
    {
      'slug': 'a-register',
      'title_en': 'A-Register (Village Permanent Registry)',
      'title_ta': 'அ-பதிவேடு (கிராம நிரந்தர நிலப் பதிவேடு)',
      'desc_en': 'Permanent record of tenure, soil classification, and public reservations.',
      'desc_ta': 'நிலத்தின் தரம், வகைப்பாடு மற்றும் புறம்போக்கு விவரங்கள் கொண்ட முதன்மை பதிவேடு.',
      'icon': Icons.menu_book_outlined,
      'color': Color(0xFF3B82F6),
      'what_en': 'The master permanent land registry maintained by the Village Administrative Officer (VAO). Contains soil classification, rate per acre, and whether the land is private Ryotwari or government-held.',
      'what_ta': 'கிராம நிர்வாக அலுவலரால் (VAO) பராமரிக்கப்படும் முதன்மை நிலப் பதிவேடு. இதில் மண் தரம், ராயத்துவாரி அல்லது அரசு புறம்போக்கு வகைப்பாடு பதிவாகி இருக்கும்.',
      'why_en': 'Critical to verify that the property you are purchasing is not classified as Government Poramboke, grazing land, or water catchment.',
      'why_ta': 'நீங்கள் வாங்கும் நிலம் அரசு புறம்போக்கு, மேய்ச்சல் நிலம் அல்லது நீர்நிலையா என அறிய இது மிக அவசியம்.',
      'checklist_en': [
        'Tenure marked as Ryotwari (Private)',
        'No Poramboke or Temple reservation recorded',
        'Old Survey Number matches deed chain',
      ],
      'checklist_ta': [
        'ராயத்துவாரி (தனியார் உரிமை) என குறிப்பிடப்பட்டுள்ளது',
        'புறம்போக்கு அல்லது கோயில் நிலம் இல்லை',
        'பழைய புல எண் பத்திர வரலாற்றோடு பொருந்துகிறது',
      ],
      'url': 'https://eservices.tn.gov.in/eservicesnew/land/areg.html',
    },
    {
      'slug': 'fmb',
      'title_en': 'Field Measurement Book (FMB)',
      'title_ta': 'புல வரைபடம் (FMB)',
      'desc_en': 'Cadastral parcel map showing precise physical boundaries and ladder offsets.',
      'desc_ta': 'நிலத்தின் உண்மையான எல்லைகள் மற்றும் ஏணி அளவீடுகள் கொண்ட துல்லிய வரைபடம்.',
      'icon': Icons.map_outlined,
      'color': Color(0xFF8B5CF6),
      'what_en': 'A compilation of survey sketches displaying individual field dimensions, G-lines, offset ladder points, and neighbor parcel references.',
      'what_ta': 'நிலத்தின் எல்லை அளவுகள், ஏணி அளவீடுகள் மற்றும் உட்பிரிவுகளைக் காட்டும் துல்லிய வரைபடம்.',
      'why_en': 'FMB prevents boundary encroachment disputes and confirms whether physical fenced boundary matches registered deed dimensions.',
      'why_ta': 'பத்திரத்தில் உள்ள பரப்பளவும் களத்தில் உள்ள நில அளவும் சரியாக பொருந்துகிறதா என்பதை உறுதிசெய்ய உதவுகிறது.',
      'checklist_en': [
        'All boundary sides match deed measurements',
        'G-Line baseline geometry verified',
        'Subdivision split officially reflected',
      ],
      'checklist_ta': [
        'அனைத்து எல்லை அளவுகளும் பத்திர அளவுகளோடு ஒத்துப்போகிறது',
        'G-Line மையக்கோடு அளவீடு சரிபார்க்கப்பட்டது',
        'உட்பிரிவு முறைப்படி அங்கீகரிக்கப்பட்டுள்ளது',
      ],
      'url': 'https://eservices.tn.gov.in/eservicesnew/land/fmb.html',
    },
    {
      'slug': 'encumbrance-certificate',
      'title_en': 'Encumbrance Certificate (EC)',
      'title_ta': 'வில்லங்கச் சான்றிதழ் (EC)',
      'desc_en': 'Record of registered sales, mortgages, court orders, and releases.',
      'desc_ta': 'சொத்தின் மீதான கடந்தகால கிரையம், அடமானம் மற்றும் வில்லங்கங்களின் வரலாறு.',
      'icon': Icons.verified_outlined,
      'color': Color(0xFF0D9488),
      'what_en': 'A certified extract from the Sub-Registrar Office listing every registered deed, bank hypothecation, and legal transfer for the past 30+ years.',
      'what_ta': 'சார்பதிவாளர் அலுவலகத்தில் கடந்த 30+ ஆண்டுகளில் அந்த சொத்தின் மீது பதிவு செய்யப்பட்ட அனைத்து பத்திரப் பதிவுகளின் வரலாறு.',
      'why_en': 'Verifies that the seller has clear marketable title without outstanding mortgages or prior conflicting sales.',
      'why_ta': 'விற்பனையாளருக்கு முழுமையான உரிமை உள்ளதா மற்றும் நிலுவையில் உள்ள வங்கி அடமானங்கள் இல்லை என்பதை உறுதிசெய்ய வேண்டும்.',
      'checklist_en': [
        'Continuous 30-year search history conducted',
        'No active un-cancelled mortgages',
        'Survey number and extent correctly cited',
      ],
      'checklist_ta': [
        'தொடர்ச்சியான 30 ஆண்டுகால வில்லங்கம் எடுக்கப்பட்டது',
        'முடிவுறாத வங்கி அடமானங்கள் எதுவும் இல்லை',
        'புல எண் மற்றும் பரப்பு சரியாகப் பொருந்துகிறது',
      ],
      'url': 'https://tnreginet.gov.in',
    },
    {
      'slug': 'sale-deed',
      'title_en': 'Sale Deed & Parent Documents',
      'title_ta': 'கிரையப் பத்திரம் & மூல ஆவணங்கள்',
      'desc_en': 'The principal title transfer deed establishing legal ownership.',
      'desc_ta': 'சொத்து உரிமையை முழுமையாக மாற்றும் முதன்மை சட்டப் பத்திரம்.',
      'icon': Icons.feed_outlined,
      'color': Color(0xFFC85A32),
      'what_en': 'The executed and registered deed conveying ownership from seller to buyer for consideration. Includes description of four boundaries.',
      'what_ta': 'விற்பனையாளரிடமிருந்து வாங்குபவருக்கு உரிமையை மாற்றும் பதிவு செய்யப்பட்ட முதன்மை பத்திரம்.',
      'why_en': 'Establishes absolute ownership chain. Buyer must trace uninterrupted ownership through parent deeds for at least 30 uninterrupted years.',
      'why_ta': 'சொத்தின் தொடர்ச்சியான 30 ஆண்டுகால உரிமைச் சங்கிலியை உறுதிசெய்ய மூல ஆவணங்கள் அவசியம்.',
      'checklist_en': [
        'Four boundary descriptions (North, South, East, West) clear',
        'Registered with Sub-Registrar seal & stamp',
        'Chain of parent title deeds complete',
      ],
      'checklist_ta': [
        'நான்கு எல்லை விவரங்கள் தெளிவாக உள்ளன',
        'சார்பதிவாளர் முத்திரையுடன் பதிவு செய்யப்பட்டுள்ளது',
        '30 ஆண்டுகால மூல ஆவணங்களின் தொடர்ச்சி உள்ளது',
      ],
      'url': 'https://tnreginet.gov.in',
    },
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lang = ref.watch(languageProvider);

    return Scaffold(
      appBar: CustomAppBar(
        title: AppTranslations.get('doc_guides', lang),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DisclaimerBanner(
              text: lang == 'ta'
                  ? 'இக்கையேடுகள் பொதுமக்களுக்கான விழிப்புணர்வு வழிகாட்டியே. சொத்து பரிவர்த்தனைகளுக்கு வழக்கறிஞரின் சட்ட ஆலோசனையைப் பெறவும்.'
                  : 'Document guides are for educational awareness only and do not constitute legal advice. Always obtain a formal title opinion from an advocate.',
            ),
            const SizedBox(height: 16),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: guidesData.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final item = guidesData[index];
                final title = lang == 'ta' ? item['title_ta'] : item['title_en'];
                final desc = lang == 'ta' ? item['desc_ta'] : item['desc_en'];
                final icon = item['icon'] as IconData;
                final color = item['color'] as Color;

                return Card(
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    leading: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(icon, color: color, size: 24),
                    ),
                    title: Text(
                      title,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        desc,
                        style: const TextStyle(fontSize: 12, color: AppColors.charcoalLight),
                      ),
                    ),
                    trailing: const Icon(Icons.chevron_right, size: 20),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => DocumentGuideDetailScreen(guide: item),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
