import 'dart:convert';
import 'dart:typed_data';

import 'package:encrypt/encrypt.dart' as enc;

/// Encrypts customer device passcodes/patterns before they are written to the local database.
/// AES-256-GCM; the key lives in the platform keystore (see LocalCache.deviceSecretKey).
class DeviceSecretCipher {
  static const String _prefix = 'enc:v1:';
  static const int _ivLength = 12;

  final enc.Encrypter _encrypter;

  DeviceSecretCipher(Uint8List key) : _encrypter = enc.Encrypter(enc.AES(enc.Key(key), mode: enc.AESMode.gcm));

  String? encrypt(String? plaintext) {
    if (plaintext == null || plaintext.isEmpty) return null;
    final iv = enc.IV.fromSecureRandom(_ivLength);
    final encrypted = _encrypter.encrypt(plaintext, iv: iv);
    return '$_prefix${base64Encode([...iv.bytes, ...encrypted.bytes])}';
  }

  String? decrypt(String? stored) {
    if (stored == null || !stored.startsWith(_prefix)) return stored;
    final data = base64Decode(stored.substring(_prefix.length));
    final iv = enc.IV(Uint8List.fromList(data.sublist(0, _ivLength)));
    return _encrypter.decrypt(enc.Encrypted(Uint8List.fromList(data.sublist(_ivLength))), iv: iv);
  }
}
