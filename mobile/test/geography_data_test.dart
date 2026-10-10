import 'package:flutter_test/flutter_test.dart';
import 'package:tn_landmate/core/data/tn_geography_data.dart';

void main() {
  test('TnGeographyData contains all 38 districts of Tamil Nadu', () {
    final districts = TnGeographyData.districts;
    expect(districts.length, equals(38));

    // Verify key districts exist
    final chennai = districts.firstWhere((d) => d['name_en'] == 'Chennai');
    expect(chennai['id'], equals(1));
    expect(chennai['name_ta'], equals('சென்னை'));

    final madurai = districts.firstWhere((d) => d['name_en'] == 'Madurai');
    expect(madurai['name_ta'], equals('மதுரை'));
  });

  test('TnGeographyData contains taluks for all 38 districts', () {
    // Check Chennai taluks
    final chennaiTaluks = TnGeographyData.getTaluksForDistrict(1);
    expect(chennaiTaluks.isNotEmpty, isTrue);
    expect(chennaiTaluks.any((t) => t['name_en'] == 'Ambattur'), isTrue);
    expect(chennaiTaluks.any((t) => t['name_en'] == 'Mylapore'), isTrue);

    // Verify all 38 districts have at least one taluk
    for (int i = 1; i <= 38; i++) {
      final taluks = TnGeographyData.getTaluksForDistrict(i);
      expect(taluks.isNotEmpty, isTrue, reason: 'District $i has no taluks');
    }
  });

  test('TnGeographyData contains revenue villages for taluks', () {
    final chennaiTaluks = TnGeographyData.getTaluksForDistrict(1);
    final ambattur = chennaiTaluks.firstWhere((t) => t['name_en'] == 'Ambattur');
    final ambatturVillages = TnGeographyData.getVillagesForTaluk(ambattur['id'] as int);

    expect(ambatturVillages.isNotEmpty, isTrue);
    expect(ambatturVillages.any((v) => v['name_en'] == 'Ambattur'), isTrue);
  });

  test('TnGeographyData name resolution works in English and Tamil', () {
    expect(TnGeographyData.getDistrictName(1, 'en'), equals('Chennai'));
    expect(TnGeographyData.getDistrictName(1, 'ta'), equals('சென்னை'));

    final taluks = TnGeographyData.getTaluksForDistrict(1);
    final ambattur = taluks.firstWhere((t) => t['name_en'] == 'Ambattur');
    final tId = ambattur['id'] as int;

    expect(TnGeographyData.getTalukName(1, tId, 'en'), equals('Ambattur'));
    expect(TnGeographyData.getTalukName(1, tId, 'ta'), equals('அம்பத்தூர்'));
  });
}
