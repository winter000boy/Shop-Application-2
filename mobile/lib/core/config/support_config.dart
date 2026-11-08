/// Support contacts shown on the Help & Support screen. Set per build, for example:
///   flutter build apk --dart-define=SUPPORT_PHONE=+919876543210 --dart-define=SUPPORT_EMAIL=help@example.com
/// A contact left empty is hidden from the screen.
class SupportConfig {
  static const String phone = String.fromEnvironment('SUPPORT_PHONE');
  static const String whatsapp = String.fromEnvironment('SUPPORT_WHATSAPP');
  static const String email = String.fromEnvironment('SUPPORT_EMAIL');

  static bool get hasAnyContact => phone.isNotEmpty || whatsapp.isNotEmpty || email.isNotEmpty;
}
