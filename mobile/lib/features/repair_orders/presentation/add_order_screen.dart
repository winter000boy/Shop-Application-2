import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:repair_shop_app/core/theme/app_theme.dart';
import 'package:repair_shop_app/database/app_database.dart';
import 'package:repair_shop_app/database/local_cache.dart';
import 'package:repair_shop_app/features/repair_orders/presentation/orders_notifier.dart';

class AddOrderScreen extends ConsumerStatefulWidget {
  final Order? order; // Pass existing order to transition into "Edit" mode

  const AddOrderScreen({super.key, this.order});

  @override
  ConsumerState<AddOrderScreen> createState() => _AddOrderScreenState();
}

class _AddOrderScreenState extends ConsumerState<AddOrderScreen> {
  final _formKey = GlobalKey<FormState>();
  bool get _isEditing => widget.order != null;

  // Controllers
  final _customerNameController = TextEditingController();
  final _customerNumberController = TextEditingController();
  final _customerAddressController = TextEditingController();
  final _deviceProblemController = TextEditingController();
  final _estimatePriceController = TextEditingController();
  final _paidPriceController = TextEditingController();
  final _devicePasswordController = TextEditingController();
  final _descriptionController = TextEditingController();

  // Section 1: Order Details States
  String _selectedStatus = 'PENDING';
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();
  bool _reminderEnabled = false;

  // Section 3: Pattern Selector States
  String? _devicePattern;
  List<int> _patternPoints = [];

  // Section 4: Accessories States
  bool _accSim = false;
  bool _accSd = false;
  bool _accCover = false;
  bool _accCharger = false;

  // Section 5: Notification States
  bool _notifyWhatsapp = true;
  bool _notifyEmail = false;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      final order = widget.order!;
      _selectedStatus = order.status;
      _selectedDate = order.repairDate;
      
      // Parse TimeOfDay
      final timeParts = order.repairTime.split(':');
      if (timeParts.length >= 2) {
        _selectedTime = TimeOfDay(
          hour: int.parse(timeParts[0]),
          minute: int.parse(timeParts[1]),
        );
      }

      _reminderEnabled = order.reminderEnabled;
      _customerNameController.text = order.customerName;
      _customerNumberController.text = order.customerNumber;
      _customerAddressController.text = order.customerAddress ?? '';
      _deviceProblemController.text = order.deviceProblem;
      _estimatePriceController.text = order.estimatePrice.toString();
      _paidPriceController.text = order.paidPrice.toString();
      _devicePasswordController.text = order.devicePassword ?? '';
      _devicePattern = order.devicePattern;
      if (_devicePattern != null && _devicePattern!.isNotEmpty) {
        _patternPoints = _devicePattern!.split('-').map(int.parse).toList();
      }
      _descriptionController.text = order.description ?? '';
      
      _accSim = order.accessoriesSim;
      _accSd = order.accessoriesSdCard;
      _accCover = order.accessoriesBackCover;
      _accCharger = order.accessoriesCharger;

