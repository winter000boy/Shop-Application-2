import 'package:flutter_test/flutter_test.dart';
import 'package:repair_shop_app/core/brands.dart';

void main() {
  test('brands are normalised to one spelling', () {
    expect(Brands.normalize('  samsung '), 'Samsung');
    expect(Brands.normalize('ONEPLUS'), 'OnePlus');
    expect(Brands.normalize('karbonn'), 'Karbonn');
    expect(Brands.normalize('   '), isNull);
    expect(Brands.normalize(null), isNull);
  });
}
