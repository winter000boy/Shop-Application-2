/// Common phone brands in India, offered as suggestions on the job card. Any other brand can be typed.
class Brands {
  static const List<String> common = [
    'Samsung', 'Apple', 'Xiaomi', 'Redmi', 'POCO', 'Vivo', 'iQOO', 'Oppo', 'Realme', 'OnePlus', 'Motorola',
    'Nokia', 'Google', 'Infinix', 'Tecno', 'itel', 'Lava', 'Micromax', 'Nothing', 'Honor', 'Asus', 'Lenovo',
  ];

  /// Trims and matches the known spelling case-insensitively ("samsung " -> "Samsung") so the brand filter
  /// doesn't split one brand into several chips.
  static String? normalize(String? raw) {
    final value = raw?.trim().replaceAll(RegExp(r'\s+'), ' ') ?? '';
    if (value.isEmpty) return null;
    for (final b in common) {
      if (b.toLowerCase() == value.toLowerCase()) return b;
    }
    return value[0].toUpperCase() + value.substring(1);
  }
}
