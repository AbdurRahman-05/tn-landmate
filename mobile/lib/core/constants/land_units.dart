class LandUnits {
  static const Map<String, double> sqftFactors = {
    'square_feet': 1.0,
    'square_meters': 10.763910416709722,
    'square_yards': 9.0,
    'cents': 435.6,
    'grounds': 2400.0,
    'acres': 43560.0,
    'hectares': 107639.10416709722,
    'square_kilometers': 10763910.416709722,
  };

  static const Map<String, String> unitLabelsEn = {
    'square_feet': 'Square Feet (Sq.Ft)',
    'cents': 'Cents (சென்ட்)',
    'grounds': 'Grounds (கிரவுண்டு)',
    'acres': 'Acres (ஏக்கர்)',
    'hectares': 'Hectares (ஹெக்டேர்)',
    'square_meters': 'Square Metres (Sq.M)',
    'square_yards': 'Square Yards (கஜம்)',
    'square_kilometers': 'Square Kilometres (Sq.Km)',
  };

  static const Map<String, String> unitLabelsTa = {
    'square_feet': 'சதுர அடி (Sq.Ft)',
    'cents': 'சென்ட் (Cents)',
    'grounds': 'கிரவுண்டு (Grounds)',
    'acres': 'ஏக்கர் (Acres)',
    'hectares': 'ஹெக்டேர் (Hectares)',
    'square_meters': 'சதுர மீட்டர் (Sq.M)',
    'square_yards': 'சதுர கஜம் (Sq.Yds)',
    'square_kilometers': 'சதுர கி.மீ (Sq.Km)',
  };

  static Map<String, double> convertAll(double value, String fromUnit) {
    if (value <= 0) return {};
    final factor = sqftFactors[fromUnit] ?? 1.0;
    final totalSqFt = value * factor;

    final results = <String, double>{};
    sqftFactors.forEach((unit, uFactor) {
      results[unit] = totalSqFt / uFactor;
    });
    return results;
  }
}
