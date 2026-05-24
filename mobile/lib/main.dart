import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:repair_shop_app/core/theme/app_theme.dart';
import 'package:repair_shop_app/core/theme/theme_provider.dart';
import 'package:repair_shop_app/database/local_cache.dart';
import 'package:repair_shop_app/features/auth/presentation/login_screen.dart';
import 'package:repair_shop_app/features/dashboard/presentation/dashboard_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize persistent Hive local cache
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

    return MaterialApp(
      title: 'FixManager',
      debugShowCheckedModeBanner: false,
      themeMode: themeMode,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      // Conditional entry routing
      home: LocalCache.isAuthenticated()
          ? const DashboardScreen()
          : const LoginScreen(),
    );
  }
}
