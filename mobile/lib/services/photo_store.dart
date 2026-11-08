import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

/// Keeps job card photos (device condition, customer KYC) in the app's private documents directory.
/// Other apps cannot read it, and it is removed when the app is uninstalled or the shop signs out.
class PhotoStore {
  static const String _folder = 'job_photos';
  static const _uuid = Uuid();

  static Future<Directory> _dir() async {
    final docs = await getApplicationDocumentsDirectory();
    final dir = Directory(p.join(docs.path, _folder));
    if (!await dir.exists()) await dir.create(recursive: true);
    return dir;
  }

  /// Copies a picked image (usually in the picker's temporary cache) into permanent private storage.
  static Future<String> persist(String sourcePath) async {
    final dir = await _dir();
    final ext = p.extension(sourcePath).isEmpty ? '.jpg' : p.extension(sourcePath);
    final target = p.join(dir.path, '${_uuid.v4()}$ext');
    await File(sourcePath).copy(target);
    return target;
  }

  static Future<void> delete(String path) async {
    try {
      final file = File(path);
      if (await file.exists()) await file.delete();
    } catch (e) {
      debugPrint('Could not delete photo $path: $e');
    }
  }

  /// Removes every stored photo (sign-out, or a different shop signing in on this device).
  static Future<void> deleteAll() async {
    try {
      final docs = await getApplicationDocumentsDirectory();
      final dir = Directory(p.join(docs.path, _folder));
      if (await dir.exists()) await dir.delete(recursive: true);
    } catch (e) {
      debugPrint('Could not clear job photos: $e');
    }
  }
}
