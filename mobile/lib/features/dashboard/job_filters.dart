import 'package:repair_shop_app/core/brands.dart';
import 'package:repair_shop_app/database/app_database.dart';

/// The horizontal tiles on the home page.
enum JobTile { all, today, pending, repaired, delivered, cancelled }

class JobFilters {
  /// Whether [order] belongs under [tile]. "Today" means received today (local time), whatever its status.
  static bool matchesTile(Order order, JobTile tile, DateTime now) {
    switch (tile) {
      case JobTile.all:
        return true;
      case JobTile.today:
        final created = order.createdAt.toLocal();
        return created.year == now.year && created.month == now.month && created.day == now.day;
      case JobTile.pending:
        return order.status == OrderStatus.pending;
      case JobTile.repaired:
        return order.status == OrderStatus.repaired;
      case JobTile.delivered:
        return order.status == OrderStatus.delivered;
      case JobTile.cancelled:
        return order.status == OrderStatus.cancelled;
    }
  }

  /// Display brand of an order ("Other" when none was recorded, e.g. jobs created before brands existed).
  static String brandOf(Order order) => Brands.normalize(order.brand) ?? otherBrand;
  static const String otherBrand = 'Other';

  static bool matchesQuery(Order order, String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return true;
    return [
      order.customerName,
      order.customerNumber,
      order.alternateNumber,
      order.imei,
      order.brand,
      order.model,
      order.id.substring(0, 8),
    ].any((field) => field != null && field.toLowerCase().contains(q));
  }

  static Map<JobTile, int> countByTile(List<Order> orders, DateTime now) => {
        for (final tile in JobTile.values) tile: orders.where((o) => matchesTile(o, tile, now)).length,
      };

  /// Brands present in [orders] with their job counts, most jobs first.
  static List<MapEntry<String, int>> brandCounts(List<Order> orders) {
    final counts = <String, int>{};
    for (final o in orders) {
      counts.update(brandOf(o), (c) => c + 1, ifAbsent: () => 1);
    }
    final entries = counts.entries.toList()
      ..sort((a, b) => b.value != a.value ? b.value.compareTo(a.value) : a.key.compareTo(b.key));
    return entries;
  }

  static List<Order> apply(List<Order> orders,
      {required JobTile tile, String? brand, String query = '', required DateTime now}) {
    return orders
        .where((o) => matchesTile(o, tile, now))
        .where((o) => brand == null || brandOf(o) == brand)
        .where((o) => matchesQuery(o, query))
        .toList();
  }
}
