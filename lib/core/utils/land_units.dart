class LandUnitConverter {
  static const double sqFtPerCent = 435.6;
  static const double sqFtPerGround = 2400.0;
  static const double sqFtPerAcre = 43560.0;
  static const double sqFtPerGuntha = 1089.0;

  static const List<String> supportedUnits = [
    'Sq.Ft',
    'Cents',
    'Grounds',
    'Acres',
    'Guntha',
  ];

  /// Converts any value in a given unit to square feet.
  static int toSqFt(double value, String unit) {
    switch (unit) {
      case 'Cents':
        return (value * sqFtPerCent).round();
      case 'Grounds':
        return (value * sqFtPerGround).round();
      case 'Acres':
        return (value * sqFtPerAcre).round();
      case 'Guntha':
        return (value * sqFtPerGuntha).round();
      case 'Sq.Ft':
      default:
        return value.round();
    }
  }

  /// Converts square feet to a specific unit with formatted decimal.
  static double fromSqFt(int sqFt, String unit) {
    switch (unit) {
      case 'Cents':
        return double.parse((sqFt / sqFtPerCent).toStringAsFixed(2));
      case 'Grounds':
        return double.parse((sqFt / sqFtPerGround).toStringAsFixed(2));
      case 'Acres':
        return double.parse((sqFt / sqFtPerAcre).toStringAsFixed(3));
      case 'Guntha':
        return double.parse((sqFt / sqFtPerGuntha).toStringAsFixed(2));
      case 'Sq.Ft':
      default:
        return sqFt.toDouble();
    }
  }

  /// Returns a human-friendly multi-unit label, e.g. "4.5 Cents (~1,960 sq ft)"
  static String formatWithConversion({
    required int sqFt,
    String? preferredUnit,
    double? unitValue,
  }) {
    if (preferredUnit != null && preferredUnit != 'Sq.Ft' && unitValue != null && unitValue > 0) {
      return '$unitValue $preferredUnit (~$sqFt sq ft)';
    }

    // Auto smart presentation for Land / Plots
    if (sqFt >= 43560) {
      final acres = (sqFt / sqFtPerAcre).toStringAsFixed(2);
      return '$acres Acres ($sqFt sq ft)';
    } else if (sqFt >= 2400) {
      final grounds = (sqFt / sqFtPerGround).toStringAsFixed(1);
      final cents = (sqFt / sqFtPerCent).toStringAsFixed(1);
      return '$grounds Grounds / $cents Cents ($sqFt sq ft)';
    } else if (sqFt >= 435) {
      final cents = (sqFt / sqFtPerCent).toStringAsFixed(1);
      return '$cents Cents ($sqFt sq ft)';
    }
    return '$sqFt sq ft';
  }
}
