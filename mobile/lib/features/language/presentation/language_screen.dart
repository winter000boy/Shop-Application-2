import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:repair_shop_app/core/l10n/app_strings.dart';
import 'package:repair_shop_app/core/theme/app_theme.dart';

/// Picks the app language. The change applies immediately across the app and is remembered.
class LanguageScreen extends ConsumerWidget {
  const LanguageScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final current = ref.watch(localeProvider).languageCode;
    return Scaffold(
      appBar: AppBar(title: Text(context.tr(S.changeLanguage))),
      body: ListView.separated(
        itemCount: AppLanguage.all.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (context, i) {
          final lang = AppLanguage.all[i];
          final selected = lang.code == current;
          return ListTile(
            title: Text(lang.nativeName, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
            subtitle: lang.code == 'en' ? null : Text(lang.englishName),
            trailing: selected
                ? const Icon(Icons.check_circle, color: AppTheme.primaryColor)
                : const Icon(Icons.circle_outlined),
            onTap: () => ref.read(localeProvider.notifier).setLanguage(lang.code),
          );
        },
      ),
    );
  }
}
