import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:tn_landmate/core/services/patta_pdf_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('PattaPdfService generates valid non-empty PDF document bytes', () async {
    final record = {
      'district_name': 'Chennai',
      'taluk_name': 'Ambattur',
      'village_name': 'Ambattur',
      'survey_number': '104',
      'subdivision_number': '2B',
      'patta_number': '1420',
      'owner_name_en': 'R. Selvam',
      'owner_name_ta': 'ஆர். செல்வம்',
      'father_husband_name': 'K. Ramasamy / கே. ராமசாமி',
      'land_type': 'நன்செய் (Wet Land)',
      'extent_cents': 5.51,
      'extent_sq_ft': '2400',
      'extent_hectares': '0.022',
      'extent_ares': '2.23',
      'reference_id': 'TN-REV-2026-TEST1234',
      'issue_date': '2026-10-10 16:50:00',
      'tax_assessment': '₹ 18.50 / Year',
    };

    final Uint8List pdfBytes = await PattaPdfService.generatePattaPdf(record);

    expect(pdfBytes, isNotNull);
    expect(pdfBytes.isNotEmpty, isTrue);
    // PDF header magic bytes are %PDF- (0x25, 0x50, 0x44, 0x46, 0x2D)
    expect(pdfBytes.length, greaterThan(500));
    final header = String.fromCharCodes(pdfBytes.sublist(0, 5));
    expect(header, equals('%PDF-'));
  });
}
