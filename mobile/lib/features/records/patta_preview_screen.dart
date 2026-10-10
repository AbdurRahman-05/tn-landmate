import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import '../../core/constants/app_colors.dart';
import '../../core/services/patta_pdf_service.dart';

class PattaPreviewScreen extends StatelessWidget {
  final Map<String, dynamic> data;

  const PattaPreviewScreen({Key? key, required this.data}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final pattaNo = data['patta_number'] ?? data['patta_no'] ?? '1420';
    final surveyNo = data['survey_number'] ?? data['survey_no'] ?? '104';
    final subdivNo = data['subdivision_number'] ?? data['subdivision_no'] ?? '1';
    final fileName = 'TN_Patta_${pattaNo}_Survey_${surveyNo}_$subdivNo.pdf';

    return Scaffold(
      appBar: AppBar(
        title: Text('Patta No: $pattaNo Copy'),
        backgroundColor: AppColors.forestGreen,
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined),
            tooltip: 'Share Patta PDF',
            onPressed: () async {
              final bytes = await PattaPdfService.generatePattaPdf(data);
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
            color: Colors.green.shade50,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.verified_outlined, size: 16, color: AppColors.forestGreen),
                const SizedBox(width: 8),
                Text(
                  'Tap the Print or Share icon below to save/download PDF directly to your device',
                  style: TextStyle(fontSize: 11, color: Colors.green.shade900, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
          Expanded(
            child: PdfPreview(
              build: (format) => PattaPdfService.generatePattaPdf(data),
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
