import 'package:flutter_test/flutter_test.dart';
import 'package:tn_landmate/core/constants/land_units.dart';

void main() {
  group('Tamil Nadu Land Units Conversion Tests', () {
    test('1 Cent must equal 435.6 Square Feet', () {
      final res = LandUnits.convertAll(1.0, 'cents');
      expect(res['square_feet'], closeTo(435.6, 0.001));
    });

    test('1 Ground must equal 2,400 Square Feet', () {
      final res = LandUnits.convertAll(1.0, 'grounds');
      expect(res['square_feet'], closeTo(2400.0, 0.001));
      // 2400 / 435.6 = 5.5096 Cents
      expect(res['cents'], closeTo(5.5096, 0.01));
    });

    test('1 Acre must equal 43,560 Square Feet and 100 Cents', () {
      final res = LandUnits.convertAll(1.0, 'acres');
      expect(res['square_feet'], closeTo(43560.0, 0.001));
      expect(res['cents'], closeTo(100.0, 0.001));
    });

    test('1 Hectare must equal 10,000 Square Metres', () {
      final res = LandUnits.convertAll(1.0, 'hectares');
      expect(res['square_meters'], closeTo(10000.0, 0.1));
      expect(res['acres'], closeTo(2.471, 0.01));
    });

    test('1 Square Yard must equal 9 Square Feet', () {
      final res = LandUnits.convertAll(10.0, 'square_yards');
      expect(res['square_feet'], closeTo(90.0, 0.001));
    });

    test('Zero or negative values return empty map gracefully', () {
      expect(LandUnits.convertAll(0.0, 'cents'), isEmpty);
      expect(LandUnits.convertAll(-5.0, 'cents'), isEmpty);
    });
  });
}
