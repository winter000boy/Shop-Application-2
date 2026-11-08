import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:repair_shop_app/core/brands.dart';
import 'package:repair_shop_app/core/l10n/app_strings.dart';
import 'package:repair_shop_app/core/money.dart';
import 'package:repair_shop_app/core/theme/app_theme.dart';
import 'package:repair_shop_app/database/app_database.dart';
import 'package:repair_shop_app/database/local_cache.dart';
import 'package:repair_shop_app/features/repair_orders/presentation/orders_notifier.dart';
import 'package:repair_shop_app/services/whatsapp_service.dart';
import 'package:repair_shop_app/shared/providers.dart';
import 'package:repair_shop_app/shared/widgets/photo_picker_grid.dart';

/// Job card: everything recorded when a customer hands over a device. Pass [order] to edit an existing one.
class AddOrderScreen extends ConsumerStatefulWidget {
  final Order? order;

  const AddOrderScreen({super.key, this.order});

  @override
  ConsumerState<AddOrderScreen> createState() => _AddOrderScreenState();
}

class _AddOrderScreenState extends ConsumerState<AddOrderScreen> {
  static const List<String> _kycDocTypes = [
    'Aadhaar Card', 'PAN Card', 'Voter ID', 'Driving Licence', 'Passport', 'Other',
  ];

  final _formKey = GlobalKey<FormState>();
  bool get _isEditing => widget.order != null;
  bool _saving = false;

  // Customer
  final _customerNameController = TextEditingController();
  final _customerNumberController = TextEditingController();
  final _alternateNumberController = TextEditingController();
  final _customerAddressController = TextEditingController();

  // Device
  final _brandController = TextEditingController();
  final _brandFocus = FocusNode();
  final _modelController = TextEditingController();
  final _imeiController = TextEditingController();
  final _deviceProblemController = TextEditingController();

  // Lock
  final _devicePasswordController = TextEditingController();
  String? _devicePattern;
  List<int> _patternPoints = [];

  // Price & delivery
  final _estimatePriceController = TextEditingController();
  final _paidPriceController = TextEditingController();
  DateTime? _estimatedDelivery;
  String _selectedStatus = OrderStatus.pending;
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();
  bool _reminderEnabled = false;

  // Accessories
  bool _accSim = false;
  bool _accSd = false;
  bool _accCover = false;
  bool _accCharger = false;
  bool _accBattery = false;
  final _accessoriesOtherController = TextEditingController();

  // Additional details & KYC
  final _descriptionController = TextEditingController();
  String? _kycDocType;

  // Photos
  List<OrderPhoto> _savedPhotos = [];
  final List<String> _newDevicePhotos = [];
  final List<String> _newKycPhotos = [];
  final List<OrderPhoto> _removedPhotos = [];
  bool _showPhotoError = false;

  // Messages
  bool _notifyWhatsapp = true;
  bool _notifyEmail = false;

  @override
  void initState() {
    super.initState();
    final order = widget.order;
    if (order == null) return;

    _selectedStatus = order.status;
    _selectedDate = order.repairDate;
    final timeParts = order.repairTime.split(':');
    if (timeParts.length >= 2) {
      _selectedTime = TimeOfDay(hour: int.parse(timeParts[0]), minute: int.parse(timeParts[1]));
    }
    _reminderEnabled = order.reminderEnabled;

    _customerNameController.text = order.customerName;
    _customerNumberController.text = order.customerNumber;
    _alternateNumberController.text = order.alternateNumber ?? '';
    _customerAddressController.text = order.customerAddress ?? '';

    _brandController.text = order.brand ?? '';
    _modelController.text = order.model ?? '';
    _imeiController.text = order.imei ?? '';
    _deviceProblemController.text = order.deviceProblem;
    _estimatedDelivery = order.estimatedDelivery;

    _estimatePriceController.text = Money.toInput(order.estimatePriceMinor);
    _paidPriceController.text = Money.toInput(order.paidPriceMinor);

    final secrets = ref.read(ordersOperationsProvider).revealDeviceSecrets(order);
    _devicePasswordController.text = secrets.password ?? '';
    _devicePattern = secrets.pattern;
    if (_devicePattern != null && _devicePattern!.isNotEmpty) {
      _patternPoints = _devicePattern!.split('-').map(int.parse).toList();
    }

    _descriptionController.text = order.description ?? '';
    _kycDocType = _kycDocTypes.contains(order.kycDocType) ? order.kycDocType : null;

    _accSim = order.accessoriesSim;
    _accSd = order.accessoriesSdCard;
    _accCover = order.accessoriesBackCover;
    _accCharger = order.accessoriesCharger;
    _accBattery = order.accessoriesBattery;
    _accessoriesOtherController.text = order.accessoriesOther ?? '';

    _notifyWhatsapp = order.notifyWhatsapp;
    _notifyEmail = order.notifyEmail;

    ref.read(databaseProvider).getPhotos(order.id).then((photos) {
      if (mounted) setState(() => _savedPhotos = photos);
    });
  }

