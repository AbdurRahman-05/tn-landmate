import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/l10n/translations.dart';
import '../../core/providers.dart';
import '../../shared/widgets/custom_app_bar.dart';
import '../../shared/widgets/disclaimer_banner.dart';
import '../../shared/widgets/official_source_card.dart';
import '../../shared/widgets/live_gov_extractor_sheet.dart';
import '../documents/pdf_document_center_screen.dart';

class FmbScreen extends ConsumerStatefulWidget {
  const FmbScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<FmbScreen> createState() => _FmbScreenState();
}

class _FmbScreenState extends ConsumerState<FmbScreen> {
  final TransformationController _transController = TransformationController();

  @override
  void dispose() {
    _transController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(languageProvider);

    return Scaffold(
      appBar: CustomAppBar(
        title: AppTranslations.get('fmb_sketch', lang),
        actions: [
          IconButton(
            icon: const Icon(Icons.restart_alt),
            tooltip: 'Reset Zoom',
            onPressed: () {
              _transController.value = Matrix4.identity();
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DisclaimerBanner(
              text: lang == 'ta'
                  ? 'கீழே உள்ள வரைபடம் FMB அளவீட்டு முறையை விளக்க உதவும் மாதிரி வரைபடமாகும். அதிகாரப்பூர்வ வரைபடத்தை அரசு தளத்தில் பதிவிறக்குக.'
                  : 'The sketch below is an educational schematic demonstration of FMB G-Lines and ladder offsets. Download authorized survey sketches directly from Tamil Nilam portal.',
              isDemo: true,
            ),
            const SizedBox(height: 16),

            // Pan & Zoom Cadastral Map Viewer
            Card(
              clipBehavior: Clip.antiAlias,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    color: AppColors.forestGreen,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: const [
                            Icon(Icons.pinch, color: AppColors.mutedGold, size: 18),
                            SizedBox(width: 8),
                            Text(
                              'Survey Map Viewer (Pan & Pinch to Zoom)',
                              style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text('SAMPLE SKETCH', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(
                    height: 280,
                    width: double.infinity,
                    child: InteractiveViewer(
                      transformationController: _transController,
                      minScale: 0.5,
                      maxScale: 3.5,
                      child: CustomPaint(
                        painter: _FmbCadastralPainter(),
                        child: Container(),
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(12),
                    color: AppColors.surfaceVariant,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildLegend(color: Colors.black, label: 'Boundary (புல எல்லை)'),
                        _buildLegend(color: Colors.red, label: 'G-Line (மையக்கோடு)'),
                        _buildLegend(color: Colors.blue, label: 'Offsets (ஏணி அளவுகள்)'),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Field Measurement Book Guidance
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      lang == 'ta' ? 'FMB புல வரைபடம் விளக்கம்' : 'Understanding FMB Records',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.charcoal),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      lang == 'ta'
                          ? 'புல வரைபடம் என்பது ஒரு குறிப்பிட்ட சர்வே எண்ணின் எல்லை அளவுகள், ஏணி அளவீடுகள் (Ladder Offsets) மற்றும் உட்பிரிவுகளைக் காட்டும் துல்லிய வரைபடமாகும். பத்திரத்தில் உள்ள அளவும் களத்தில் உள்ள நில அளவும் சரியாக பொருந்துகிறதா என்பதை உறுதிசெய்ய இது உதவுகிறது.'
                          : 'A Field Measurement Book sketch displays parcel boundaries, G-lines, offset ladder points, and sub-divisions. It is essential to ensure that physical land possession matches the registered legal deed.',
                      style: const TextStyle(fontSize: 12, height: 1.5, color: AppColors.charcoalLight),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),
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
                  lang == 'ta' ? 'அரசு புல வரைபட விவரம் பெறுக (Live FMB)' : 'Extract Live FMB Sketch (Native UI)',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                onPressed: () {
                  LiveGovExtractorSheet.show(
                    context: context,
                    recordType: 'fmb',
                    title: lang == 'ta' ? 'புல வரைபடம் நேரடி விவரம்' : 'Live FMB Sketch Extraction',
                  );
                },
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.forestGreen, width: 1.5),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                icon: const Icon(Icons.picture_as_pdf, color: AppColors.forestGreen),
                label: Text(
                  lang == 'ta' ? 'புல வரைபடம் பதிவிறக்கம் (PDF)' : 'Generate & Download FMB Sketch (PDF)',
                  style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.forestGreen),
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const PdfDocumentCenterScreen(initialDocType: 'fmb'),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 14),
            OfficialSourceCard(
              title: 'Download Official FMB Sketch (Tamil Nilam)',
              description: 'Extract signed cadastral boundaries directly into the mobile app UI.',
              url: 'https://eservices.tn.gov.in/eservicesnew/land/fmb.html',
              onTap: () {
                LiveGovExtractorSheet.show(
                  context: context,
                  recordType: 'fmb',
                  title: lang == 'ta' ? 'புல வரைபடம் நேரடி விவரம்' : 'Live FMB Sketch Extraction',
                );
              },
            ),
          ],
        ),
      ),
    );

  }

  Widget _buildLegend({required Color color, required String label}) {
    return Row(
      children: [
        Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.charcoal)),
      ],
    );
  }
}

// Educational Custom Painter demonstrating FMB Geometry with G-Line and Ladder Offsets
class _FmbCadastralPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final bgPaint = Paint()..color = const Color(0xFFFCFDFD);
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);

