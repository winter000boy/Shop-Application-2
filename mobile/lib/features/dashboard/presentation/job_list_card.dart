import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:repair_shop_app/core/l10n/app_strings.dart';
import 'package:repair_shop_app/core/money.dart';
import 'package:repair_shop_app/core/theme/app_theme.dart';
import 'package:repair_shop_app/database/app_database.dart';
import 'package:repair_shop_app/database/local_cache.dart';
import 'package:repair_shop_app/features/repair_orders/presentation/add_order_screen.dart';
import 'package:repair_shop_app/features/repair_orders/presentation/orders_notifier.dart';
import 'package:repair_shop_app/services/whatsapp_service.dart';
import 'package:url_launcher/url_launcher.dart';

Color statusColor(String status) {
  switch (status) {
    case OrderStatus.pending:
      return AppTheme.warningColor;
    case OrderStatus.repaired:
      return AppTheme.successColor;
    case OrderStatus.delivered:
      return AppTheme.primaryColor;
    case OrderStatus.cancelled:
      return AppTheme.dangerColor;
    default:
      return Colors.grey;
  }
}

String statusLabel(BuildContext context, String status) {
  switch (status) {
    case OrderStatus.pending:
      return context.tr(S.pending);
    case OrderStatus.repaired:
      return context.tr(S.repaired);
    case OrderStatus.delivered:
      return context.tr(S.delivered);
    case OrderStatus.cancelled:
      return context.tr(S.cancelled);
    default:
      return status;
  }
}

/// One job on the home list: who, which device, what's wrong, money, dates, and quick actions.
class JobListCard extends ConsumerWidget {
  final Order order;
  final int photoCount;

  const JobListCard({super.key, required this.order, this.photoCount = 0});

  void _snack(BuildContext context, String text, Color color) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(text), backgroundColor: color, behavior: SnackBarBehavior.floating));
  }

  Future<void> _whatsapp(BuildContext context, Order o) async {
    final ok = await WhatsAppService.open(phone: o.customerNumber, message: WhatsAppService.jobMessage(o));
    if (!ok && context.mounted) _snack(context, context.tr(S.whatsappNotInstalled), AppTheme.warningColor);
  }

  Future<void> _changeStatus(BuildContext context, WidgetRef ref) async {
    final status = await showModalBottomSheet<String>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(title: Text(context.tr(S.changeStatus), style: const TextStyle(fontWeight: FontWeight.bold))),
            for (final s in OrderStatus.values)
              ListTile(
                leading: Icon(Icons.circle, size: 14, color: statusColor(s)),
                title: Text(statusLabel(context, s)),
                trailing: s == order.status ? const Icon(Icons.check) : null,
                onTap: () => Navigator.pop(ctx, s),
              ),
          ],
        ),
      ),
    );
    if (status == null || status == order.status || !context.mounted) return;
    final updated = await ref.read(ordersOperationsProvider).updateStatus(order, status);
    if (updated == null || !context.mounted) return;
    // Offer the matching customer message right away (repaired = ready for pickup, etc.)
    if (updated.notifyWhatsapp) await _whatsapp(context, updated);
  }

  Future<void> _delete(BuildContext context, WidgetRef ref) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('${context.tr(S.delete)}?'),
        content: Text('${order.customerName} • #${WhatsAppService.jobNumber(order)}'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(context.tr(S.cancel))),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppTheme.dangerColor),
            child: Text(context.tr(S.delete)),
          ),
        ],
      ),
    );
    if (confirm == true) await ref.read(ordersOperationsProvider).deleteOrder(order.id);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final secondary = isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary;
    final currency = LocalCache.getCurrencySymbol();
    final device = [order.brand, order.model].where((s) => s != null && s.trim().isNotEmpty).join(' ');
    final color = statusColor(order.status);
    final due = order.estimatePriceMinor - order.paidPriceMinor;
    final deliveryLate = order.estimatedDelivery != null &&
        order.status == OrderStatus.pending &&
        order.estimatedDelivery!.isBefore(DateUtils.dateOnly(DateTime.now()));

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder),
      ),
      color: isDark ? AppTheme.darkSurface : Colors.white,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => AddOrderScreen(order: order))),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 8, 6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Text('#${WhatsAppService.jobNumber(order)}',
                      style: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                  if (order.syncStatus != SyncStatus.synced) ...[
                    const SizedBox(width: 6),
                    const Tooltip(
                      message: 'Waiting to sync',
                      child: Icon(Icons.cloud_off_outlined, size: 14, color: AppTheme.warningColor),
                    ),
                  ],
                  if (photoCount > 0) ...[
                    const SizedBox(width: 8),
                    Icon(Icons.photo_camera_outlined, size: 14, color: secondary),
                    Text(' $photoCount', style: TextStyle(fontSize: 11, color: secondary)),
                  ],
                  const Spacer(),
                  InkWell(
                    onTap: () => _changeStatus(context, ref),
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(statusLabel(context, order.status),
                              style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold)),
                          Icon(Icons.arrow_drop_down, size: 16, color: color),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(order.customerName,
                            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                        Text(order.customerNumber, style: TextStyle(fontSize: 12, color: secondary)),
                        const SizedBox(height: 6),
                        if (device.isNotEmpty)
                          Text(device,
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis),
                        Text(order.deviceProblem,
                            maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13)),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(Money.format(order.estimatePriceMinor, currency),
                            style: const TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.primaryColor)),
                        if (due > 0 && order.status != OrderStatus.cancelled)
                          Text('Due ${Money.format(due, currency)}',
                              style: const TextStyle(fontSize: 11, color: AppTheme.dangerColor)),
                        const SizedBox(height: 8),
                        Text(DateFormat('dd MMM').format(order.repairDate),
                            style: TextStyle(fontSize: 11, color: secondary)),
                        if (order.estimatedDelivery != null)
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.event_available_outlined,
                                  size: 12, color: deliveryLate ? AppTheme.dangerColor : secondary),
                              const SizedBox(width: 2),
                              Text(DateFormat('dd MMM').format(order.estimatedDelivery!),
                                  style: TextStyle(
                                      fontSize: 11,
                                      color: deliveryLate ? AppTheme.dangerColor : secondary,
                                      fontWeight: deliveryLate ? FontWeight.bold : FontWeight.normal)),
                            ],
                          ),
                      ],
                    ),
                  ),
                ],
              ),
              const Divider(height: 16, thickness: 0.5),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  IconButton(
                    tooltip: context.tr(S.call),
                    icon: const Icon(Icons.call_outlined, size: 20),
                    onPressed: () => launchUrl(Uri(scheme: 'tel', path: order.customerNumber)),
                  ),
                  IconButton(
                    tooltip: context.tr(S.whatsapp),
                    icon: const Icon(Icons.chat_outlined, size: 20, color: Color(0xFF25D366)),
                    onPressed: () => _whatsapp(context, order),
                  ),
                  IconButton(
                    tooltip: context.tr(S.delete),
                    icon: const Icon(Icons.delete_outline, size: 20, color: AppTheme.dangerColor),
                    onPressed: () => _delete(context, ref),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
