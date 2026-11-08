import 'package:flutter_test/flutter_test.dart';
import 'package:repair_shop_app/services/whatsapp_service.dart';

void main() {
  test('local 10-digit numbers get the country code', () {
    expect(WhatsAppService.normalizeNumber('98765 43210', countryCode: '+91'), '919876543210');
    expect(WhatsAppService.normalizeNumber('098765-43210', countryCode: '+91'), '919876543210');
  });

  test('international numbers are kept', () {
    expect(WhatsAppService.normalizeNumber('+91 98765 43210', countryCode: '+91'), '919876543210');
    expect(WhatsAppService.normalizeNumber('0091 9876543210', countryCode: '+91'), '919876543210');
  });

  test('junk is rejected', () {
    expect(WhatsAppService.normalizeNumber('abc', countryCode: '+91'), isNull);
    expect(WhatsAppService.normalizeNumber('123', countryCode: '+91'), isNull);
  });
}
