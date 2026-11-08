import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:repair_shop_app/core/l10n/app_strings.dart';
import 'package:repair_shop_app/core/theme/app_theme.dart';
import 'package:repair_shop_app/database/app_database.dart';
import 'package:repair_shop_app/services/whatsapp_service.dart';
import 'package:repair_shop_app/shared/providers.dart';
import 'package:uuid/uuid.dart';

final offersProvider = StreamProvider.autoDispose<List<Offer>>((ref) => ref.watch(databaseProvider).watchOffers());

/// Shop offers and promotions: add, edit, switch on/off, delete, and share on WhatsApp.
class OffersScreen extends ConsumerWidget {
  const OffersScreen({super.key});

  static bool isExpired(Offer o) =>
      o.validTill != null && o.validTill!.isBefore(DateUtils.dateOnly(DateTime.now()));

  Future<void> _edit(BuildContext context, WidgetRef ref, [Offer? existing]) async {
    final offer = await showModalBottomSheet<Offer>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _OfferForm(existing: existing),
    );
    if (offer != null) await ref.read(databaseProvider).upsertOffer(offer);
  }

  Future<void> _delete(BuildContext context, WidgetRef ref, Offer offer) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('${context.tr(S.delete)}?'),
        content: Text(offer.title),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(context.tr(S.cancel))),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: Text(context.tr(S.delete))),
        ],
      ),
    );
    if (ok == true) await ref.read(databaseProvider).deleteOffer(offer.id);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final offers = ref.watch(offersProvider);
    return Scaffold(
      appBar: AppBar(title: Text(context.tr(S.offers))),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _edit(context, ref),
        icon: const Icon(Icons.add),
        label: Text(context.tr(S.addOffer)),
      ),
      body: offers.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
        data: (list) {
          if (list.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.local_offer_outlined, size: 64, color: Colors.grey.shade400),
                  const SizedBox(height: 12),
                  Text(context.tr(S.noOffers)),
                ],
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
            itemCount: list.length,
            itemBuilder: (context, i) {
              final o = list[i];
              final expired = isExpired(o);
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 8, 4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(o.title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          ),
                          Switch(
                            value: o.active,
                            onChanged: (v) => ref.read(databaseProvider).upsertOffer(
                                  o.copyWith(active: v, updatedAt: DateTime.now().toUtc()),
                                ),
                          ),
                        ],
                      ),
                      if (o.discount != null && o.discount!.isNotEmpty)
                        Text(o.discount!,
                            style: const TextStyle(color: AppTheme.successColor, fontWeight: FontWeight.bold)),
                      if (o.details != null && o.details!.isNotEmpty)
                        Padding(padding: const EdgeInsets.only(top: 4), child: Text(o.details!)),
                      Row(
                        children: [
                          if (o.validTill != null)
                            Text(
                              '${context.tr(S.validTill)}: ${DateFormat('dd MMM yyyy').format(o.validTill!)}',
                              style: TextStyle(
                                fontSize: 12,
                                color: expired ? AppTheme.dangerColor : Colors.grey,
                                fontWeight: expired ? FontWeight.bold : FontWeight.normal,
                              ),
                            ),
                          const Spacer(),
                          IconButton(
                            tooltip: context.tr(S.shareOffer),
                            icon: const Icon(Icons.chat_outlined, color: Color(0xFF25D366)),
                            onPressed: () => WhatsAppService.open(message: WhatsAppService.offerMessage(o)),
                          ),
                          IconButton(
                            tooltip: context.tr(S.edit),
                            icon: const Icon(Icons.edit_outlined),
                            onPressed: () => _edit(context, ref, o),
                          ),
                          IconButton(
                            tooltip: context.tr(S.delete),
                            icon: const Icon(Icons.delete_outline, color: AppTheme.dangerColor),
                            onPressed: () => _delete(context, ref, o),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _OfferForm extends StatefulWidget {
  final Offer? existing;

  const _OfferForm({this.existing});

  @override
  State<_OfferForm> createState() => _OfferFormState();
}

class _OfferFormState extends State<_OfferForm> {
  final _formKey = GlobalKey<FormState>();
  late final _title = TextEditingController(text: widget.existing?.title);
  late final _discount = TextEditingController(text: widget.existing?.discount);
  late final _details = TextEditingController(text: widget.existing?.details);
  late DateTime? _validTill = widget.existing?.validTill;
  late bool _active = widget.existing?.active ?? true;

  @override
  void dispose() {
    _title.dispose();
    _discount.dispose();
    _details.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    final now = DateTime.now().toUtc();
    String? opt(TextEditingController c) => c.text.trim().isEmpty ? null : c.text.trim();
    Navigator.pop(
      context,
      Offer(
        id: widget.existing?.id ?? const Uuid().v4(),
        title: _title.text.trim(),
        details: opt(_details),
        discount: opt(_discount),
        validTill: _validTill,
        active: _active,
        createdAt: widget.existing?.createdAt ?? now,
        updatedAt: now,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 16, 16, MediaQuery.of(context).viewInsets.bottom + 16),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(widget.existing == null ? context.tr(S.addOffer) : context.tr(S.editOffer),
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              TextFormField(
                controller: _title,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(labelText: '${context.tr(S.offerTitle)} *'),
                validator: (v) => (v == null || v.trim().isEmpty) ? context.tr(S.required) : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _discount,
                decoration: InputDecoration(labelText: context.tr(S.discount), hintText: '10% off / ₹200 off'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _details,
                maxLines: 3,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(labelText: context.tr(S.offerDetails)),
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.event_outlined),
                title: Text(context.tr(S.validTill)),
                subtitle: Text(_validTill == null ? context.tr(S.notSet) : DateFormat('dd MMM yyyy').format(_validTill!)),
                trailing: _validTill == null
                    ? null
                    : IconButton(icon: const Icon(Icons.clear), onPressed: () => setState(() => _validTill = null)),
                onTap: () async {
                  final now = DateTime.now();
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _validTill ?? now.add(const Duration(days: 7)),
                    firstDate: DateTime(now.year - 1),
                    lastDate: DateTime(now.year + 3),
                  );
                  if (picked != null) setState(() => _validTill = picked);
                },
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(context.tr(S.active)),
                value: _active,
                onChanged: (v) => setState(() => _active = v),
              ),
              const SizedBox(height: 8),
              ElevatedButton(onPressed: _save, child: Text(context.tr(S.save))),
            ],
          ),
        ),
      ),
    );
  }
}