  @override
  void dispose() {
    for (final c in [
      _customerNameController, _customerNumberController, _alternateNumberController, _customerAddressController,
      _brandController, _modelController, _imeiController, _deviceProblemController, _devicePasswordController,
      _estimatePriceController, _paidPriceController, _accessoriesOtherController, _descriptionController,
    ]) {
      c.dispose();
    }
    _brandFocus.dispose();
    super.dispose();
  }

  List<OrderPhoto> _savedOfKind(String kind) => _savedPhotos.where((p) => p.kind == kind).toList();

  int get _devicePhotoCount => _savedOfKind(PhotoKind.device).length + _newDevicePhotos.length;

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  Future<void> _selectTime() async {
    final picked = await showTimePicker(context: context, initialTime: _selectedTime);
    if (picked != null) setState(() => _selectedTime = picked);
  }

  Future<void> _selectDeliveryDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _estimatedDelivery ?? now.add(const Duration(days: 1)),
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 2),
    );
    if (picked != null) setState(() => _estimatedDelivery = picked);
  }

  // Visual 3x3 pattern designer modal bottom drawer
  void _openPatternGridSelector() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).cardColor,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(context.tr(S.drawPattern), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text(
                    _patternPoints.isEmpty ? '1 ➔ 2 ➔ 3 …' : _patternPoints.join(' ➔ '),
                    style: const TextStyle(fontSize: 13, color: AppTheme.primaryColor),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    height: 220,
                    width: 220,
                    child: GridView.builder(
                      itemCount: 9,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        crossAxisSpacing: 20,
                        mainAxisSpacing: 20,
                      ),
                      itemBuilder: (context, index) {
                        final dotNumber = index + 1;
                        final isSelected = _patternPoints.contains(dotNumber);
                        final selectedIndex = _patternPoints.indexOf(dotNumber);
                        return GestureDetector(
                          onTap: () {
                            setModalState(() {
                              setState(() {
                                if (isSelected) {
                                  _patternPoints.remove(dotNumber);
                                } else {
                                  _patternPoints.add(dotNumber);
                                }
                              });
                            });
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              color: isSelected ? AppTheme.primaryColor : Colors.grey.withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isSelected ? AppTheme.primaryLight : Colors.grey.shade400,
                                width: 2,
                              ),
                            ),
                            child: Center(
                              child: Text(
                                isSelected ? '${selectedIndex + 1}' : '$dotNumber',
                                style: isSelected
                                    ? const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)
                                    : TextStyle(color: Colors.grey.shade600, fontSize: 12),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      TextButton(
                        onPressed: () {
                          setModalState(() {
                            setState(() {
                              _patternPoints.clear();
                              _devicePattern = null;
                            });
                          });
                        },
                        child: const Text('Clear'),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          setState(() => _devicePattern = _patternPoints.isEmpty ? null : _patternPoints.join('-'));
                          Navigator.pop(context);
                        },
                        child: Text(context.tr(S.save)),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  String? _trimmedOrNull(TextEditingController c) {
    final v = c.text.trim();
    return v.isEmpty ? null : v;
  }

  Future<void> _handleSubmitOrder() async {
    final formValid = _formKey.currentState!.validate();
    // A photo of the device's condition at handover protects the shop in disputes, so new job cards need one
    final photoMissing = !_isEditing && _devicePhotoCount == 0;
    setState(() => _showPhotoError = photoMissing);
    if (!formValid || photoMissing) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(photoMissing ? context.tr(S.photoRequired) : context.tr(S.required)),
        backgroundColor: AppTheme.dangerColor,
        behavior: SnackBarBehavior.floating,
      ));
      return;
    }

    setState(() => _saving = true);
    final timeStr =
        '${_selectedTime.hour.toString().padLeft(2, '0')}:${_selectedTime.minute.toString().padLeft(2, '0')}';
    final input = OrderInput(
      status: _selectedStatus,
      repairDate: _selectedDate,
      repairTime: timeStr,
      reminderEnabled: _reminderEnabled,
      customerName: _customerNameController.text.trim(),
      customerNumber: _customerNumberController.text.trim(),
      customerAddress: _trimmedOrNull(_customerAddressController),
      alternateNumber: _trimmedOrNull(_alternateNumberController),
      brand: Brands.normalize(_brandController.text),
      model: _trimmedOrNull(_modelController),
      imei: _trimmedOrNull(_imeiController),
      deviceProblem: _deviceProblemController.text.trim(),
      estimatedDelivery: _estimatedDelivery,
      estimatePriceMinor: Money.parseMinor(_estimatePriceController.text)!,
      paidPriceMinor: Money.parseMinor(_paidPriceController.text.trim().isEmpty ? '0' : _paidPriceController.text)!,
      devicePassword: _trimmedOrNull(_devicePasswordController),
      devicePattern: _devicePattern,
      description: _trimmedOrNull(_descriptionController),
      accessoriesSim: _accSim,
      accessoriesSdCard: _accSd,
      accessoriesBackCover: _accCover,
      accessoriesCharger: _accCharger,
      accessoriesBattery: _accBattery,
      accessoriesOther: _trimmedOrNull(_accessoriesOtherController),
      kycDocType: _kycDocType,
      notifyWhatsapp: _notifyWhatsapp,
      notifyEmail: _notifyEmail,
    );
    final photos = PhotoChanges(
      newDevicePhotos: List.of(_newDevicePhotos),
      newKycPhotos: List.of(_newKycPhotos),
      removed: List.of(_removedPhotos),
    );

    final ops = ref.read(ordersOperationsProvider);
    final previousStatus = widget.order?.status;
    final Order? saved = _isEditing
        ? await ops.updateOrder(widget.order!.id, input, photos: photos)
        : await ops.createOrder(input, photos: photos);
    if (!mounted) return;
    setState(() => _saving = false);

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(context.tr(S.jobSaved)),
      backgroundColor: AppTheme.successColor,
      behavior: SnackBarBehavior.floating,
    ));

    // New job, or the status changed: hand the shop a ready-made WhatsApp message to send
    final shouldMessage = saved != null && _notifyWhatsapp && (!_isEditing || previousStatus != saved.status);
    if (shouldMessage) {
      final opened = await WhatsAppService.open(phone: saved.customerNumber, message: WhatsAppService.jobMessage(saved));
      if (!opened && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(context.tr(S.whatsappNotInstalled)),
          backgroundColor: AppTheme.warningColor,
          behavior: SnackBarBehavior.floating,
        ));
      }
    }
    if (mounted) Navigator.pop(context);
  }

  String? _requiredValidator(String? val) => (val == null || val.trim().isEmpty) ? context.tr(S.required) : null;

  String? _phoneValidator(String? val, {required bool required}) {
    final v = val?.trim() ?? '';
    if (v.isEmpty) return required ? context.tr(S.required) : null;
    final digits = v.replaceAll(RegExp(r'[\s\-+()]'), '');
    if (!RegExp(r'^\d{8,15}$').hasMatch(digits)) return context.tr(S.invalidNumber);
    return null;
  }

  String? _moneyValidator(String? val, {required bool required}) {
    if (val == null || val.trim().isEmpty) return required ? context.tr(S.required) : null;
    return Money.parseMinor(val) == null ? context.tr(S.required) : null;
  }

  Widget _brandField() {
    return RawAutocomplete<String>(
      textEditingController: _brandController,
      focusNode: _brandFocus,
      optionsBuilder: (value) {
        final q = value.text.trim().toLowerCase();
        if (q.isEmpty) return Brands.common;
        return Brands.common.where((b) => b.toLowerCase().contains(q));
      },
      fieldViewBuilder: (context, controller, focusNode, onSubmitted) => TextFormField(
        controller: controller,
        focusNode: focusNode,
        textCapitalization: TextCapitalization.words,
        decoration: InputDecoration(
          labelText: '${context.tr(S.brandName)} *',
          prefixIcon: const Icon(Icons.branding_watermark_outlined),
        ),
        validator: _requiredValidator,
      ),
      optionsViewBuilder: (context, onSelected, options) => Align(
        alignment: Alignment.topLeft,
        child: Material(
          elevation: 4,
          borderRadius: BorderRadius.circular(12),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 240, maxWidth: 320),
            child: ListView(
              padding: EdgeInsets.zero,
              shrinkWrap: true,
              children: [
                for (final o in options) ListTile(dense: true, title: Text(o), onTap: () => onSelected(o)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _accessoryChip(String label, bool value, ValueChanged<bool> onChanged) {
    return FilterChip(
      label: Text(label),
      selected: value,
      onSelected: onChanged,
      selectedColor: AppTheme.primaryColor.withValues(alpha: 0.2),
      checkmarkColor: AppTheme.primaryColor,
    );
  }

  @override
  Widget build(BuildContext context) {
    final currency = LocalCache.getCurrencySymbol();
    final statusLabels = {
      OrderStatus.pending: context.tr(S.pending),
      OrderStatus.repaired: context.tr(S.repaired),
      OrderStatus.delivered: context.tr(S.delivered),
      OrderStatus.cancelled: context.tr(S.cancelled),
    };

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing
            ? '${context.tr(S.editJobCard)} #${widget.order!.id.substring(0, 8).toUpperCase()}'
            : context.tr(S.newJobCard)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // --- CUSTOMER ---
              _buildSectionCard(
                title: context.tr(S.customerDetails),
                icon: Icons.person_outline,
                children: [
                  TextFormField(
                    controller: _customerNameController,
                    textCapitalization: TextCapitalization.words,
                    decoration: InputDecoration(
                      labelText: '${context.tr(S.customerName)} *',
                      prefixIcon: const Icon(Icons.person_outline),
                    ),
                    validator: _requiredValidator,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _customerNumberController,
                    keyboardType: TextInputType.phone,
                    decoration: InputDecoration(
                      labelText: '${context.tr(S.mobileNumber)} *',
                      prefixIcon: const Icon(Icons.phone_android_outlined),
                    ),
                    validator: (v) => _phoneValidator(v, required: true),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _alternateNumberController,
                    keyboardType: TextInputType.phone,
                    decoration: InputDecoration(
                      labelText: context.tr(S.alternateContact),
                      prefixIcon: const Icon(Icons.contact_phone_outlined),
                    ),
                    validator: (v) => _phoneValidator(v, required: false),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _customerAddressController,
                    textCapitalization: TextCapitalization.sentences,
                    maxLines: 2,
                    decoration: InputDecoration(
                      labelText: context.tr(S.address),
                      prefixIcon: const Icon(Icons.location_on_outlined),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // --- DEVICE ---
              _buildSectionCard(
                title: context.tr(S.deviceDetails),
                icon: Icons.phone_iphone_outlined,
                children: [
                  _brandField(),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _modelController,
                    textCapitalization: TextCapitalization.words,
                    decoration: InputDecoration(
                      labelText: '${context.tr(S.modelName)} *',
                      prefixIcon: const Icon(Icons.smartphone_outlined),
                    ),
                    validator: _requiredValidator,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _imeiController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(15)],
                    decoration: InputDecoration(
                      labelText: context.tr(S.imei),
                      helperText: '*#06#',
                      prefixIcon: const Icon(Icons.qr_code_2_outlined),
                    ),
                    validator: (v) {
                      final value = v?.trim() ?? '';
                      if (value.isEmpty) return null;
                      return value.length == 15 ? null : context.tr(S.invalidImei);
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _deviceProblemController,
                    textCapitalization: TextCapitalization.sentences,
                    maxLines: 3,
                    decoration: InputDecoration(
                      labelText: '${context.tr(S.problem)} *',
                      prefixIcon: const Icon(Icons.report_problem_outlined),
                    ),
                    validator: _requiredValidator,
                  ),
                  const SizedBox(height: 16),
                  Text('${context.tr(S.devicePhotos)}${_isEditing ? '' : ' *'}',
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  PhotoPickerGrid(
                    saved: _savedOfKind(PhotoKind.device),
                    added: _newDevicePhotos,
                    errorText: _showPhotoError && _devicePhotoCount == 0 ? context.tr(S.photoRequired) : null,
                    onAdd: (path) => setState(() {
                      _newDevicePhotos.add(path);
                      _showPhotoError = false;
                    }),
                    onRemoveAdded: (path) => setState(() => _newDevicePhotos.remove(path)),
                    onRemoveSaved: (photo) => setState(() {
                      _savedPhotos.remove(photo);
                      _removedPhotos.add(photo);
                    }),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // --- SCREEN LOCK ---
              _buildSectionCard(
                title: context.tr(S.screenLock),
                icon: Icons.lock_outline,
                children: [
                  TextFormField(
                    controller: _devicePasswordController,
                    decoration: InputDecoration(
                      labelText: context.tr(S.pinPassword),
                      prefixIcon: const Icon(Icons.password_outlined),
                    ),
                  ),
                  const SizedBox(height: 16),
                  OutlinedButton.icon(
                    onPressed: _openPatternGridSelector,
                    icon: const Icon(Icons.pattern_outlined),
                    label: Text(_devicePattern == null
                        ? context.tr(S.drawPattern)
                        : '${context.tr(S.patternSaved)}: ${_devicePattern!.replaceAll('-', ' ➔ ')}'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // --- ACCESSORIES ---
              _buildSectionCard(
                title: context.tr(S.accessoriesReceived),
                icon: Icons.checklist_outlined,
                children: [
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _accessoryChip(context.tr(S.sim), _accSim, (v) => setState(() => _accSim = v)),
                      _accessoryChip(context.tr(S.memoryCard), _accSd, (v) => setState(() => _accSd = v)),
                      _accessoryChip(context.tr(S.charger), _accCharger, (v) => setState(() => _accCharger = v)),
                      _accessoryChip(context.tr(S.battery), _accBattery, (v) => setState(() => _accBattery = v)),
                      _accessoryChip(context.tr(S.backCover), _accCover, (v) => setState(() => _accCover = v)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _accessoriesOtherController,
                    decoration: InputDecoration(
                      labelText: context.tr(S.otherAccessories),
                      prefixIcon: const Icon(Icons.headphones_outlined),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // --- ESTIMATE, DELIVERY, STATUS ---
              _buildSectionCard(
                title: context.tr(S.priceDelivery),
                icon: Icons.receipt_long_outlined,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _estimatePriceController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: InputDecoration(labelText: '${context.tr(S.estimate)} ($currency) *'),
                          validator: (v) => _moneyValidator(v, required: true),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _paidPriceController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: InputDecoration(labelText: '${context.tr(S.advance)} ($currency)'),
                          validator: (v) => _moneyValidator(v, required: false),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.event_available_outlined, color: AppTheme.primaryColor),
                    title: Text(context.tr(S.estimatedDelivery)),
                    subtitle: Text(_estimatedDelivery == null
                        ? context.tr(S.notSet)
                        : DateFormat('EEE, dd MMM yyyy').format(_estimatedDelivery!)),
                    trailing: _estimatedDelivery == null
                        ? const Icon(Icons.chevron_right)
                        : IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () => setState(() => _estimatedDelivery = null),
                          ),
                    onTap: _selectDeliveryDate,
                  ),
                  const Divider(height: 24, thickness: 0.5),
                  DropdownButtonFormField<String>(
                    initialValue: _selectedStatus,
                    decoration: InputDecoration(labelText: context.tr(S.jobStatus)),
                    items: OrderStatus.values
                        .map((st) => DropdownMenuItem(value: st, child: Text(statusLabels[st] ?? st)))
                        .toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => _selectedStatus = val);
                    },
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _selectDate,
                          icon: const Icon(Icons.calendar_month_outlined),
                          label: Text(DateFormat('dd MMM yyyy').format(_selectedDate)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _selectTime,
                          icon: const Icon(Icons.access_time_outlined),
                          label: Text(_selectedTime.format(context)),
                        ),
                      ),
                    ],
                  ),
                  SwitchListTile(
                    title: const Text('Reminder'),
                    value: _reminderEnabled,
                    contentPadding: EdgeInsets.zero,
                    onChanged: (val) => setState(() => _reminderEnabled = val),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // --- ADDITIONAL DETAILS ---
              _buildSectionCard(
                title: context.tr(S.additionalDetails),
                icon: Icons.notes_outlined,
                children: [
                  TextFormField(
                    controller: _descriptionController,
                    maxLines: 4,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: InputDecoration(
                      hintText: context.tr(S.additionalDetails),
                      prefixIcon: const Icon(Icons.description_outlined),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // --- KYC ---
              _buildSectionCard(
                title: context.tr(S.kycDetails),
                icon: Icons.badge_outlined,
                children: [
                  DropdownButtonFormField<String>(
                    initialValue: _kycDocType,
                    decoration: InputDecoration(labelText: context.tr(S.kycDocType)),
                    items: _kycDocTypes.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                    onChanged: (val) => setState(() => _kycDocType = val),
                  ),
                  const SizedBox(height: 16),
                  Text(context.tr(S.kycPhoto), style: const TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  PhotoPickerGrid(
                    saved: _savedOfKind(PhotoKind.kyc),
                    added: _newKycPhotos,
                    maxPhotos: 2,
                    onAdd: (path) => setState(() => _newKycPhotos.add(path)),
                    onRemoveAdded: (path) => setState(() => _newKycPhotos.remove(path)),
                    onRemoveSaved: (photo) => setState(() {
                      _savedPhotos.remove(photo);
                      _removedPhotos.add(photo);
                    }),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // --- MESSAGES ---
              _buildSectionCard(
                title: context.tr(S.whatsapp),
                icon: Icons.chat_outlined,
                children: [
                  CheckboxListTile(
                    title: Text(context.tr(S.sendWhatsapp)),
                    value: _notifyWhatsapp,
                    contentPadding: EdgeInsets.zero,
                    onChanged: (val) => setState(() => _notifyWhatsapp = val ?? false),
                  ),
                  CheckboxListTile(
                    title: const Text('Email'),
                    value: _notifyEmail,
                    contentPadding: EdgeInsets.zero,
                    onChanged: (val) => setState(() => _notifyEmail = val ?? false),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              ElevatedButton(
                onPressed: _saving ? null : _handleSubmitOrder,
                child: _saving
                    ? const SizedBox(
                        width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : Text(_isEditing ? context.tr(S.updateJobCard) : context.tr(S.saveJobCard)),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionCard({required String title, required IconData icon, required List<Widget> children}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder),
      ),
      color: isDark ? AppTheme.darkSurface : Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 20, color: AppTheme.primaryColor),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(title,
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, letterSpacing: -0.3)),
                ),
              ],
            ),
            const Divider(height: 24, thickness: 0.5),
            ...children,
          ],
        ),
      ),
    );
  }
}
