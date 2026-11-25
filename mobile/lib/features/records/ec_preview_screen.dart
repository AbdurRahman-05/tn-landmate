import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import '../../core/services/ec_pdf_service.dart';

class EcPreviewScreen extends StatelessWidget {
  final Map<String, dynamic> data;

  const EcPreviewScreen({Key? key, required this.data}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final certNo = data['reference_id'] ?? data['certificate_no'] ?? '1420';
    final surveyNo = data['survey_number'] ?? data['survey_no'] ?? '104';
    final subdivNo = data['subdivision_number'] ?? data['subdivision_no'] ?? '1';
    final fileName = 'TN_EC_${certNo}_Survey_${surveyNo}_$subdivNo.pdf';

    const reginetMaroon = Color(0xFF7B1113);

    return Scaffold(
      appBar: AppBar(
        title: Text('Encumbrance Certificate: $surveyNo/$subdivNo'),
        backgroundColor: reginetMaroon,
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined),
            tooltip: 'Share Encumbrance PDF',
            onPressed: () async {
              final bytes = await EcPdfService.generateEcPdf(data);
              await Printing.sharePdf(bytes: bytes, filename: fileName);
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Informational Tip Bar
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(8),
            color: Colors.red.shade50,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.verified_outlined, size: 16, color: reginetMaroon),
                const SizedBox(width: 8),
                Text(
                  'Tap the Print or Share icon below to save/download PDF directly to your device',
                  style: TextStyle(fontSize: 11, color: Colors.red.shade900, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
          Expanded(
            child: PdfPreview(
              build: (format) => EcPdfService.generateEcPdf(data),
              canChangeOrientation: false,
              canChangePageFormat: false,
              pdfFileName: fileName,
              allowPrinting: true,
              allowSharing: true,
              canDebug: false,
              previewPageMargin: const EdgeInsets.all(12),
            ),
          ),
        ],
      ),
    );
  }
}
