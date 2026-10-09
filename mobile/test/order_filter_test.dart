import 'package:flutter_test/flutter_test.dart';
import 'package:repair_shop_app/features/repair_orders/presentation/orders_notifier.dart';

void main() {
  test('equal filters are equal so the stream provider is reused', () {
    expect(const OrderFilter(status: 'PENDING', searchQuery: 'ravi'),
        const OrderFilter(status: 'PENDING', searchQuery: 'ravi'));
    expect(const OrderFilter().hashCode, const OrderFilter().hashCode);
    expect(const OrderFilter(status: 'PENDING'), isNot(const OrderFilter()));
  });
}
