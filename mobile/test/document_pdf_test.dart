import 'package:flutter_test/flutter_test.dart';
import 'package:tn_landmate/core/services/document_pdf_service.dart';
import 'package:tn_landmate/core/services/document_vault_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('End-to-End PDF Generation & Vault Tests', () {
    final sampleData = {
      'district_name': 'Chennai',
      'taluk_name': 'Ambattur',
      'village_name': 'Ambattur',
      'survey_number': '104',
      'subdivision_number': '2B',
      'patta_number': '1420',
      'owner_name_en': 'K. Ramanathan',
      'owner_name_ta': 'கே. ராமநாதன்',
      'classification': 'ரயத்துவாரி மனை',
      'extent_cents': 5.51,
      'extent_sq_ft': '2400',
      'reference_id': 'TN-TEST-9999',
    };

    test('generates valid patta_chitta PDF bytes', () async {
      final bytes = await DocumentPdfService.generatePdf(
        docType: 'patta_chitta',
        data: sampleData,
        saveToVault: true,
      );
      expect(bytes, isNotEmpty);
      expect(bytes.length, greaterThan(1000));
    });

    test('generates valid a_register PDF bytes', () async {
      final bytes = await DocumentPdfService.generatePdf(
        docType: 'a_register',
        data: sampleData,
        saveToVault: false,
      );
      expect(bytes, isNotEmpty);
      expect(bytes.length, greaterThan(1000));
    });

    test('generates valid fmb cadastral sketch PDF bytes', () async {
      final bytes = await DocumentPdfService.generatePdf(
        docType: 'fmb',
        data: sampleData,
        saveToVault: false,
      );
      expect(bytes, isNotEmpty);
      expect(bytes.length, greaterThan(1000));
    });

    test('generates valid registration_valuation PDF bytes', () async {
      final bytes = await DocumentPdfService.generatePdf(
        docType: 'registration_valuation',
        data: {
          ...sampleData,
          'market_value': '3000000',
          'stamp_duty_amount': '210000',
          'registration_fee_amount': '60000',
        },
        saveToVault: false,
      );
      expect(bytes, isNotEmpty);
      expect(bytes.length, greaterThan(1000));
    });

    test('generates valid due_diligence dossier PDF bytes', () async {
      final bytes = await DocumentPdfService.generatePdf(
        docType: 'due_diligence',
        data: sampleData,
        saveToVault: false,
      );
      expect(bytes, isNotEmpty);
      expect(bytes.length, greaterThan(1000));
    });

    test('DocumentVaultService stores and retrieves saved PDFs', () async {
      await DocumentVaultService.saveDocument(
        referenceId: 'VAULT-001',
        docType: 'patta_chitta',
        docTitle: 'Patta Extract',
        district: 'Chennai',
        taluk: 'Ambattur',
        village: 'Ambattur',
        surveyNumber: '104',
        subdivisionNumber: '2B',
        fileSizeBytes: 24500,
        rawData: sampleData,
      );

      final list = await DocumentVaultService.getDocuments();
      expect(list.length, 1);
      expect(list.first['reference_id'], 'VAULT-001');
      expect(list.first['survey_number'], '104');

      await DocumentVaultService.deleteDocument('VAULT-001');

      final updatedList = await DocumentVaultService.getDocuments();
      expect(updatedList.isEmpty, isTrue);
    });
  });
}
