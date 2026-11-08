import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:repair_shop_app/core/l10n/app_strings.dart';
import 'package:repair_shop_app/core/theme/app_theme.dart';
import 'package:repair_shop_app/core/theme/theme_provider.dart';
import 'package:repair_shop_app/database/local_cache.dart';
import 'package:repair_shop_app/features/auth/presentation/auth_notifier.dart';
import 'package:repair_shop_app/features/auth/presentation/login_screen.dart';
import 'package:repair_shop_app/features/dashboard/presentation/dashboard_screen.dart';

final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Hive preferences and load the secure session from the platform keystore
  await LocalCache.init();

  runApp(
    const ProviderScope(
      child: FixManagerApp(),
    ),
  );
}

class FixManagerApp extends ConsumerWidget {
  const FixManagerApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Dynamically watch active theme state
    final themeMode = ref.watch(themeModeProvider);
    final locale = ref.watch(localeProvider);

    // Whenever the session ends (sign out, or expired/revoked on the server), return to the login screen
    ref.listen<bool>(authProvider.select((s) => s.isAuthenticated), (wasAuthenticated, nowAuthenticated) {
      if (wasAuthenticated == true && !nowAuthenticated) {
        _navigatorKey.currentState?.pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
        );
      }
    });

    return MaterialApp(
      title: 'Ajgar Mobile UP',
      navigatorKey: _navigatorKey,
      debugShowCheckedModeBanner: false,
      themeMode: themeMode,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      // English + 10 Indian languages; Material widgets (date pickers, dialogs) follow the same locale
      locale: locale,
      supportedLocales: AppLanguage.locales,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      // Entry route only; later transitions are handled by the screens and the listener above
      home: LocalCache.isAuthenticated() ? const DashboardScreen() : const LoginScreen(),
    );
  }
}