    // Grid lines for graph effect
    final gridPaint = Paint()
      ..color = const Color(0xFFE2E8F0)
      ..strokeWidth = 0.5;
    for (double x = 0; x < size.width; x += 20) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    for (double y = 0; y < size.height; y += 20) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    final cx = size.width / 2;
    final cy = size.height / 2;

    // Boundary Polygon
    final p1 = Offset(cx - 100, cy - 60);
    final p2 = Offset(cx + 80, cy - 80);
    final p3 = Offset(cx + 110, cy + 50);
    final p4 = Offset(cx - 30, cy + 90);
    final p5 = Offset(cx - 110, cy + 30);

    final boundaryPaint = Paint()
      ..color = Colors.black
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    final path = Path()
      ..moveTo(p1.dx, p1.dy)
      ..lineTo(p2.dx, p2.dy)
      ..lineTo(p3.dx, p3.dy)
      ..lineTo(p4.dx, p4.dy)
      ..lineTo(p5.dx, p5.dy)
      ..close();

    final fillPaint = Paint()..color = AppColors.forestGreen.withOpacity(0.06);
    canvas.drawPath(path, fillPaint);
    canvas.drawPath(path, boundaryPaint);

    // G-Line (Central Baseline)
    final gLinePaint = Paint()
      ..color = Colors.red
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(p1, p3, gLinePaint);

    // Ladder Offsets
    final offsetPaint = Paint()
      ..color = Colors.blue
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;

    canvas.drawLine(Offset(cx - 20, cy - 10), p5, offsetPaint);
    canvas.drawLine(Offset(cx + 20, cy + 10), p4, offsetPaint);
    canvas.drawLine(Offset(cx, cy - 70), p2, offsetPaint);

    // Boundary Corner Points
    final dotPaint = Paint()..color = AppColors.forestGreen;
    for (var p in [p1, p2, p3, p4, p5]) {
      canvas.drawCircle(p, 4, dotPaint);
    }

    // Survey Field Labels
    final textPainter = TextPainter(textDirection: TextDirection.ltr);
    
    _drawText(canvas, textPainter, '104/2B', Offset(cx - 25, cy - 25), isBold: true);
    _drawText(canvas, textPainter, 'A', Offset(p1.dx - 14, p1.dy - 10));
    _drawText(canvas, textPainter, 'B', Offset(p2.dx + 6, p2.dy - 10));
    _drawText(canvas, textPainter, 'C', Offset(p3.dx + 8, p3.dy + 4));
    _drawText(canvas, textPainter, 'D', Offset(p4.dx - 5, p4.dy + 8));
    _drawText(canvas, textPainter, 'E', Offset(p5.dx - 16, p5.dy + 4));
    _drawText(canvas, textPainter, 'G-Line (Baseline)', Offset(cx - 40, cy + 2), color: Colors.red, size: 9);
  }

  void _drawText(Canvas canvas, TextPainter tp, String text, Offset offset, {bool isBold = false, Color color = Colors.black, double size = 11}) {
    tp.text = TextSpan(
      text: text,
      style: TextStyle(color: color, fontSize: size, fontWeight: isBold ? FontWeight.bold : FontWeight.w600),
    );
    tp.layout();
    tp.paint(canvas, offset);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
