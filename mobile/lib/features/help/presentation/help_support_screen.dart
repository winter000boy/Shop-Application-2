import 'dart:io';

import 'package:flutter/material.dart';
import 'package:repair_shop_app/core/config/support_config.dart';
import 'package:repair_shop_app/core/l10n/app_strings.dart';
import 'package:repair_shop_app/core/theme/app_theme.dart';
import 'package:repair_shop_app/database/local_cache.dart';
import 'package:repair_shop_app/services/whatsapp_service.dart';
import 'package:url_launcher/url_launcher.dart';

/// FAQs plus ways to reach support. Contacts come from --dart-define (see SupportConfig); empty ones are hidden.
class HelpSupportScreen extends StatelessWidget {
  const HelpSupportScreen({super.key});

  static const String appVersion = '1.1.0';

  static const List<(String, String)> _faqs = [
    ('How do I add a new repair job?',
        'Tap "New Job Card" on the home page. Fill in the customer, brand, model and problem, and take at least one photo of the device so its condition at handover is on record.'),
    ('How do I tell the customer their phone is ready?',
        'Tap the status badge on the job and choose Repaired. If "Send WhatsApp Message" is ticked on the job card, WhatsApp opens with a ready-made message; just tap Send.'),
    ('Where are device and ID photos stored?',
        'Only on this phone, in the app\'s private storage. They are not uploaded to the server and are removed when you sign out. Text details of every job sync to your account.'),
    ('Does the app work without internet?',
        'Yes. Jobs are saved on the phone first and sync automatically when you are back online. Tap the cloud icon on the home page to sync right away.'),
    ('I forgot my password.',
        'On the sign-in screen tap "Forgot Password?". We email you a 6-digit code to set a new password.'),
    ('How do I change the language?',
        'Tap the translate icon at the top of the home page, or Menu > Change Language.'),
    ('How do I share an offer with customers?',
        'Menu > Offers. Add an offer, then tap the WhatsApp button on it to send it to a customer or a group.'),
  ];

  String _diagnostics() =>
      'App version: $appVersion\nPlatform: ${Platform.operatingSystem} ${Platform.operatingSystemVersion}\n'
      'Shop: ${LocalCache.getShopName() ?? '-'}';

  Future<void> _launch(BuildContext context, Uri uri) async {
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not open ${uri.scheme}'), behavior: SnackBarBehavior.floating),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final whatsappNumber = SupportConfig.whatsapp.isNotEmpty ? SupportConfig.whatsapp : SupportConfig.phone;
    return Scaffold(
      appBar: AppBar(title: Text(context.tr(S.helpSupport))),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (SupportConfig.hasAnyContact) ...[
            Text(context.tr(S.contactUs), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Card(
              child: Column(
                children: [
                  if (SupportConfig.phone.isNotEmpty)
                    ListTile(
                      leading: const Icon(Icons.call_outlined, color: AppTheme.primaryColor),
                      title: Text(context.tr(S.callUs)),
                      subtitle: const Text(SupportConfig.phone),
                      onTap: () => _launch(context, Uri(scheme: 'tel', path: SupportConfig.phone)),
                    ),
                  if (whatsappNumber.isNotEmpty)
                    ListTile(
                      leading: const Icon(Icons.chat_outlined, color: Color(0xFF25D366)),
                      title: Text(context.tr(S.whatsapp)),
                      subtitle: Text(whatsappNumber),
                      onTap: () => _launch(
                        context,
                        WhatsAppService.chatUri(phone: whatsappNumber, message: 'Hi, I need help with the app.\n\n${_diagnostics()}'),
                      ),
                    ),
                  if (SupportConfig.email.isNotEmpty) ...[
                    ListTile(
                      leading: const Icon(Icons.email_outlined, color: AppTheme.primaryColor),
                      title: Text(context.tr(S.emailUs)),
                      subtitle: const Text(SupportConfig.email),
                      onTap: () => _launch(context, Uri(scheme: 'mailto', path: SupportConfig.email, queryParameters: {
                        'subject': 'Help needed',
                      })),
                    ),
                    ListTile(
                      leading: const Icon(Icons.bug_report_outlined, color: AppTheme.dangerColor),
                      title: Text(context.tr(S.reportProblem)),
                      onTap: () => _launch(context, Uri(scheme: 'mailto', path: SupportConfig.email, queryParameters: {
                        'subject': 'Problem report',
                        'body': 'Describe the problem here:\n\n\n---\n${_diagnostics()}',
                      })),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],
          Text(context.tr(S.faq), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Card(
            child: Column(
              children: [
                for (final (q, a) in _faqs)
                  ExpansionTile(
                    title: Text(q, style: const TextStyle(fontWeight: FontWeight.w600)),
                    childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    expandedAlignment: Alignment.centerLeft,
                    children: [Text(a)],
                  ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Center(child: Text('Version $appVersion', style: const TextStyle(fontSize: 12, color: Colors.grey))),
        ],
      ),
    );
  }
}
