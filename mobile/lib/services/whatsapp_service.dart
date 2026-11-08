import 'package:intl/intl.dart';
import 'package:repair_shop_app/core/money.dart';
import 'package:repair_shop_app/database/app_database.dart';
import 'package:repair_shop_app/database/local_cache.dart';
import 'package:url_launcher/url_launcher.dart';

/// Opens WhatsApp with a pre-filled message. The shop reviews it and taps Send inside WhatsApp:
/// nothing is sent automatically and no WhatsApp Business API account is needed.
class WhatsAppService {
  /// Digits-only international number for wa.me. A 10-digit local number gets the shop's country code.
  static String? normalizeNumber(String raw, {String? countryCode}) {
    var digits = raw.replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty) return null;
    if (digits.startsWith('00')) digits = digits.substring(2);
    if (digits.length == 11 && digits.startsWith('0')) digits = digits.substring(1);
    if (digits.length == 10) {
      final cc = (countryCode ?? LocalCache.getCountryCode()).replaceAll(RegExp(r'\D'), '');
      digits = '$cc$digits';
    }
    return digits.length >= 8 ? digits : null;
  }

  static Uri chatUri({String? phone, required String message}) {
    final number = phone == null ? null : normalizeNumber(phone);
    final path = number ?? '';
    return Uri.parse('https://wa.me/$path?text=${Uri.encodeComponent(message)}');
  }

  /// Returns false if no app could open the link (WhatsApp missing and no browser).
  static Future<bool> open({String? phone, required String message}) {
    return launchUrl(chatUri(phone: phone, message: message), mode: LaunchMode.externalApplication);
  }

  static String jobNumber(Order order) => order.id.substring(0, 8).toUpperCase();

  /// Customer message matching the job's current status.
  static String jobMessage(Order order) {
    final shop = LocalCache.getShopName() ?? 'our shop';
    final currency = LocalCache.getCurrencySymbol();
    final device = [order.brand, order.model].where((s) => s != null && s.trim().isNotEmpty).join(' ');
    final deviceText = device.isEmpty ? 'your device' : 'your $device';
    final due = order.estimatePriceMinor - order.paidPriceMinor;
    final b = StringBuffer('Hello ${order.customerName},\n\n');

    switch (order.status) {
      case OrderStatus.repaired:
        b.writeln('Good news! $deviceText is repaired and ready for pickup.');
        b.writeln('Job No: ${jobNumber(order)}');
        b.writeln('Total: ${Money.format(order.estimatePriceMinor, currency)}');
        if (due > 0) b.writeln('Balance to pay: ${Money.format(due, currency)}');
      case OrderStatus.delivered:
        b.writeln('Thank you! $deviceText (Job No: ${jobNumber(order)}) has been delivered.');
        b.writeln('We hope to serve you again.');
      case OrderStatus.cancelled:
        b.writeln('The repair job for $deviceText (Job No: ${jobNumber(order)}) has been cancelled.');
        b.writeln('Please collect your device from the shop.');
      default:
        b.writeln('We have received $deviceText for repair.');
        b.writeln('Job No: ${jobNumber(order)}');
        b.writeln('Problem: ${order.deviceProblem}');
        b.writeln('Estimate: ${Money.format(order.estimatePriceMinor, currency)}');
        if (order.paidPriceMinor > 0) b.writeln('Advance paid: ${Money.format(order.paidPriceMinor, currency)}');
        if (order.estimatedDelivery != null) {
          b.writeln('Expected delivery: ${DateFormat('dd MMM yyyy').format(order.estimatedDelivery!)}');
        }
    }
    b.write('\n- $shop');
    final shopPhone = LocalCache.getMobileNumber();
    if (shopPhone != null && shopPhone.isNotEmpty) b.write(' (${LocalCache.getCountryCode()} $shopPhone)');
    return b.toString();
  }

  static String offerMessage(Offer offer) {
    final shop = LocalCache.getShopName() ?? '';
    final b = StringBuffer('🎉 ${offer.title}\n');
    if (offer.discount != null && offer.discount!.isNotEmpty) b.writeln(offer.discount);
    if (offer.details != null && offer.details!.isNotEmpty) b.writeln(offer.details);
    if (offer.validTill != null) b.writeln('Valid till ${DateFormat('dd MMM yyyy').format(offer.validTill!)}');
    if (shop.isNotEmpty) b.write('\n- $shop');
    return b.toString();
  }
}
