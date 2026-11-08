import 'package:flutter_test/flutter_test.dart';
import 'package:repair_shop_app/database/app_database.dart';
import 'package:repair_shop_app/features/dashboard/job_filters.dart';

Order job(String id, {String status = OrderStatus.pending, String? brand, String? model, String? imei, DateTime? created}) {
  final at = created ?? DateTime(2026, 11, 1, 10);
  return Order(
    id: '${id}0000000-0000',
    status: status,
    repairDate: at,
    repairTime: '10:00',
    reminderEnabled: false,
    customerName: 'Customer $id',
    customerNumber: '98765$id',
    brand: brand,
    model: model,
    imei: imei,
    deviceProblem: 'Screen',
    estimatePriceMinor: 0,
    paidPriceMinor: 0,
    accessoriesSim: false,
    accessoriesSdCard: false,
    accessoriesBackCover: false,
    accessoriesCharger: false,
    accessoriesBattery: false,
    notifyWhatsapp: false,
    notifyEmail: false,
    syncStatus: SyncStatus.synced,
    localRevision: 0,
    createdAt: at,
    updatedAt: at,
  );
}

void main() {
  final now = DateTime(2026, 11, 8, 15);
  final orders = [
    job('1', brand: 'Samsung', created: DateTime(2026, 11, 8, 9)),
    job('2', brand: 'samsung ', status: OrderStatus.repaired),
    job('3', brand: 'Apple', status: OrderStatus.delivered, model: 'iPhone 13'),
    job('4', status: OrderStatus.cancelled, imei: '356938035643809'),
  ];

  test('tile counts', () {
    final counts = JobFilters.countByTile(orders, now);
    expect(counts[JobTile.all], 4);
    expect(counts[JobTile.today], 1);
    expect(counts[JobTile.pending], 1);
    expect(counts[JobTile.repaired], 1);
    expect(counts[JobTile.delivered], 1);
    expect(counts[JobTile.cancelled], 1);
  });

  test('brands are grouped case-insensitively, missing brand is Other', () {
    final brands = JobFilters.brandCounts(orders);
    expect(brands.first.key, 'Samsung');
    expect(brands.first.value, 2);
    expect(brands.map((e) => e.key), containsAll(['Apple', JobFilters.otherBrand]));
  });

  test('tile, brand and search combine', () {
    expect(JobFilters.apply(orders, tile: JobTile.all, brand: 'Samsung', now: now).length, 2);
    expect(JobFilters.apply(orders, tile: JobTile.today, brand: 'Samsung', now: now).length, 1);
    expect(JobFilters.apply(orders, tile: JobTile.all, query: 'iphone', now: now).single.brand, 'Apple');
    expect(JobFilters.apply(orders, tile: JobTile.all, query: '35693803', now: now).length, 1);
  });
}
