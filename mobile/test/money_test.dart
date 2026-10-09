import 'package:flutter_test/flutter_test.dart';
import 'package:repair_shop_app/core/money.dart';

void main() {
  test('parses user input into minor units without float drift', () {
    expect(Money.parseMinor('1500'), 150000);
    expect(Money.parseMinor('0.1'), 10);
    expect(Money.parseMinor(' 19.99 '), 1999);
    expect(Money.parseMinor('-5'), isNull);
    expect(Money.parseMinor('abc'), isNull);
  });

  test('formats and round-trips through the API', () {
    expect(Money.format(150050, '₹'), '₹1500.50');
    expect(Money.format(150000, '₹'), '₹1500');
    expect(Money.toInput(1999), '19.99');
    expect(Money.fromApi(Money.toApi(1999)), 1999);
    expect(Money.fromApi(1500.5), 150050);
  });
}
