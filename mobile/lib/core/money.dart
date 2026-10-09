// Amounts are stored as integer minor units (paise/cents) so arithmetic never suffers float rounding.
class Money {
  Money._();

  /// Parses user input like "1500" or "1500.50" into minor units. Returns null if invalid or negative.
  static int? parseMinor(String input) {
    final value = double.tryParse(input.trim());
    if (value == null || value < 0 || value.isNaN || value.isInfinite) return null;
    return (value * 100).round();
  }

  /// Formats minor units for display, e.g. 150050 -> "₹1500.50", 150000 -> "₹1500".
  static String format(int minor, String currency) => '$currency${toInput(minor)}';

  /// Text for pre-filling an input field.
  static String toInput(int minor) =>
      minor % 100 == 0 ? '${minor ~/ 100}' : (minor / 100).toStringAsFixed(2);

  /// JSON value for the API (a decimal number with at most 2 fraction digits).
  static num toApi(int minor) => minor % 100 == 0 ? minor ~/ 100 : minor / 100;

  static int fromApi(num value) => (value * 100).round();
}
