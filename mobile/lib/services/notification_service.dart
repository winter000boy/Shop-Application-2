abstract class NotificationProvider {
  Future<bool> sendOrderReceived({
    required String customerName,
    required String customerNumber,
    required String orderId,
    required double estimatePrice,
    required String currency,
  });

  Future<bool> sendRepairCompleted({
    required String customerName,
    required String customerNumber,
    required String orderId,
    required double estimatePrice,
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
    required double pendingAmount,
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
    required double estimatePrice,
    required String currency,
  }) async {
    print('----------------------------------------');
    print('[WHATSAPP / EMAIL NOTIFICATION MOCK]');
    print('To: $customerName ($customerNumber)');
    print('Message: Hello $customerName, we have received your device (Order ID: $orderId). The estimated repair cost is $currency$estimatePrice. Thank you!');
    print('----------------------------------------');
    return true;
  }

  @override
  Future<bool> sendRepairCompleted({
    required String customerName,
    required String customerNumber,
    required String orderId,
    required double estimatePrice,
    required String currency,
  }) async {
    print('----------------------------------------');
    print('[WHATSAPP / EMAIL NOTIFICATION MOCK]');
    print('To: $customerName ($customerNumber)');
    print('Message: Great news $customerName! Your device under Order ID $orderId has been repaired successfully. Total payable: $currency$estimatePrice. You can collect it at your earliest convenience.');
    print('----------------------------------------');
    return true;
  }

  @override
  Future<bool> sendDeliveryReminder({
    required String customerName,
    required String customerNumber,
    required String orderId,
  }) async {
    print('----------------------------------------');
    print('[WHATSAPP / EMAIL NOTIFICATION MOCK]');
    print('To: $customerName ($customerNumber)');
    print('Message: Dear $customerName, this is a reminder to collect your repaired device (Order ID: $orderId) from our shop. See you soon!');
    print('----------------------------------------');
    return true;
  }

  @override
  Future<bool> sendPaymentPending({
    required String customerName,
    required String customerNumber,
    required double pendingAmount,
    required String currency,
  }) async {
    print('----------------------------------------');
    print('[WHATSAPP / EMAIL NOTIFICATION MOCK]');
    print('To: $customerName ($customerNumber)');
    print('Message: Dear $customerName, a payment of $currency$pendingAmount is pending for your recent repair order. Kindly complete the transaction at your earliest convenience.');
    print('----------------------------------------');
    return true;
  }
}
