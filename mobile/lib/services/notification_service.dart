import 'package:flutter/foundation.dart';
import 'package:repair_shop_app/core/money.dart';

abstract class NotificationProvider {
  Future<bool> sendOrderReceived({
    required String customerName,
    required String customerNumber,
    required String orderId,
    required int estimatePriceMinor,
    required String currency,
  });

  Future<bool> sendRepairCompleted({
    required String customerName,
    required String customerNumber,
    required String orderId,
    required int estimatePriceMinor,
    required String currency,
  });

  Future<bool> sendDeliveryReminder({
    required String customerName,
    required String customerNumber,
    required String orderId,
  });

  Future<bool> sendPaymentPending({
    required String customerName,
    required String customerNumber,
    required int pendingAmountMinor,
    required String currency,
  });
}

// Log-based Mock implementation for Phase 1 testing
class MockNotificationProvider implements NotificationProvider {
  @override
  Future<bool> sendOrderReceived({
    required String customerName,
    required String customerNumber,
    required String orderId,
    required int estimatePriceMinor,
    required String currency,
  }) async {
    debugPrint('----------------------------------------');
    debugPrint('[WHATSAPP / EMAIL NOTIFICATION MOCK]');
    debugPrint('To: $customerName ($customerNumber)');
    debugPrint('Message: Hello $customerName, we have received your device (Order ID: $orderId). The estimated repair cost is ${Money.format(estimatePriceMinor, currency)}. Thank you!');
    debugPrint('----------------------------------------');
    return true;
  }

  @override
  Future<bool> sendRepairCompleted({
    required String customerName,
    required String customerNumber,
    required String orderId,
    required int estimatePriceMinor,
    required String currency,
  }) async {
    debugPrint('----------------------------------------');
    debugPrint('[WHATSAPP / EMAIL NOTIFICATION MOCK]');
    debugPrint('To: $customerName ($customerNumber)');
    debugPrint('Message: Great news $customerName! Your device under Order ID $orderId has been repaired successfully. Total payable: ${Money.format(estimatePriceMinor, currency)}. You can collect it at your earliest convenience.');
    debugPrint('----------------------------------------');
    return true;
  }

  @override
  Future<bool> sendDeliveryReminder({
    required String customerName,
    required String customerNumber,
    required String orderId,
  }) async {
    debugPrint('----------------------------------------');
    debugPrint('[WHATSAPP / EMAIL NOTIFICATION MOCK]');
    debugPrint('To: $customerName ($customerNumber)');
    debugPrint('Message: Dear $customerName, this is a reminder to collect your repaired device (Order ID: $orderId) from our shop. See you soon!');
    debugPrint('----------------------------------------');
    return true;
  }

  @override
  Future<bool> sendPaymentPending({
    required String customerName,
    required String customerNumber,
    required int pendingAmountMinor,
    required String currency,
  }) async {
    debugPrint('----------------------------------------');
    debugPrint('[WHATSAPP / EMAIL NOTIFICATION MOCK]');
    debugPrint('To: $customerName ($customerNumber)');
    debugPrint('Message: Dear $customerName, a payment of ${Money.format(pendingAmountMinor, currency)} is pending for your recent repair order. Kindly complete the transaction at your earliest convenience.');
    debugPrint('----------------------------------------');
    return true;
  }
}
