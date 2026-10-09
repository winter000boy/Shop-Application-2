import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:repair_shop_app/core/security/device_secret_cipher.dart';

void main() {
  final cipher = DeviceSecretCipher(Uint8List.fromList(List<int>.generate(32, (i) => i)));

  test('round-trips and never stores plaintext', () {
    final encrypted = cipher.encrypt('1234')!;
    expect(encrypted, startsWith('enc:v1:'));
    expect(encrypted, isNot(contains('1234')));
    expect(cipher.decrypt(encrypted), '1234');
  });

  test('uses a fresh IV each time', () {
    expect(cipher.encrypt('1-2-3'), isNot(cipher.encrypt('1-2-3')));
  });

  test('empty values are stored as null; legacy plaintext passes through', () {
    expect(cipher.encrypt(''), isNull);
    expect(cipher.encrypt(null), isNull);
    expect(cipher.decrypt('plain'), 'plain');
  });
}
