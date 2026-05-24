import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:repair_shop_app/core/network/api_client.dart';
import 'package:repair_shop_app/core/theme/app_theme.dart';
import 'package:repair_shop_app/core/theme/theme_provider.dart';
import 'package:repair_shop_app/database/local_cache.dart';
import 'package:repair_shop_app/shared/providers.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _OrdersSyncState {
  final bool isLoading;
  _OrdersSyncState(this.isLoading);
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final _formKey = GlobalKey<FormState>();

  // Shop Details Controllers
  final _shopNameController = TextEditingController();
  final _ownerNameController = TextEditingController();
  final _mobileController = TextEditingController();
  final _addressController = TextEditingController();

  String _selectedShopType = 'Mobile Repair';
  String _selectedCurrency = '₹';
  String _selectedLanguage = 'en';

  bool _isSaving = false;
  bool _syncing = false;

  final List<String> _shopTypes = [
    'Mobile Repair',
    'Laptop Repair',
    'Computer Repair',
    'Electronics Repair'
  ];
  final List<String> _currencies = ['₹', '$', '€', '£', '¥', 'AED'];
  
  final Map<String, String> _languages = {
    'en': 'English',
    'hi': 'Hindi (हिन्दी)',
    'es': 'Spanish (Español)',
    'fr': 'French (Français)',
  };

  @override
  void initState() {
    super.initState();
    _shopNameController.text = LocalCache.getShopName() ?? '';
    _ownerNameController.text = LocalCache.getOwnerName() ?? '';
    _mobileController.text = Hive.box('auth_session').get(LocalCache.keyMobileNumber) as String? ?? '';
    _addressController.text = LocalCache.getLogoUrl() ?? ''; // reuse logo or address
    
    _selectedShopType = LocalCache.getShopType() ?? 'Mobile Repair';
    if (!_shopTypes.contains(_selectedShopType)) {
      _selectedShopType = _shopTypes.first;
    }
    
    _selectedCurrency = LocalCache.getCurrencySymbol();
    if (!_currencies.contains(_selectedCurrency)) {
      _selectedCurrency = _currencies.first;
    }

    _selectedLanguage = LocalCache.getLanguage();
  }

  @override
  void dispose() {
    _shopNameController.dispose();
    _ownerNameController.dispose();
    _mobileController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _handleSaveShopDetails() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isSaving = true);
      
      final api = ref.read(apiClientProvider);
      final shopAddress = _addressController.text.trim();
      final mobile = _mobileController.text.trim();
      final countryCode = Hive.box('auth_session').get(LocalCache.keyCountryCode) as String? ?? '+91';

      try {
        final http.Response response = await api.put('/shop', {
          'shopName': _shopNameController.text.trim(),
          'shopType': _selectedShopType,
          'ownerName': _ownerNameController.text.trim(),
          'mobileNumber': mobile.isEmpty ? '1234567890' : mobile,
          'countryCode': countryCode,
          'shopAddress': shopAddress.isEmpty ? null : shopAddress,
          'currencySymbol': _selectedCurrency,
          'logoUrl': '',
        });

        if (response.statusCode == 200) {
          // Success: Save in local Hive cache
          await LocalCache.updateShopDetails(
            shopName: _shopNameController.text.trim(),
            shopType: _selectedShopType,
            ownerName: _ownerNameController.text.trim(),
            currencySymbol: _selectedCurrency,
            logoUrl: '',
          );

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('Shop settings updated successfully!'),
                backgroundColor: AppTheme.successColor,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        } else {
          final errorData = jsonDecode(response.body);
          throw Exception(errorData['message'] ?? 'Failed to update remote shop details');
        }
      } catch (e) {
        // Fallback: Even if server is offline/unavailable, save locally!
        await LocalCache.updateShopDetails(
          shopName: _shopNameController.text.trim(),
          shopType: _selectedShopType,
          ownerName: _ownerNameController.text.trim(),
          currencySymbol: _selectedCurrency,
          logoUrl: '',
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Offline: Shop details updated locally on this device.'),
              backgroundColor: AppTheme.warningColor,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } finally {
        if (mounted) setState(() => _isSaving = false);
      }
    }
  }

  Future<void> _handleSync() async {
    setState(() => _syncing = true);
    final success = await ref.read(syncManagerProvider).triggerSync();
    if (mounted) {
      setState(() => _syncing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success ? 'Database synced successfully!' : 'Sync failed. Check connection.'),
          backgroundColor: success ? AppTheme.successColor : AppTheme.warningColor,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _handleClearLocalDatabase() async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Clear SQLite Database?'),
          content: const Text('This will delete all local repair orders from your device. Syncing later will pull them back if they exist on the server.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              style: TextButton.styleFrom(foregroundColor: AppTheme.dangerColor),
              child: const Text('Wipe Data'),
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      await ref.read(databaseProvider).clearAll();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('SQLite database cleared successfully'),
            backgroundColor: AppTheme.successColor,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeModeProvider);
    final isDark = themeMode == ThemeMode.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('App Settings'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // --- SHOP PROFILE PANEL ---
              _buildSectionCard(
                title: 'Shop Management',
                icon: Icons.storefront_outlined,
                children: [
                  DropdownButtonFormField<String>(
                    value: _selectedShopType,
                    decoration: const InputDecoration(labelText: 'Shop Type'),
                    items: _shopTypes.map((st) {
                      return DropdownMenuItem(value: st, child: Text(st));
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => _selectedShopType = val);
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _shopNameController,
                    decoration: const InputDecoration(
                      labelText: 'Shop Name',
                      prefixIcon: Icon(Icons.store),
                    ),
                    validator: (val) =>
                        (val == null || val.trim().isEmpty) ? 'Shop name is required' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _ownerNameController,
                    decoration: const InputDecoration(
                      labelText: 'Owner Name',
                      prefixIcon: Icon(Icons.person),
                    ),
                    validator: (val) =>
                        (val == null || val.trim().isEmpty) ? 'Owner name is required' : null,
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: _selectedCurrency,
                    decoration: const InputDecoration(
                      labelText: 'Business Currency',
                      prefixIcon: Icon(Icons.monetization_on_outlined),
                    ),
                    items: _currencies.map((symbol) {
                      return DropdownMenuItem(value: symbol, child: Text('$symbol ($symbol)'));
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => _selectedCurrency = val);
                    },
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _isSaving ? null : _handleSaveShopDetails,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: _isSaving
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Text('Save Shop Profile'),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // --- PREFERENCES PANEL ---
              _buildSectionCard(
                title: 'App Preferences',
                icon: Icons.tune_outlined,
                children: [
                  // Light/Dark Theme Switch
                  ListTile(
                    title: const Text('Dark Theme Mode'),
                    subtitle: const Text('HSL high-contrast colors'),
                    contentPadding: EdgeInsets.zero,
                    trailing: Switch(
                      value: isDark,
                      activeColor: AppTheme.primaryColor,
                      onChanged: (_) {
                        ref.read(themeModeProvider.notifier).toggleTheme();
                      },
                    ),
                  ),
                  const Divider(height: 16, thickness: 0.5),

                  // Language Choice dropdown
                  DropdownButtonFormField<String>(
                    value: _selectedLanguage,
                    decoration: const InputDecoration(
                      labelText: 'Application Language',
                      prefixIcon: Icon(Icons.language_outlined),
                    ),
                    items: _languages.entries.map((entry) {
                      return DropdownMenuItem(value: entry.key, child: Text(entry.value));
                    }).toList(),
                    onChanged: (val) async {
                      if (val != null) {
                        setState(() => _selectedLanguage = val);
                        await LocalCache.setLanguage(val);
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Language preference saved: ${_languages[val]}'),
                              backgroundColor: AppTheme.successColor,
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        }
                      }
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // --- DATA MANAGEMENT PANEL ---
              _buildSectionCard(
                title: 'Data & Sync Management',
                icon: Icons.storage_outlined,
                children: [
                  ListTile(
                    title: const Text('Force Cloud Database Sync'),
                    subtitle: const Text('Bi-directional push/pull'),
                    contentPadding: EdgeInsets.zero,
                    trailing: _syncing
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                        : IconButton(
                            icon: const Icon(Icons.sync, color: AppTheme.primaryColor),
                            onPressed: _handleSync,
                          ),
                  ),
                  const Divider(height: 16, thickness: 0.5),
                  ListTile(
                    title: const Text('Wipe Local SQLite Orders'),
                    subtitle: const Text('Deletes all local repair data'),
                    contentPadding: EdgeInsets.zero,
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_forever, color: AppTheme.dangerColor),
                      onPressed: _handleClearLocalDatabase,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // --- ABOUT INFO ---
              Center(
                child: Column(
                  children: [
                    const Icon(Icons.build_circle_outlined, size: 36, color: AppTheme.primaryColor),
                    const SizedBox(height: 8),
                    const Text(
                      'FixManager Mobile App',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      'Version 1.0.0 (Phase 1 Build)',
                      style: TextStyle(fontSize: 11, color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '© 2026 FixManager Inc. All rights reserved.',
                      style: TextStyle(fontSize: 10, color: (isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary).withOpacity(0.5)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 36),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder,
          width: 1.0,
        ),
      ),
      color: isDark ? AppTheme.darkSurface : Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 20, color: AppTheme.primaryColor),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, letterSpacing: -0.3),
                ),
              ],
            ),
            const Divider(height: 24, thickness: 0.5),
            ...children,
          ],
        ),
      ),
    );
  }
}
