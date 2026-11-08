import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:repair_shop_app/core/l10n/app_strings.dart';
import 'package:repair_shop_app/core/theme/app_theme.dart';
import 'package:repair_shop_app/database/local_cache.dart';
import 'package:repair_shop_app/features/auth/presentation/auth_notifier.dart';
import 'package:repair_shop_app/features/dashboard/job_filters.dart';
import 'package:repair_shop_app/features/dashboard/presentation/job_list_card.dart';
import 'package:repair_shop_app/features/help/presentation/help_support_screen.dart';
import 'package:repair_shop_app/features/language/presentation/language_screen.dart';
import 'package:repair_shop_app/features/offers/presentation/offers_screen.dart';
import 'package:repair_shop_app/features/repair_orders/presentation/add_order_screen.dart';
import 'package:repair_shop_app/features/repair_orders/presentation/orders_notifier.dart';
import 'package:repair_shop_app/features/settings/presentation/settings_screen.dart';
import 'package:repair_shop_app/shared/providers.dart';

final _devicePhotoCountsProvider = StreamProvider.autoDispose<Map<String, int>>((ref) {
  return ref.watch(databaseProvider).watchDevicePhotoCounts();
});

/// Home: every repair job, with status tiles, a brand filter and search.
class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  bool _syncing = false;
  JobTile _tile = JobTile.all;
  String? _brand;
  String _query = '';
  final _searchController = TextEditingController();
  Timer? _searchDebounce;

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 250), () {
      if (mounted) setState(() => _query = value.trim());
    });
  }

  Future<void> _handleSync() async {
    setState(() => _syncing = true);
    final success = await ref.read(syncManagerProvider).triggerSync();
    if (!mounted) return;
    setState(() => _syncing = false);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(success ? 'Synced successfully' : 'Sync failed. You are currently offline.'),
      backgroundColor: success ? AppTheme.successColor : AppTheme.warningColor,
      behavior: SnackBarBehavior.floating,
    ));
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

  void _showComingSoon(String title) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(28.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.stars_rounded, size: 56, color: AppTheme.primaryColor),
            const SizedBox(height: 16),
            Text(title, style: Theme.of(context).textTheme.titleLarge, textAlign: TextAlign.center),
            const SizedBox(height: 8),
            const Text('This module is coming in a later update.', textAlign: TextAlign.center),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(onPressed: () => Navigator.pop(context), child: const Text('OK')),
            ),
          ],
        ),
      ),
    );
  }

  void _open(Widget screen) {
    Navigator.pop(context); // close the drawer
    Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
  }

  Widget _buildDrawer() {
    final shopName = LocalCache.getShopName() ?? 'My Repair Shop';
    final ownerName = LocalCache.getOwnerName() ?? '';
    const moreTools = [
      (Icons.handshake_outlined, 'Dealer Repairing'),
      (Icons.book_outlined, 'Rough Register'),
      (Icons.analytics_outlined, 'Daily Profit'),
      (Icons.shopping_bag_outlined, 'Sale Request'),
      (Icons.point_of_sale_outlined, 'Point of Sale'),
      (Icons.phonelink_setup_outlined, 'Old Mobile Purchase'),
      (Icons.receipt_long_outlined, 'Quick Invoice'),
    ];

    return Drawer(
      child: SafeArea(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
              child: Row(
                children: [
                  Image.asset('assets/branding/logo_round.png', width: 56, height: 56),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(shopName,
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                        if (ownerName.isNotEmpty) Text(ownerName, style: const TextStyle(fontSize: 12)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.add_box_outlined),
              title: Text(context.tr(S.newJobCard)),
              onTap: () => _open(const AddOrderScreen()),
            ),
            ListTile(
              leading: const Icon(Icons.local_offer_outlined),
              title: Text(context.tr(S.offers)),
              onTap: () => _open(const OffersScreen()),
            ),
            ListTile(
              leading: const Icon(Icons.translate_outlined),
              title: Text(context.tr(S.changeLanguage)),
              onTap: () => _open(const LanguageScreen()),
            ),
            ListTile(
              leading: const Icon(Icons.support_agent_outlined),
              title: Text(context.tr(S.helpSupport)),
              onTap: () => _open(const HelpSupportScreen()),
            ),
            ListTile(
              leading: const Icon(Icons.settings_outlined),
              title: Text(context.tr(S.settings)),
              onTap: () => _open(const SettingsScreen()),
            ),
            ExpansionTile(
              leading: const Icon(Icons.apps_outlined),
              title: Text(context.tr(S.moreTools)),
              children: [
                for (final (icon, title) in moreTools)
                  ListTile(
                    contentPadding: const EdgeInsets.only(left: 32, right: 16),
                    leading: Icon(icon, size: 20),
                    title: Text(title),
                    onTap: () {
                      Navigator.pop(context);
                      _showComingSoon(title);
                    },
                  ),
              ],
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout, color: AppTheme.dangerColor),
              title: Text(context.tr(S.signOut), style: const TextStyle(color: AppTheme.dangerColor)),
              onTap: () {
                Navigator.pop(context);
                _handleLogout();
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTiles(Map<JobTile, int> counts) {
    final tiles = [
      (JobTile.all, S.all, Icons.all_inbox_outlined, Colors.blueGrey),
      (JobTile.today, S.today, Icons.today_outlined, AppTheme.accentColor),
      (JobTile.pending, S.pending, Icons.hourglass_top_outlined, AppTheme.warningColor),
      (JobTile.repaired, S.repaired, Icons.build_circle_outlined, AppTheme.successColor),
      (JobTile.delivered, S.delivered, Icons.local_shipping_outlined, AppTheme.primaryColor),
      (JobTile.cancelled, S.cancelled, Icons.cancel_outlined, AppTheme.dangerColor),
    ];
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SizedBox(
      height: 92,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: tiles.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, i) {
          final (tile, label, icon, color) = tiles[i];
          final selected = _tile == tile;
          return InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () => setState(() => _tile = tile),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: 104,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: selected ? color : (isDark ? AppTheme.darkSurface : Colors.white),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: selected ? color : (isDark ? AppTheme.darkBorder : AppTheme.lightBorder)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(icon, size: 18, color: selected ? Colors.white : color),
                      const Spacer(),
                      Text('${counts[tile] ?? 0}',
                          style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: selected ? Colors.white : null)),
                    ],
                  ),
                  Text(context.tr(label),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: selected ? Colors.white : null)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildBrandFilter(List<MapEntry<String, int>> brands) {
    return SizedBox(
      height: 44,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(context.tr(S.allBrands)),
              selected: _brand == null,
              onSelected: (_) => setState(() => _brand = null),
            ),
          ),
          for (final b in brands)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                label: Text('${b.key} (${b.value})'),
                selected: _brand == b.key,
                onSelected: (sel) => setState(() => _brand = sel ? b.key : null),
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final shopName = LocalCache.getShopName() ?? 'My Repair Shop';
    final ordersAsync = ref.watch(ordersStreamProvider(const OrderFilter()));
    final photoCounts = ref.watch(_devicePhotoCountsProvider).valueOrNull ?? const {};
    final now = DateTime.now();

    return Scaffold(
      drawer: _buildDrawer(),
      appBar: AppBar(
        title: Text(shopName, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            tooltip: context.tr(S.changeLanguage),
            icon: const Icon(Icons.translate_outlined),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LanguageScreen())),
          ),
          IconButton(
            tooltip: context.tr(S.syncNow),
            icon: _syncing
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.cloud_sync_outlined),
            onPressed: _syncing ? null : _handleSync,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AddOrderScreen())),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: Text(context.tr(S.newJobCard)),
      ),
      body: ordersAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Could not load jobs: $err')),
        data: (orders) {
          final counts = JobFilters.countByTile(orders, now);
          // Brand chips reflect the selected tile, so "Today" shows only today's brands
          final inTile = orders.where((o) => JobFilters.matchesTile(o, _tile, now)).toList();
          final brands = JobFilters.brandCounts(inTile);
          if (_brand != null && !brands.any((b) => b.key == _brand)) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) setState(() => _brand = null);
            });
          }
          final visible = JobFilters.apply(orders, tile: _tile, brand: _brand, query: _query, now: now);

          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
                  child: Text(context.tr(S.allJobs),
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: -0.3)),
                ),
              ),
              SliverToBoxAdapter(child: _buildTiles(counts)),
              const SliverToBoxAdapter(child: SizedBox(height: 12)),
              if (brands.isNotEmpty) SliverToBoxAdapter(child: _buildBrandFilter(brands)),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                  child: TextField(
                    controller: _searchController,
                    onChanged: _onSearchChanged,
                    decoration: InputDecoration(
                      hintText: context.tr(S.searchJobs),
                      prefixIcon: const Icon(Icons.search),
                      isDense: true,
                      suffixIcon: _searchController.text.isEmpty
                          ? null
                          : IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                _searchController.clear();
                                _onSearchChanged('');
                              },
                            ),
                    ),
                  ),
                ),
              ),
              if (visible.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.inbox_outlined, size: 64, color: Colors.grey.shade400),
                        const SizedBox(height: 12),
                        Text(context.tr(S.noJobs), style: const TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Text(context.tr(S.noJobsHint), textAlign: TextAlign.center),
                      ],
                    ),
                  ),
                )
              else
                SliverPadding(
                  // Bottom padding keeps the last card clear of the floating button
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 96),
                  sliver: SliverList.builder(
                    itemCount: visible.length,
                    itemBuilder: (context, i) => JobListCard(
                      order: visible[i],
                      photoCount: photoCounts[visible[i].id] ?? 0,
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
