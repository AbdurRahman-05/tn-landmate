import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import '../../core/constants/app_colors.dart';
import '../../core/services/document_pdf_service.dart';

class DocumentPreviewScreen extends StatelessWidget {
  final String docType;
  final Map<String, dynamic> data;

  const DocumentPreviewScreen({
    Key? key,
    required this.docType,
    required this.data,
  }) : super(key: key);

  String _getDocName() {
    switch (docType) {
      case 'a_register':
        return 'A-Register Record';
      case 'fmb':
        return 'FMB Cadastral Sketch';
      case 'registration_valuation':
        return 'Registration Valuation';
      case 'due_diligence':
        return 'Due Diligence Dossier';
      default:
        return 'Patta / Chitta Extract';
    }
  }

  @override
  Widget build(BuildContext context) {
    final survey = (data['survey_number'] ?? data['survey_no'] ?? '104').toString();
    final subdiv = (data['subdivision_number'] ?? data['subdivision_no'] ?? '2B').toString();
    final fileName = 'TN_${docType.toUpperCase()}_Survey_${survey}_$subdiv.pdf';

    return Scaffold(
      appBar: AppBar(
        title: Text('${_getDocName()} - S.No $survey/$subdiv'),
        backgroundColor: AppColors.forestGreen,
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined),
            tooltip: 'Share Document PDF',
            onPressed: () async {
              final bytes = await DocumentPdfService.generatePdf(
                docType: docType,
                data: data,
                saveToVault: false,
              );
              await Printing.sharePdf(bytes: bytes, filename: fileName);
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Informational Tip Banner
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: Colors.green.shade50,
            child: Row(
              children: [
                const Icon(Icons.verified_outlined, size: 16, color: AppColors.forestGreen),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Document archived in Vault. Tap Print or Share below to export PDF to device.',
                    style: TextStyle(fontSize: 11, color: Colors.green.shade900, fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: PdfPreview(
              build: (format) => DocumentPdfService.generatePdf(
                docType: docType,
                data: data,
                saveToVault: true,
              ),
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
