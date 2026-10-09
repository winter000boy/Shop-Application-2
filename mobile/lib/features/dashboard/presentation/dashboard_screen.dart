import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:repair_shop_app/core/theme/app_theme.dart';
import 'package:repair_shop_app/database/local_cache.dart';
import 'package:repair_shop_app/features/auth/presentation/auth_notifier.dart';
import 'package:repair_shop_app/features/repair_orders/presentation/orders_list_screen.dart';
import 'package:repair_shop_app/features/settings/presentation/settings_screen.dart';
import 'package:repair_shop_app/shared/providers.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  bool _syncing = false;

  Future<void> _handleSync() async {
    setState(() => _syncing = true);
    final success = await ref.read(syncManagerProvider).triggerSync();
    if (!mounted) return;
    setState(() => _syncing = false);

    {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success ? 'Database synced successfully!' : 'Sync failed. You are currently offline.'),
          backgroundColor: success ? AppTheme.successColor : AppTheme.warningColor,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _handleLogout() async {
    final auth = ref.read(authProvider.notifier);
    // Push anything still queued first; signing out wipes this device's copy of the orders
    final unsynced = await auth.syncBeforeLogout();
    if (!mounted) return;

    if (unsynced > 0) {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Unsynced changes'),
          content: Text(
            '$unsynced change${unsynced == 1 ? '' : 's'} could not be uploaded (you may be offline). '
            'Signing out now will permanently lose ${unsynced == 1 ? 'it' : 'them'}.',
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Stay Signed In')),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Sign Out Anyway', style: TextStyle(color: AppTheme.dangerColor)),
            ),
          ],
        ),
      );
      if (confirm != true) return;
    }

    // Navigation back to the login screen is handled by the app-level auth listener
    await auth.logout();
  }

  void _showScaffoldedModuleDialog(String title) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(28.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 50,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade400,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              const SizedBox(height: 24),
              const Icon(Icons.stars_rounded, size: 56, color: AppTheme.primaryColor),
              const SizedBox(height: 16),
              Text(
                title,
                style: Theme.of(context).textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'This module is scaffolded for Phase 1. Complete implementation, full analytics integration, and printer connectivity will be available in Phase 2!',
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Got it!'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final shopName = LocalCache.getShopName() ?? 'My Repair Shop';
    final ownerName = LocalCache.getOwnerName() ?? 'Owner';
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            CircleAvatar(
              backgroundColor: AppTheme.primaryColor.withOpacity(0.15),
              child: const Icon(Icons.build, color: AppTheme.primaryColor, size: 20),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  shopName,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                Text(
                  'Hello, $ownerName',
                  style: TextStyle(fontSize: 12, color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary),
                ),
              ],
            ),
          ],
        ),
        actions: [
          // Synchronize trigger action
          IconButton(
            icon: _syncing
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.cloud_sync_outlined),
            tooltip: 'Sync Local SQLite with Cloud',
            onPressed: _syncing ? null : _handleSync,
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsScreen()),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Depart 1: Repairing Management
            _buildSectionHeader('Repairing Management', Icons.home_repair_service_outlined),
            const SizedBox(height: 12),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              childAspectRatio: 1.35,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              children: [
                _buildDashboardTile(
                  icon: Icons.assignment_outlined,
                  color: AppTheme.primaryColor,
                  title: 'Repair Order',
                  subtitle: 'Manage repairs',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const OrdersListScreen()),
                    );
                  },
                ),
                _buildDashboardTile(
                  icon: Icons.handshake_outlined,
                  color: AppTheme.successColor,
                  title: 'Dealer Repairing',
                  subtitle: 'Outsourced jobs',
                  onTap: () => _showScaffoldedModuleDialog('Dealer Repairing'),
                ),
                _buildDashboardTile(
                  icon: Icons.book_outlined,
                  color: AppTheme.warningColor,
                  title: 'Rough Register',
                  subtitle: 'Quick drafts',
                  onTap: () => _showScaffoldedModuleDialog('Rough Register'),
                ),
                _buildDashboardTile(
                  icon: Icons.analytics_outlined,
                  color: AppTheme.accentColor,
                  title: 'Daily Profit',
                  subtitle: 'Income records',
                  onTap: () => _showScaffoldedModuleDialog('Daily Profit Record'),
                ),
                _buildDashboardTile(
                  icon: Icons.shopping_bag_outlined,
                  color: Colors.cyan,
                  title: 'Sale Request',
                  subtitle: 'Spare requests',
                  onTap: () => _showScaffoldedModuleDialog('Sale Request'),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Depart 2: Retail Shop
            _buildSectionHeader('Retail Shop & POS', Icons.shopping_cart_outlined),
            const SizedBox(height: 12),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              childAspectRatio: 1.35,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              children: [
                _buildDashboardTile(
                  icon: Icons.point_of_sale_outlined,
                  color: AppTheme.successColor,
                  title: 'Point of Sale',
                  subtitle: 'Billing system',
                  onTap: () => _showScaffoldedModuleDialog('Point of Sale'),
                ),
                _buildDashboardTile(
                  icon: Icons.phonelink_setup_outlined,
                  color: AppTheme.primaryColor,
                  title: 'Old Mobile',
                  subtitle: 'Purchase logs',
                  onTap: () => _showScaffoldedModuleDialog('Old Mobile Purchase'),
                ),
                _buildDashboardTile(
                  icon: Icons.store_mall_directory_outlined,
                  color: AppTheme.warningColor,
                  title: 'Local Market',
                  subtitle: 'Wholesale prices',
                  onTap: () => _showScaffoldedModuleDialog('Local Market'),
                ),
                _buildDashboardTile(
                  icon: Icons.receipt_long_outlined,
                  color: AppTheme.dangerColor,
                  title: 'Quick Invoice',
                  subtitle: 'PDF receipts',
                  onTap: () => _showScaffoldedModuleDialog('Quick Invoice'),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Depart 3: Marketing
            _buildSectionHeader('Marketing & Engagement', Icons.campaign_outlined),
            const SizedBox(height: 12),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              childAspectRatio: 1.35,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              children: [
                _buildDashboardTile(
                  icon: Icons.groups_outlined,
                  color: AppTheme.accentColor,
                  title: 'Technicians',
                  subtitle: 'Community forum',
                  onTap: () => _showScaffoldedModuleDialog('Technician Community'),
                ),
                _buildDashboardTile(
                  icon: Icons.textsms_outlined,
                  color: AppTheme.successColor,
                  title: 'WhatsApp Bulk',
                  subtitle: 'Broadcast alerts',
                  onTap: () => _showScaffoldedModuleDialog('WhatsApp Bulk Message'),
                ),
                _buildDashboardTile(
                  icon: Icons.notifications_active_outlined,
                  color: AppTheme.warningColor,
                  title: 'Auto Alert',
                  subtitle: 'Collection triggers',
                  onTap: () => _showScaffoldedModuleDialog('Auto Alert'),
                ),
                _buildDashboardTile(
                  icon: Icons.card_giftcard_outlined,
                  color: AppTheme.primaryColor,
                  title: 'Refer & Earn',
                  subtitle: 'Affiliate links',
                  onTap: () => _showScaffoldedModuleDialog('Refer & Earn'),
                ),
              ],
            ),
            const SizedBox(height: 36),

            // Logout Action Button
            ElevatedButton.icon(
              onPressed: _handleLogout,
              icon: const Icon(Icons.logout),
              label: const Text('Sign Out'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.dangerColor,
                foregroundColor: Colors.white,
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppTheme.primaryColor),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: -0.5),
        ),
      ],
    );
  }

  Widget _buildDashboardTile({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? AppTheme.darkSurface : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder,
            width: 1,
          ),
          boxShadow: isDark
              ? null
              : [
                  BoxShadow(
                    color: Colors.grey.shade100,
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, height: 1.2),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 10,
                    color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