      _notifyWhatsapp = order.notifyWhatsapp;
      _notifyEmail = order.notifyEmail;
    }
  }

  @override
  void dispose() {
    _customerNameController.dispose();
    _customerNumberController.dispose();
    _customerAddressController.dispose();
    _deviceProblemController.dispose();
    _estimatePriceController.dispose();
    _paidPriceController.dispose();
    _devicePasswordController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _selectTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    if (picked != null && picked != _selectedTime) {
      setState(() => _selectedTime = picked);
    }
  }

  // Visual 3x3 pattern designer modal bottom drawer
  void _openPatternGridSelector() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Draw Device Pattern',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _patternPoints.isEmpty
                        ? 'Tap dots in order to define a pattern'
                        : 'Selected dots: ${_patternPoints.join(' ➔ ')}',
                    style: const TextStyle(fontSize: 13, color: AppTheme.primaryColor),
                  ),
                  const SizedBox(height: 20),
                  // 3x3 grid dots
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
                              color: isSelected ? AppTheme.primaryColor : Colors.grey.withOpacity(0.1),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isSelected ? AppTheme.primaryLight : Colors.grey.shade400,
                                width: 2,
                              ),
                            ),
                            child: Center(
                              child: isSelected
                                  ? Text(
                                      '${selectedIndex + 1}',
                                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                    )
                                  : Text(
                                      '$dotNumber',
                                      style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
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
                          setState(() {
                            if (_patternPoints.isNotEmpty) {
                              _devicePattern = _patternPoints.join('-');
                            } else {
                              _devicePattern = null;
                            }
                          });
                          Navigator.pop(context);
                        },
                        child: const Text('Save Pattern'),
                      ),
                    ],
                  )
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _handleSubmitOrder() async {
    if (_formKey.currentState!.validate()) {
      final String timeStr = '${_selectedTime.hour.toString().padLeft(2, '0')}:${_selectedTime.minute.toString().padLeft(2, '0')}';
      final double estPrice = double.parse(_estimatePriceController.text);
      final double pPrice = double.parse(_paidPriceController.text);

      final ops = ref.read(ordersOperationsProvider);

      if (_isEditing) {
        await ops.updateOrder(
          id: widget.order!.id,
          status: _selectedStatus,
          repairDate: _selectedDate,
          repairTime: timeStr,
          reminderEnabled: _reminderEnabled,
          customerName: _customerNameController.text.trim(),
          customerNumber: _customerNumberController.text.trim(),
          customerAddress: _customerAddressController.text.trim(),
          deviceProblem: _deviceProblemController.text.trim(),
          estimatePrice: estPrice,
          paidPrice: pPrice,
          devicePassword: _devicePasswordController.text.trim(),
          devicePattern: _devicePattern,
          description: _descriptionController.text.trim(),
          accessoriesSim: _accSim,
          accessoriesSdCard: _accSd,
          accessoriesBackCover: _accCover,
          accessoriesCharger: _accCharger,
          notifyWhatsapp: _notifyWhatsapp,
          notifyEmail: _notifyEmail,
          createdAt: widget.order!.createdAt,
        );
      } else {
        await ops.createOrder(
          status: _selectedStatus,
          repairDate: _selectedDate,
          repairTime: timeStr,
          reminderEnabled: _reminderEnabled,
          customerName: _customerNameController.text.trim(),
          customerNumber: _customerNumberController.text.trim(),
          customerAddress: _customerAddressController.text.trim(),
          deviceProblem: _deviceProblemController.text.trim(),
          estimatePrice: estPrice,
          paidPrice: pPrice,
          devicePassword: _devicePasswordController.text.trim(),
          devicePattern: _devicePattern,
          description: _descriptionController.text.trim(),
          accessoriesSim: _accSim,
          accessoriesSdCard: _accSd,
          accessoriesBackCover: _accCover,
          accessoriesCharger: _accCharger,
          notifyWhatsapp: _notifyWhatsapp,
          notifyEmail: _notifyEmail,
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isEditing ? 'Order updated successfully' : 'Order created successfully'),
            backgroundColor: AppTheme.successColor,
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.pop(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currency = LocalCache.getCurrencySymbol();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Repair Order' : 'Add Repair Order'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // --- SECTION 1: ORDER DETAILS ---
              _buildSectionCard(
                title: 'Section 1 — Order Details',
                icon: Icons.info_outline,
                children: [
                  DropdownButtonFormField<String>(
                    value: _selectedStatus,
                    decoration: const InputDecoration(labelText: 'Order Status'),
                    items: ['PENDING', 'REPAIRED', 'DELIVERED', 'CANCELLED'].map((st) {
                      return DropdownMenuItem(value: st, child: Text(st));
                    }).toList(),
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
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _selectTime,
                          icon: const Icon(Icons.access_time_outlined),
                          label: Text(_selectedTime.format(context)),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SwitchListTile(
                    title: const Text('Enable Reminder Notification'),
                    value: _reminderEnabled,
                    activeColor: AppTheme.primaryColor,
                    contentPadding: EdgeInsets.zero,
                    onChanged: (val) => setState(() => _reminderEnabled = val),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // --- SECTION 2: CUSTOMER DETAILS ---
              _buildSectionCard(
                title: 'Section 2 — Customer Details',
                icon: Icons.person_outline,
                children: [
                  TextFormField(
                    controller: _customerNameController,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(
                      labelText: 'Customer Name *',
                      prefixIcon: Icon(Icons.person_outline),
                    ),
                    validator: (val) =>
                        (val == null || val.trim().isEmpty) ? 'Customer name is mandatory' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _customerNumberController,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      labelText: 'Customer Number *',
                      prefixIcon: Icon(Icons.phone_outlined),
                    ),
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) {
                        return 'Customer number is mandatory';
                      }
                      if (double.tryParse(val) == null) {
                        return 'Must contain only numeric digits';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _customerAddressController,
                    textCapitalization: TextCapitalization.sentences,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: 'Customer Address',
                      prefixIcon: Icon(Icons.location_on_outlined),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // --- SECTION 3: DEVICE INFORMATION ---
              _buildSectionCard(
                title: 'Section 3 — Device Information',
                icon: Icons.phone_android_outlined,
                children: [
                  TextFormField(
                    controller: _deviceProblemController,
                    textCapitalization: TextCapitalization.sentences,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Device Problem *',
                      prefixIcon: Icon(Icons.report_problem_outlined),
                    ),
                    validator: (val) =>
                        (val == null || val.trim().isEmpty) ? 'Device problem diagnostics is mandatory' : null,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _estimatePriceController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: 'Estimate Price ($currency) *',
                            prefixIcon: const Icon(Icons.sell_outlined),
                          ),
                          validator: (val) {
                            if (val == null || val.trim().isEmpty) return 'Required';
                            if (double.tryParse(val) == null) return 'Must be numeric';
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _paidPriceController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: 'Advance Paid ($currency) *',
                            prefixIcon: const Icon(Icons.payments_outlined),
                          ),
                          validator: (val) {
                            if (val == null || val.trim().isEmpty) return 'Required';
                            if (double.tryParse(val) == null) return 'Must be numeric';
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _devicePasswordController,
                    decoration: const InputDecoration(
                      labelText: 'Device Pin/Password (Optional)',
                      prefixIcon: Icon(Icons.password_outlined),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Device pattern custom widget
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _openPatternGridSelector,
                          icon: const Icon(Icons.pattern_outlined),
                          label: Text(_devicePattern == null
                              ? 'Draw Pattern (Optional)'
                              : 'Pattern Saved: $_devicePattern'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _descriptionController,
                    maxLines: 4,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: const InputDecoration(
                      labelText: 'Additional Description',
                      prefixIcon: Icon(Icons.description_outlined),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // --- SECTION 4: ACCESSORIES CHECKLIST ---
              _buildSectionCard(
                title: 'Section 4 — Accessories Checklist',
                icon: Icons.checklist_outlined,
                children: [
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      FilterChip(
                        label: const Text('SIM Present'),
                        selected: _accSim,
                        onSelected: (val) => setState(() => _accSim = val),
                        selectedColor: AppTheme.primaryColor.withOpacity(0.2),
                        checkmarkColor: AppTheme.primaryColor,
                      ),
                      FilterChip(
                        label: const Text('Memory Card'),
                        selected: _accSd,
                        onSelected: (val) => setState(() => _accSd = val),
                        selectedColor: AppTheme.primaryColor.withOpacity(0.2),
                        checkmarkColor: AppTheme.primaryColor,
                      ),
                      FilterChip(
                        label: const Text('Back Cover'),
                        selected: _accCover,
                        onSelected: (val) => setState(() => _accCover = val),
                        selectedColor: AppTheme.primaryColor.withOpacity(0.2),
                        checkmarkColor: AppTheme.primaryColor,
                      ),
                      FilterChip(
                        label: const Text('Charger Present'),
                        selected: _accCharger,
                        onSelected: (val) => setState(() => _accCharger = val),
                        selectedColor: AppTheme.primaryColor.withOpacity(0.2),
                        checkmarkColor: AppTheme.primaryColor,
                      ),
                    ],
                  )
                ],
              ),
              const SizedBox(height: 16),

              // --- SECTION 5: NOTIFICATIONS ---
              _buildSectionCard(
                title: 'Section 5 — Notifications Preferences',
                icon: Icons.notifications_outlined,
                children: [
                  CheckboxListTile(
                    title: const Text('Send Instant WhatsApp Message'),
                    value: _notifyWhatsapp,
                    activeColor: AppTheme.primaryColor,
                    contentPadding: EdgeInsets.zero,
                    onChanged: (val) {
                      if (val != null) setState(() => _notifyWhatsapp = val);
                    },
                  ),
                  CheckboxListTile(
                    title: const Text('Send Email Notification'),
                    value: _notifyEmail,
                    activeColor: AppTheme.primaryColor,
                    contentPadding: EdgeInsets.zero,
                    onChanged: (val) {
                      if (val != null) setState(() => _notifyEmail = val);
                    },
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Final submit button
              ElevatedButton(
                onPressed: _handleSubmitOrder,
                child: Text(_isEditing ? 'Update Repair Order' : 'Submit Repair Order'),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder,
          width: 1.0,
        ),
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
                Text(
                  title,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, letterSpacing: -0.3),
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
