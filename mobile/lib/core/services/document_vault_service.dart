import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class DocumentVaultService {
  static const String _vaultKey = 'local_pdf_document_vault';

  /// Save a newly generated document record in the local vault
  static Future<void> saveDocument({
    required String referenceId,
    required String docType,
    required String docTitle,
    required String district,
    required String taluk,
    required String village,
    required String surveyNumber,
    required String subdivisionNumber,
    required int fileSizeBytes,
    required Map<String, dynamic> rawData,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final list = await getDocuments();

    // Check if already in vault to avoid duplicate reference IDs
    list.removeWhere((item) => item['reference_id'] == referenceId);

    final item = {
      'reference_id': referenceId,
      'doc_type': docType,
      'doc_title': docTitle,
      'district': district,
      'taluk': taluk,
      'village': village,
      'survey_number': surveyNumber,
      'subdivision_number': subdivisionNumber,
      'file_size_bytes': fileSizeBytes,
      'generated_at': DateTime.now().toIso8601String(),
      'raw_data': rawData,
    };

    list.insert(0, item);

    // Keep up to 50 most recent documents
    if (list.length > 50) {
      list.removeLast();
    }

    await prefs.setString(_vaultKey, jsonEncode(list));
  }

  /// Retrieve all generated documents from the local vault
  static Future<List<Map<String, dynamic>>> getDocuments() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_vaultKey);
    if (raw == null || raw.isEmpty) return [];

    try {
      final List decoded = jsonDecode(raw);
      return decoded.map((e) => Map<String, dynamic>.from(e)).toList();
    } catch (_) {
      return [];
    }
  }

  /// Delete a document by its reference ID
  static Future<void> deleteDocument(String referenceId) async {
    final prefs = await SharedPreferences.getInstance();
    final list = await getDocuments();
    list.removeWhere((item) => item['reference_id'] == referenceId);
    await prefs.setString(_vaultKey, jsonEncode(list));
  }

  /// Clear the entire vault
  static Future<void> clearVault() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_vaultKey);
  }
}
