import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:printing/printing.dart';
import '../../core/constants/app_colors.dart';
import '../../core/l10n/translations.dart';
import '../../core/providers.dart';
import '../../core/services/document_pdf_service.dart';
import '../../core/services/document_vault_service.dart';
import '../../shared/widgets/custom_app_bar.dart';

class DocumentVaultScreen extends ConsumerStatefulWidget {
  const DocumentVaultScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<DocumentVaultScreen> createState() => _DocumentVaultScreenState();
}

class _DocumentVaultScreenState extends ConsumerState<DocumentVaultScreen> {
  List<Map<String, dynamic>> _documents = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadDocuments();
  }

  Future<void> _loadDocuments() async {
    setState(() => _loading = true);
    final docs = await DocumentVaultService.getDocuments();
    if (!mounted) return;
    setState(() {
      _documents = docs;
      _loading = false;
    });
  }

  Future<void> _deleteDoc(String refId) async {
    await DocumentVaultService.deleteDocument(refId);
    _loadDocuments();
  }

  Color _getBadgeColor(String docType) {
    switch (docType) {
      case 'a_register':
        return const Color(0xFF2563EB);
      case 'fmb':
        return const Color(0xFF7C3AED);
      case 'registration_valuation':
        return const Color(0xFFD97706);
      case 'due_diligence':
        return const Color(0xFFDC2626);
      default:
        return const Color(0xFF15803D);
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(languageProvider);

    return Scaffold(
      appBar: CustomAppBar(
        title: lang == 'ta' ? 'பதிவிறக்கிய ஆவணங்கள்' : 'Document Vault & History',
        actions: [
          if (_documents.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep_outlined),
              tooltip: 'Clear Vault',
              onPressed: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Clear All Documents?'),
                    content: const Text('Are you sure you want to remove all saved document history from the vault?'),
                    actions: [
                      TextButton(child: const Text('Cancel'), onPressed: () => Navigator.pop(ctx, false)),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
                        child: const Text('Clear All'),
                        onPressed: () => Navigator.pop(ctx, true),
                      ),
                    ],
                  ),
                );
                if (confirm == true) {
                  await DocumentVaultService.clearVault();
                  _loadDocuments();
                }
              },
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _documents.isEmpty
              ? _buildEmptyState(lang)
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _documents.length,
                  itemBuilder: (context, index) {
                    final doc = _documents[index];
                    final raw = Map<String, dynamic>.from(doc['raw_data'] ?? {});
                    final docType = doc['doc_type'] ?? 'patta_chitta';
                    final badgeColor = _getBadgeColor(docType);
                    final refId = doc['reference_id'] ?? '';
                    final sizeKb = ((doc['file_size_bytes'] ?? 45000) / 1024).toStringAsFixed(1);
                    final date = (doc['generated_at'] ?? '').toString().split('T').first;

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 1.5,
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Type Badge & Actions
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: badgeColor.withOpacity(0.12),
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(color: badgeColor.withOpacity(0.3)),
                                  ),
                                  child: Text(
                                    doc['doc_title'] ?? 'Land Record',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: badgeColor,
                                    ),
                                  ),
                                ),
                                const Spacer(),
                                Text(
                                  date,
                                  style: const TextStyle(fontSize: 10, color: AppColors.charcoalLight),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline, size: 18, color: AppColors.charcoalLight),
                                  tooltip: 'Delete',
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                  onPressed: () => _deleteDoc(refId),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),

                            // Survey & Parcel Details
                            Row(
                              children: [
                                const Icon(Icons.location_on_outlined, size: 16, color: AppColors.forestGreen),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    '${doc['district']} • ${doc['taluk']} • ${doc['village']}',
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Survey Parcel: ${doc['survey_number']} / ${doc['subdivision_number']} | Size: $sizeKb KB | Ref: $refId',
                              style: const TextStyle(fontSize: 11, color: AppColors.charcoalLight),
                            ),
                            const Divider(height: 16),

                            // Action Buttons
                            Row(
                              children: [
                                Expanded(
                                  child: ElevatedButton.icon(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.forestGreen,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                      padding: const EdgeInsets.symmetric(vertical: 8),
                                    ),
                                    icon: const Icon(Icons.visibility_outlined, size: 15),
                                    label: const Text('View / Print', style: TextStyle(fontSize: 11)),
                                    onPressed: () {
                                      DocumentPdfService.previewAndDownload(
                                        context: context,
                                        docType: docType,
                                        data: raw,
                                      );
                                    },
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: OutlinedButton.icon(
                                    style: OutlinedButton.styleFrom(
                                      side: const BorderSide(color: AppColors.forestGreen),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                      padding: const EdgeInsets.symmetric(vertical: 8),
                                    ),
                                    icon: const Icon(Icons.share_outlined, size: 15, color: AppColors.forestGreen),
                                    label: const Text('Share PDF', style: TextStyle(fontSize: 11, color: AppColors.forestGreen)),
                                    onPressed: () async {
                                      final bytes = await DocumentPdfService.generatePdf(
                                        docType: docType,
                                        data: raw,
                                        saveToVault: false,
                                      );
                                      await Printing.sharePdf(
                                        bytes: bytes,
                                        filename: 'TN_${docType.toUpperCase()}_${doc['survey_number']}.pdf',
                                      );
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }

  Widget _buildEmptyState(String lang) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.forestGreen.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.folder_open_outlined, size: 48, color: AppColors.forestGreen),
            ),
            const SizedBox(height: 16),
            Text(
              lang == 'ta' ? 'பதிவிறக்கிய ஆவணங்கள் எதுவும் இல்லை' : 'No Vault Documents Yet',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(
              lang == 'ta'
                  ? 'நீங்கள் உருவாக்கும் அல்லது பதிவிறக்கும் அனைத்து பட்டா, அ-பதிவேடு, FMB ஆவணங்கள் ஆஃப்லைனில் இங்கே சேமிக்கப்படும்.'
                  : 'Every Patta, A-Register, and FMB report you generate or download is automatically archived here for 100% offline access.',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12, color: AppColors.charcoalLight, height: 1.4),
            ),
          ],
        ),
      ),
    );
  }
}
