import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:tn_landmate/core/services/chitta_pdf_service.dart';
import 'package:tn_landmate/core/services/gov_portal_bridge.dart';

void main() {
  testWidgets('builds a multi-page Chitta PDF from portal tables (Tamil + wide table)', (tester) async {
    final ownerRows = [
      ['வ.எண் / S.No', 'உரிமையாளர் பெயர் / Owner', 'தந்தை / Father', 'புல எண் / Survey', 'உட்பிரிவு', 'பரப்பு (ஹெ-ஏர்)', 'தீர்வை'],
      for (var i = 1; i <= 120; i++)
        ['$i', 'முருகன் $i Murugan', 'ராமசாமி Ramasamy', '100', '1A2A1', '0.${i % 9}5.50', '₹ ${i * 3}.25'],
    ];
    final result = PortalResult(
      html: '<html></html>',
      url: 'https://eservices.tn.gov.in/eservicesnew/land/chittaExtract_en.html',
      text: 'Chitta',
      fetchedAt: DateTime(2026, 11, 26, 10, 30),
      tables: [
        [
          ['மாவட்டம் / District', 'Chennai'],
          ['வட்டம் / Taluk', 'Madhavaram'],
          ['பட்டா எண் / Patta No', '1234'],
        ],
        ownerRows,
      ],
    );

    late List<int> bytes;
    await tester.runAsync(() async {
      bytes = await ChittaPdfService.build(
        result: result,
        title: 'Patta / Chitta',
        details: const [
          MapEntry('District', 'Chennai'),
          MapEntry('Survey No / Subdivision', '100 / 1A2A1'),
        ],
      );
    });

    expect(ascii.decode(bytes.sublist(0, 4)), '%PDF');
    // 120 rows cannot fit on one A4 page → several pages.
    final pageCount = RegExp(r'/Type\s*/Page[^s]').allMatches(latin1.decode(bytes)).length;
    expect(pageCount, greaterThan(1));
  });
}
