// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $OrdersTable extends Orders with TableInfo<$OrdersTable, Order> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $OrdersTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
      'status', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _repairDateMeta =
      const VerificationMeta('repairDate');
  @override
  late final GeneratedColumn<DateTime> repairDate = GeneratedColumn<DateTime>(
      'repair_date', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _repairTimeMeta =
      const VerificationMeta('repairTime');
  @override
  late final GeneratedColumn<String> repairTime = GeneratedColumn<String>(
      'repair_time', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _reminderEnabledMeta =
      const VerificationMeta('reminderEnabled');
  @override
  late final GeneratedColumn<bool> reminderEnabled = GeneratedColumn<bool>(
      'reminder_enabled', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("reminder_enabled" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _customerNameMeta =
      const VerificationMeta('customerName');
  @override
  late final GeneratedColumn<String> customerName = GeneratedColumn<String>(
      'customer_name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _customerNumberMeta =
      const VerificationMeta('customerNumber');
  @override
  late final GeneratedColumn<String> customerNumber = GeneratedColumn<String>(
      'customer_number', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _customerAddressMeta =
      const VerificationMeta('customerAddress');
  @override
  late final GeneratedColumn<String> customerAddress = GeneratedColumn<String>(
      'customer_address', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _deviceProblemMeta =
      const VerificationMeta('deviceProblem');
  @override
  late final GeneratedColumn<String> deviceProblem = GeneratedColumn<String>(
      'device_problem', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _estimatePriceMinorMeta =
      const VerificationMeta('estimatePriceMinor');
  @override
  late final GeneratedColumn<int> estimatePriceMinor = GeneratedColumn<int>(
      'estimate_price_minor', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _paidPriceMinorMeta =
      const VerificationMeta('paidPriceMinor');
  @override
  late final GeneratedColumn<int> paidPriceMinor = GeneratedColumn<int>(
      'paid_price_minor', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _devicePasswordMeta =
      const VerificationMeta('devicePassword');
  @override
  late final GeneratedColumn<String> devicePassword = GeneratedColumn<String>(
      'device_password', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _devicePatternMeta =
      const VerificationMeta('devicePattern');
  @override
  late final GeneratedColumn<String> devicePattern = GeneratedColumn<String>(
      'device_pattern', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _descriptionMeta =
      const VerificationMeta('description');
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
      'description', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _accessoriesSimMeta =
      const VerificationMeta('accessoriesSim');
  @override
  late final GeneratedColumn<bool> accessoriesSim = GeneratedColumn<bool>(
      'accessories_sim', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("accessories_sim" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _accessoriesSdCardMeta =
      const VerificationMeta('accessoriesSdCard');
  @override
  late final GeneratedColumn<bool> accessoriesSdCard = GeneratedColumn<bool>(
      'accessories_sd_card', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("accessories_sd_card" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _accessoriesBackCoverMeta =
      const VerificationMeta('accessoriesBackCover');
  @override
  late final GeneratedColumn<bool> accessoriesBackCover = GeneratedColumn<bool>(
      'accessories_back_cover', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("accessories_back_cover" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _accessoriesChargerMeta =
      const VerificationMeta('accessoriesCharger');
  @override
  late final GeneratedColumn<bool> accessoriesCharger = GeneratedColumn<bool>(
      'accessories_charger', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("accessories_charger" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _notifyWhatsappMeta =
      const VerificationMeta('notifyWhatsapp');
  @override
  late final GeneratedColumn<bool> notifyWhatsapp = GeneratedColumn<bool>(
      'notify_whatsapp', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("notify_whatsapp" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _notifyEmailMeta =
      const VerificationMeta('notifyEmail');
  @override
  late final GeneratedColumn<bool> notifyEmail = GeneratedColumn<bool>(
      'notify_email', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("notify_email" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _syncStatusMeta =
      const VerificationMeta('syncStatus');
  @override
  late final GeneratedColumn<String> syncStatus = GeneratedColumn<String>(
      'sync_status', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant(SyncStatus.synced));
  static const VerificationMeta _localRevisionMeta =
      const VerificationMeta('localRevision');
  @override
  late final GeneratedColumn<int> localRevision = GeneratedColumn<int>(
      'local_revision', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        status,
        repairDate,
        repairTime,
        reminderEnabled,
        customerName,
        customerNumber,
        customerAddress,
        deviceProblem,
        estimatePriceMinor,
        paidPriceMinor,
        devicePassword,
        devicePattern,
        description,
        accessoriesSim,
        accessoriesSdCard,
        accessoriesBackCover,
        accessoriesCharger,
        notifyWhatsapp,
        notifyEmail,
        syncStatus,
        localRevision,
        createdAt,
        updatedAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'orders';
  @override
  VerificationContext validateIntegrity(Insertable<Order> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('status')) {
      context.handle(_statusMeta,
          status.isAcceptableOrUnknown(data['status']!, _statusMeta));
    } else if (isInserting) {
      context.missing(_statusMeta);
    }
    if (data.containsKey('repair_date')) {
      context.handle(
          _repairDateMeta,
          repairDate.isAcceptableOrUnknown(
              data['repair_date']!, _repairDateMeta));
    } else if (isInserting) {
      context.missing(_repairDateMeta);
    }
    if (data.containsKey('repair_time')) {
      context.handle(
          _repairTimeMeta,
          repairTime.isAcceptableOrUnknown(
              data['repair_time']!, _repairTimeMeta));
    } else if (isInserting) {
      context.missing(_repairTimeMeta);
    }
    if (data.containsKey('reminder_enabled')) {
      context.handle(
          _reminderEnabledMeta,
          reminderEnabled.isAcceptableOrUnknown(
              data['reminder_enabled']!, _reminderEnabledMeta));
    }
    if (data.containsKey('customer_name')) {
      context.handle(
          _customerNameMeta,
          customerName.isAcceptableOrUnknown(
              data['customer_name']!, _customerNameMeta));
    } else if (isInserting) {
      context.missing(_customerNameMeta);
    }
    if (data.containsKey('customer_number')) {
      context.handle(
          _customerNumberMeta,
          customerNumber.isAcceptableOrUnknown(
              data['customer_number']!, _customerNumberMeta));
    } else if (isInserting) {
      context.missing(_customerNumberMeta);
    }
    if (data.containsKey('customer_address')) {
      context.handle(
          _customerAddressMeta,
          customerAddress.isAcceptableOrUnknown(
              data['customer_address']!, _customerAddressMeta));
    }
    if (data.containsKey('device_problem')) {
      context.handle(
          _deviceProblemMeta,
          deviceProblem.isAcceptableOrUnknown(
              data['device_problem']!, _deviceProblemMeta));
    } else if (isInserting) {
      context.missing(_deviceProblemMeta);
    }
    if (data.containsKey('estimate_price_minor')) {
      context.handle(
          _estimatePriceMinorMeta,
          estimatePriceMinor.isAcceptableOrUnknown(
              data['estimate_price_minor']!, _estimatePriceMinorMeta));
    } else if (isInserting) {
      context.missing(_estimatePriceMinorMeta);
    }
    if (data.containsKey('paid_price_minor')) {
      context.handle(
          _paidPriceMinorMeta,
          paidPriceMinor.isAcceptableOrUnknown(
              data['paid_price_minor']!, _paidPriceMinorMeta));
    } else if (isInserting) {
      context.missing(_paidPriceMinorMeta);
    }
    if (data.containsKey('device_password')) {
      context.handle(
          _devicePasswordMeta,
          devicePassword.isAcceptableOrUnknown(
              data['device_password']!, _devicePasswordMeta));
    }
    if (data.containsKey('device_pattern')) {
      context.handle(
          _devicePatternMeta,
          devicePattern.isAcceptableOrUnknown(
              data['device_pattern']!, _devicePatternMeta));
    }
    if (data.containsKey('description')) {
      context.handle(
          _descriptionMeta,
          description.isAcceptableOrUnknown(
              data['description']!, _descriptionMeta));
    }
    if (data.containsKey('accessories_sim')) {
      context.handle(
          _accessoriesSimMeta,
          accessoriesSim.isAcceptableOrUnknown(
              data['accessories_sim']!, _accessoriesSimMeta));
    }
    if (data.containsKey('accessories_sd_card')) {
      context.handle(
          _accessoriesSdCardMeta,
          accessoriesSdCard.isAcceptableOrUnknown(
              data['accessories_sd_card']!, _accessoriesSdCardMeta));
    }
    if (data.containsKey('accessories_back_cover')) {
      context.handle(
          _accessoriesBackCoverMeta,
          accessoriesBackCover.isAcceptableOrUnknown(
              data['accessories_back_cover']!, _accessoriesBackCoverMeta));
    }
    if (data.containsKey('accessories_charger')) {
      context.handle(
          _accessoriesChargerMeta,
          accessoriesCharger.isAcceptableOrUnknown(
              data['accessories_charger']!, _accessoriesChargerMeta));
    }
    if (data.containsKey('notify_whatsapp')) {
      context.handle(
          _notifyWhatsappMeta,
          notifyWhatsapp.isAcceptableOrUnknown(
              data['notify_whatsapp']!, _notifyWhatsappMeta));
    }
    if (data.containsKey('notify_email')) {
      context.handle(
          _notifyEmailMeta,
          notifyEmail.isAcceptableOrUnknown(
              data['notify_email']!, _notifyEmailMeta));
    }
    if (data.containsKey('sync_status')) {
      context.handle(
          _syncStatusMeta,
          syncStatus.isAcceptableOrUnknown(
              data['sync_status']!, _syncStatusMeta));
    }
    if (data.containsKey('local_revision')) {
      context.handle(
          _localRevisionMeta,
          localRevision.isAcceptableOrUnknown(
              data['local_revision']!, _localRevisionMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Order map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Order(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      status: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}status'])!,
      repairDate: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}repair_date'])!,
      repairTime: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}repair_time'])!,
      reminderEnabled: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}reminder_enabled'])!,
      customerName: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}customer_name'])!,
      customerNumber: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}customer_number'])!,
      customerAddress: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}customer_address']),
      deviceProblem: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}device_problem'])!,
      estimatePriceMinor: attachedDatabase.typeMapping.read(
          DriftSqlType.int, data['${effectivePrefix}estimate_price_minor'])!,
      paidPriceMinor: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}paid_price_minor'])!,
      devicePassword: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}device_password']),
      devicePattern: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}device_pattern']),
      description: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}description']),
      accessoriesSim: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}accessories_sim'])!,
      accessoriesSdCard: attachedDatabase.typeMapping.read(
          DriftSqlType.bool, data['${effectivePrefix}accessories_sd_card'])!,
      accessoriesBackCover: attachedDatabase.typeMapping.read(
          DriftSqlType.bool, data['${effectivePrefix}accessories_back_cover'])!,
      accessoriesCharger: attachedDatabase.typeMapping.read(
          DriftSqlType.bool, data['${effectivePrefix}accessories_charger'])!,
      notifyWhatsapp: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}notify_whatsapp'])!,
      notifyEmail: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}notify_email'])!,
      syncStatus: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}sync_status'])!,
      localRevision: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}local_revision'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
    );
  }

  @override
  $OrdersTable createAlias(String alias) {
    return $OrdersTable(attachedDatabase, alias);
  }
}

class Order extends DataClass implements Insertable<Order> {
  final String id;
  final String status;
  final DateTime repairDate;
  final String repairTime;
  final bool reminderEnabled;
  final String customerName;
  final String customerNumber;
  final String? customerAddress;
  final String deviceProblem;
  final int estimatePriceMinor;
  final int paidPriceMinor;
  final String? devicePassword;
  final String? devicePattern;
  final String? description;
  final bool accessoriesSim;
  final bool accessoriesSdCard;
  final bool accessoriesBackCover;
  final bool accessoriesCharger;
  final bool notifyWhatsapp;
  final bool notifyEmail;
  final String syncStatus;
  final int localRevision;
  final DateTime createdAt;
  final DateTime updatedAt;
  const Order(
      {required this.id,
      required this.status,
      required this.repairDate,
      required this.repairTime,
      required this.reminderEnabled,
      required this.customerName,
      required this.customerNumber,
      this.customerAddress,
      required this.deviceProblem,
      required this.estimatePriceMinor,
      required this.paidPriceMinor,
      this.devicePassword,
      this.devicePattern,
      this.description,
      required this.accessoriesSim,
      required this.accessoriesSdCard,
      required this.accessoriesBackCover,
      required this.accessoriesCharger,
      required this.notifyWhatsapp,
      required this.notifyEmail,
      required this.syncStatus,
      required this.localRevision,
      required this.createdAt,
      required this.updatedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['status'] = Variable<String>(status);
    map['repair_date'] = Variable<DateTime>(repairDate);
    map['repair_time'] = Variable<String>(repairTime);
    map['reminder_enabled'] = Variable<bool>(reminderEnabled);
    map['customer_name'] = Variable<String>(customerName);
    map['customer_number'] = Variable<String>(customerNumber);
    if (!nullToAbsent || customerAddress != null) {
      map['customer_address'] = Variable<String>(customerAddress);
    }
    map['device_problem'] = Variable<String>(deviceProblem);
    map['estimate_price_minor'] = Variable<int>(estimatePriceMinor);
    map['paid_price_minor'] = Variable<int>(paidPriceMinor);
    if (!nullToAbsent || devicePassword != null) {
      map['device_password'] = Variable<String>(devicePassword);
    }
    if (!nullToAbsent || devicePattern != null) {
      map['device_pattern'] = Variable<String>(devicePattern);
    }
    if (!nullToAbsent || description != null) {
      map['description'] = Variable<String>(description);
    }
    map['accessories_sim'] = Variable<bool>(accessoriesSim);
    map['accessories_sd_card'] = Variable<bool>(accessoriesSdCard);
    map['accessories_back_cover'] = Variable<bool>(accessoriesBackCover);
    map['accessories_charger'] = Variable<bool>(accessoriesCharger);
    map['notify_whatsapp'] = Variable<bool>(notifyWhatsapp);
    map['notify_email'] = Variable<bool>(notifyEmail);
    map['sync_status'] = Variable<String>(syncStatus);
    map['local_revision'] = Variable<int>(localRevision);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  OrdersCompanion toCompanion(bool nullToAbsent) {
    return OrdersCompanion(
      id: Value(id),
      status: Value(status),
      repairDate: Value(repairDate),
      repairTime: Value(repairTime),
      reminderEnabled: Value(reminderEnabled),
      customerName: Value(customerName),
      customerNumber: Value(customerNumber),
      customerAddress: customerAddress == null && nullToAbsent
          ? const Value.absent()
          : Value(customerAddress),
      deviceProblem: Value(deviceProblem),
      estimatePriceMinor: Value(estimatePriceMinor),
      paidPriceMinor: Value(paidPriceMinor),
      devicePassword: devicePassword == null && nullToAbsent
          ? const Value.absent()
          : Value(devicePassword),
      devicePattern: devicePattern == null && nullToAbsent
          ? const Value.absent()
          : Value(devicePattern),
      description: description == null && nullToAbsent
          ? const Value.absent()
          : Value(description),
      accessoriesSim: Value(accessoriesSim),
      accessoriesSdCard: Value(accessoriesSdCard),
      accessoriesBackCover: Value(accessoriesBackCover),
      accessoriesCharger: Value(accessoriesCharger),
      notifyWhatsapp: Value(notifyWhatsapp),
      notifyEmail: Value(notifyEmail),
      syncStatus: Value(syncStatus),
      localRevision: Value(localRevision),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory Order.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Order(
      id: serializer.fromJson<String>(json['id']),
      status: serializer.fromJson<String>(json['status']),
      repairDate: serializer.fromJson<DateTime>(json['repairDate']),
      repairTime: serializer.fromJson<String>(json['repairTime']),
      reminderEnabled: serializer.fromJson<bool>(json['reminderEnabled']),
      customerName: serializer.fromJson<String>(json['customerName']),
      customerNumber: serializer.fromJson<String>(json['customerNumber']),
      customerAddress: serializer.fromJson<String?>(json['customerAddress']),
      deviceProblem: serializer.fromJson<String>(json['deviceProblem']),
      estimatePriceMinor: serializer.fromJson<int>(json['estimatePriceMinor']),
      paidPriceMinor: serializer.fromJson<int>(json['paidPriceMinor']),
      devicePassword: serializer.fromJson<String?>(json['devicePassword']),
      devicePattern: serializer.fromJson<String?>(json['devicePattern']),
      description: serializer.fromJson<String?>(json['description']),
      accessoriesSim: serializer.fromJson<bool>(json['accessoriesSim']),
      accessoriesSdCard: serializer.fromJson<bool>(json['accessoriesSdCard']),
      accessoriesBackCover:
          serializer.fromJson<bool>(json['accessoriesBackCover']),
      accessoriesCharger: serializer.fromJson<bool>(json['accessoriesCharger']),
      notifyWhatsapp: serializer.fromJson<bool>(json['notifyWhatsapp']),
      notifyEmail: serializer.fromJson<bool>(json['notifyEmail']),
      syncStatus: serializer.fromJson<String>(json['syncStatus']),
      localRevision: serializer.fromJson<int>(json['localRevision']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'status': serializer.toJson<String>(status),
      'repairDate': serializer.toJson<DateTime>(repairDate),
      'repairTime': serializer.toJson<String>(repairTime),
      'reminderEnabled': serializer.toJson<bool>(reminderEnabled),
      'customerName': serializer.toJson<String>(customerName),
      'customerNumber': serializer.toJson<String>(customerNumber),
      'customerAddress': serializer.toJson<String?>(customerAddress),
      'deviceProblem': serializer.toJson<String>(deviceProblem),
      'estimatePriceMinor': serializer.toJson<int>(estimatePriceMinor),
      'paidPriceMinor': serializer.toJson<int>(paidPriceMinor),
      'devicePassword': serializer.toJson<String?>(devicePassword),
      'devicePattern': serializer.toJson<String?>(devicePattern),
      'description': serializer.toJson<String?>(description),
      'accessoriesSim': serializer.toJson<bool>(accessoriesSim),
      'accessoriesSdCard': serializer.toJson<bool>(accessoriesSdCard),
      'accessoriesBackCover': serializer.toJson<bool>(accessoriesBackCover),
      'accessoriesCharger': serializer.toJson<bool>(accessoriesCharger),
      'notifyWhatsapp': serializer.toJson<bool>(notifyWhatsapp),
      'notifyEmail': serializer.toJson<bool>(notifyEmail),
      'syncStatus': serializer.toJson<String>(syncStatus),
      'localRevision': serializer.toJson<int>(localRevision),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  Order copyWith(
          {String? id,
          String? status,
          DateTime? repairDate,
          String? repairTime,
          bool? reminderEnabled,
          String? customerName,
          String? customerNumber,
          Value<String?> customerAddress = const Value.absent(),
          String? deviceProblem,
          int? estimatePriceMinor,
          int? paidPriceMinor,
          Value<String?> devicePassword = const Value.absent(),
          Value<String?> devicePattern = const Value.absent(),
          Value<String?> description = const Value.absent(),
          bool? accessoriesSim,
          bool? accessoriesSdCard,
          bool? accessoriesBackCover,
          bool? accessoriesCharger,
          bool? notifyWhatsapp,
          bool? notifyEmail,
          String? syncStatus,
          int? localRevision,
          DateTime? createdAt,
          DateTime? updatedAt}) =>
      Order(
        id: id ?? this.id,
        status: status ?? this.status,
        repairDate: repairDate ?? this.repairDate,
        repairTime: repairTime ?? this.repairTime,
        reminderEnabled: reminderEnabled ?? this.reminderEnabled,
        customerName: customerName ?? this.customerName,
        customerNumber: customerNumber ?? this.customerNumber,
        customerAddress: customerAddress.present
            ? customerAddress.value
            : this.customerAddress,
        deviceProblem: deviceProblem ?? this.deviceProblem,
        estimatePriceMinor: estimatePriceMinor ?? this.estimatePriceMinor,
        paidPriceMinor: paidPriceMinor ?? this.paidPriceMinor,
        devicePassword:
            devicePassword.present ? devicePassword.value : this.devicePassword,
        devicePattern:
            devicePattern.present ? devicePattern.value : this.devicePattern,
        description: description.present ? description.value : this.description,
        accessoriesSim: accessoriesSim ?? this.accessoriesSim,
        accessoriesSdCard: accessoriesSdCard ?? this.accessoriesSdCard,
        accessoriesBackCover: accessoriesBackCover ?? this.accessoriesBackCover,
        accessoriesCharger: accessoriesCharger ?? this.accessoriesCharger,
        notifyWhatsapp: notifyWhatsapp ?? this.notifyWhatsapp,
        notifyEmail: notifyEmail ?? this.notifyEmail,
        syncStatus: syncStatus ?? this.syncStatus,
        localRevision: localRevision ?? this.localRevision,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );
  Order copyWithCompanion(OrdersCompanion data) {
    return Order(
      id: data.id.present ? data.id.value : this.id,
      status: data.status.present ? data.status.value : this.status,
      repairDate:
          data.repairDate.present ? data.repairDate.value : this.repairDate,
      repairTime:
          data.repairTime.present ? data.repairTime.value : this.repairTime,
      reminderEnabled: data.reminderEnabled.present
          ? data.reminderEnabled.value
          : this.reminderEnabled,
      customerName: data.customerName.present
          ? data.customerName.value
          : this.customerName,
      customerNumber: data.customerNumber.present
          ? data.customerNumber.value
          : this.customerNumber,
      customerAddress: data.customerAddress.present
          ? data.customerAddress.value
          : this.customerAddress,
      deviceProblem: data.deviceProblem.present
          ? data.deviceProblem.value
          : this.deviceProblem,
      estimatePriceMinor: data.estimatePriceMinor.present
          ? data.estimatePriceMinor.value
          : this.estimatePriceMinor,
      paidPriceMinor: data.paidPriceMinor.present
          ? data.paidPriceMinor.value
          : this.paidPriceMinor,
      devicePassword: data.devicePassword.present
          ? data.devicePassword.value
          : this.devicePassword,
      devicePattern: data.devicePattern.present
          ? data.devicePattern.value
          : this.devicePattern,
      description:
          data.description.present ? data.description.value : this.description,
      accessoriesSim: data.accessoriesSim.present
          ? data.accessoriesSim.value
          : this.accessoriesSim,
      accessoriesSdCard: data.accessoriesSdCard.present
          ? data.accessoriesSdCard.value
          : this.accessoriesSdCard,
      accessoriesBackCover: data.accessoriesBackCover.present
          ? data.accessoriesBackCover.value
          : this.accessoriesBackCover,
      accessoriesCharger: data.accessoriesCharger.present
          ? data.accessoriesCharger.value
          : this.accessoriesCharger,
      notifyWhatsapp: data.notifyWhatsapp.present
          ? data.notifyWhatsapp.value
          : this.notifyWhatsapp,
      notifyEmail:
          data.notifyEmail.present ? data.notifyEmail.value : this.notifyEmail,
      syncStatus:
          data.syncStatus.present ? data.syncStatus.value : this.syncStatus,
      localRevision: data.localRevision.present
          ? data.localRevision.value
          : this.localRevision,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Order(')
          ..write('id: $id, ')
          ..write('status: $status, ')
          ..write('repairDate: $repairDate, ')
          ..write('repairTime: $repairTime, ')
          ..write('reminderEnabled: $reminderEnabled, ')
          ..write('customerName: $customerName, ')
          ..write('customerNumber: $customerNumber, ')
          ..write('customerAddress: $customerAddress, ')
          ..write('deviceProblem: $deviceProblem, ')
          ..write('estimatePriceMinor: $estimatePriceMinor, ')
          ..write('paidPriceMinor: $paidPriceMinor, ')
          ..write('devicePassword: $devicePassword, ')
          ..write('devicePattern: $devicePattern, ')
          ..write('description: $description, ')
          ..write('accessoriesSim: $accessoriesSim, ')
          ..write('accessoriesSdCard: $accessoriesSdCard, ')
          ..write('accessoriesBackCover: $accessoriesBackCover, ')
          ..write('accessoriesCharger: $accessoriesCharger, ')
          ..write('notifyWhatsapp: $notifyWhatsapp, ')
          ..write('notifyEmail: $notifyEmail, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('localRevision: $localRevision, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hashAll([
        id,
        status,
        repairDate,
        repairTime,
        reminderEnabled,
        customerName,
        customerNumber,
        customerAddress,
        deviceProblem,
        estimatePriceMinor,
        paidPriceMinor,
        devicePassword,
        devicePattern,
        description,
        accessoriesSim,
        accessoriesSdCard,
        accessoriesBackCover,
        accessoriesCharger,
        notifyWhatsapp,
        notifyEmail,
        syncStatus,
        localRevision,
        createdAt,
        updatedAt
      ]);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Order &&
          other.id == this.id &&
          other.status == this.status &&
          other.repairDate == this.repairDate &&
          other.repairTime == this.repairTime &&
          other.reminderEnabled == this.reminderEnabled &&
          other.customerName == this.customerName &&
          other.customerNumber == this.customerNumber &&
          other.customerAddress == this.customerAddress &&
          other.deviceProblem == this.deviceProblem &&
          other.estimatePriceMinor == this.estimatePriceMinor &&
          other.paidPriceMinor == this.paidPriceMinor &&
          other.devicePassword == this.devicePassword &&
          other.devicePattern == this.devicePattern &&
          other.description == this.description &&
          other.accessoriesSim == this.accessoriesSim &&
          other.accessoriesSdCard == this.accessoriesSdCard &&
          other.accessoriesBackCover == this.accessoriesBackCover &&
          other.accessoriesCharger == this.accessoriesCharger &&
          other.notifyWhatsapp == this.notifyWhatsapp &&
          other.notifyEmail == this.notifyEmail &&
          other.syncStatus == this.syncStatus &&
          other.localRevision == this.localRevision &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class OrdersCompanion extends UpdateCompanion<Order> {
  final Value<String> id;
  final Value<String> status;
  final Value<DateTime> repairDate;
  final Value<String> repairTime;
  final Value<bool> reminderEnabled;
  final Value<String> customerName;
  final Value<String> customerNumber;
  final Value<String?> customerAddress;
  final Value<String> deviceProblem;
  final Value<int> estimatePriceMinor;
  final Value<int> paidPriceMinor;
  final Value<String?> devicePassword;
  final Value<String?> devicePattern;
  final Value<String?> description;
  final Value<bool> accessoriesSim;
  final Value<bool> accessoriesSdCard;
  final Value<bool> accessoriesBackCover;
  final Value<bool> accessoriesCharger;
  final Value<bool> notifyWhatsapp;
  final Value<bool> notifyEmail;
  final Value<String> syncStatus;
  final Value<int> localRevision;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const OrdersCompanion({
    this.id = const Value.absent(),
    this.status = const Value.absent(),
    this.repairDate = const Value.absent(),
    this.repairTime = const Value.absent(),
    this.reminderEnabled = const Value.absent(),
    this.customerName = const Value.absent(),
    this.customerNumber = const Value.absent(),
    this.customerAddress = const Value.absent(),
    this.deviceProblem = const Value.absent(),
    this.estimatePriceMinor = const Value.absent(),
    this.paidPriceMinor = const Value.absent(),
    this.devicePassword = const Value.absent(),
    this.devicePattern = const Value.absent(),
    this.description = const Value.absent(),
    this.accessoriesSim = const Value.absent(),
    this.accessoriesSdCard = const Value.absent(),
    this.accessoriesBackCover = const Value.absent(),
    this.accessoriesCharger = const Value.absent(),
    this.notifyWhatsapp = const Value.absent(),
    this.notifyEmail = const Value.absent(),
    this.syncStatus = const Value.absent(),
    this.localRevision = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  OrdersCompanion.insert({
    required String id,
    required String status,
    required DateTime repairDate,
    required String repairTime,
    this.reminderEnabled = const Value.absent(),
    required String customerName,
    required String customerNumber,
    this.customerAddress = const Value.absent(),
    required String deviceProblem,
    required int estimatePriceMinor,
    required int paidPriceMinor,
    this.devicePassword = const Value.absent(),
    this.devicePattern = const Value.absent(),
    this.description = const Value.absent(),
    this.accessoriesSim = const Value.absent(),
    this.accessoriesSdCard = const Value.absent(),
    this.accessoriesBackCover = const Value.absent(),
    this.accessoriesCharger = const Value.absent(),
    this.notifyWhatsapp = const Value.absent(),
    this.notifyEmail = const Value.absent(),
    this.syncStatus = const Value.absent(),
    this.localRevision = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        status = Value(status),
        repairDate = Value(repairDate),
        repairTime = Value(repairTime),
        customerName = Value(customerName),
        customerNumber = Value(customerNumber),
        deviceProblem = Value(deviceProblem),
        estimatePriceMinor = Value(estimatePriceMinor),
        paidPriceMinor = Value(paidPriceMinor),
        createdAt = Value(createdAt),
        updatedAt = Value(updatedAt);
  static Insertable<Order> custom({
    Expression<String>? id,
    Expression<String>? status,
    Expression<DateTime>? repairDate,
    Expression<String>? repairTime,
    Expression<bool>? reminderEnabled,
    Expression<String>? customerName,
    Expression<String>? customerNumber,
    Expression<String>? customerAddress,
    Expression<String>? deviceProblem,
    Expression<int>? estimatePriceMinor,
    Expression<int>? paidPriceMinor,
    Expression<String>? devicePassword,
    Expression<String>? devicePattern,
    Expression<String>? description,
    Expression<bool>? accessoriesSim,
    Expression<bool>? accessoriesSdCard,
    Expression<bool>? accessoriesBackCover,
    Expression<bool>? accessoriesCharger,
    Expression<bool>? notifyWhatsapp,
    Expression<bool>? notifyEmail,
    Expression<String>? syncStatus,
    Expression<int>? localRevision,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (status != null) 'status': status,
      if (repairDate != null) 'repair_date': repairDate,
      if (repairTime != null) 'repair_time': repairTime,
      if (reminderEnabled != null) 'reminder_enabled': reminderEnabled,
      if (customerName != null) 'customer_name': customerName,
      if (customerNumber != null) 'customer_number': customerNumber,
      if (customerAddress != null) 'customer_address': customerAddress,
      if (deviceProblem != null) 'device_problem': deviceProblem,
      if (estimatePriceMinor != null)
        'estimate_price_minor': estimatePriceMinor,
      if (paidPriceMinor != null) 'paid_price_minor': paidPriceMinor,
      if (devicePassword != null) 'device_password': devicePassword,
      if (devicePattern != null) 'device_pattern': devicePattern,
      if (description != null) 'description': description,
      if (accessoriesSim != null) 'accessories_sim': accessoriesSim,
      if (accessoriesSdCard != null) 'accessories_sd_card': accessoriesSdCard,
      if (accessoriesBackCover != null)
        'accessories_back_cover': accessoriesBackCover,
      if (accessoriesCharger != null) 'accessories_charger': accessoriesCharger,
      if (notifyWhatsapp != null) 'notify_whatsapp': notifyWhatsapp,
      if (notifyEmail != null) 'notify_email': notifyEmail,
      if (syncStatus != null) 'sync_status': syncStatus,
      if (localRevision != null) 'local_revision': localRevision,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  OrdersCompanion copyWith(
      {Value<String>? id,
      Value<String>? status,
      Value<DateTime>? repairDate,
      Value<String>? repairTime,
      Value<bool>? reminderEnabled,
      Value<String>? customerName,
      Value<String>? customerNumber,
      Value<String?>? customerAddress,
      Value<String>? deviceProblem,
      Value<int>? estimatePriceMinor,
      Value<int>? paidPriceMinor,
      Value<String?>? devicePassword,
      Value<String?>? devicePattern,
      Value<String?>? description,
      Value<bool>? accessoriesSim,
      Value<bool>? accessoriesSdCard,
      Value<bool>? accessoriesBackCover,
      Value<bool>? accessoriesCharger,
      Value<bool>? notifyWhatsapp,
      Value<bool>? notifyEmail,
      Value<String>? syncStatus,
      Value<int>? localRevision,
      Value<DateTime>? createdAt,
      Value<DateTime>? updatedAt,
      Value<int>? rowid}) {
    return OrdersCompanion(
      id: id ?? this.id,
      status: status ?? this.status,
      repairDate: repairDate ?? this.repairDate,
      repairTime: repairTime ?? this.repairTime,
      reminderEnabled: reminderEnabled ?? this.reminderEnabled,
      customerName: customerName ?? this.customerName,
      customerNumber: customerNumber ?? this.customerNumber,
      customerAddress: customerAddress ?? this.customerAddress,
      deviceProblem: deviceProblem ?? this.deviceProblem,
      estimatePriceMinor: estimatePriceMinor ?? this.estimatePriceMinor,
      paidPriceMinor: paidPriceMinor ?? this.paidPriceMinor,
      devicePassword: devicePassword ?? this.devicePassword,
      devicePattern: devicePattern ?? this.devicePattern,
      description: description ?? this.description,
      accessoriesSim: accessoriesSim ?? this.accessoriesSim,
      accessoriesSdCard: accessoriesSdCard ?? this.accessoriesSdCard,
      accessoriesBackCover: accessoriesBackCover ?? this.accessoriesBackCover,
      accessoriesCharger: accessoriesCharger ?? this.accessoriesCharger,
      notifyWhatsapp: notifyWhatsapp ?? this.notifyWhatsapp,
      notifyEmail: notifyEmail ?? this.notifyEmail,
      syncStatus: syncStatus ?? this.syncStatus,
      localRevision: localRevision ?? this.localRevision,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (repairDate.present) {
      map['repair_date'] = Variable<DateTime>(repairDate.value);
    }
    if (repairTime.present) {
      map['repair_time'] = Variable<String>(repairTime.value);
    }
    if (reminderEnabled.present) {
      map['reminder_enabled'] = Variable<bool>(reminderEnabled.value);
    }
    if (customerName.present) {
      map['customer_name'] = Variable<String>(customerName.value);
    }
    if (customerNumber.present) {
      map['customer_number'] = Variable<String>(customerNumber.value);
    }
    if (customerAddress.present) {
      map['customer_address'] = Variable<String>(customerAddress.value);
    }
    if (deviceProblem.present) {
      map['device_problem'] = Variable<String>(deviceProblem.value);
    }
    if (estimatePriceMinor.present) {
      map['estimate_price_minor'] = Variable<int>(estimatePriceMinor.value);
    }
    if (paidPriceMinor.present) {
      map['paid_price_minor'] = Variable<int>(paidPriceMinor.value);
    }
    if (devicePassword.present) {
      map['device_password'] = Variable<String>(devicePassword.value);
    }
    if (devicePattern.present) {
      map['device_pattern'] = Variable<String>(devicePattern.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (accessoriesSim.present) {
      map['accessories_sim'] = Variable<bool>(accessoriesSim.value);
    }
    if (accessoriesSdCard.present) {
      map['accessories_sd_card'] = Variable<bool>(accessoriesSdCard.value);
    }
    if (accessoriesBackCover.present) {
      map['accessories_back_cover'] =
          Variable<bool>(accessoriesBackCover.value);
    }
    if (accessoriesCharger.present) {
      map['accessories_charger'] = Variable<bool>(accessoriesCharger.value);
    }
    if (notifyWhatsapp.present) {
      map['notify_whatsapp'] = Variable<bool>(notifyWhatsapp.value);
    }
    if (notifyEmail.present) {
      map['notify_email'] = Variable<bool>(notifyEmail.value);
    }
    if (syncStatus.present) {
      map['sync_status'] = Variable<String>(syncStatus.value);
    }
    if (localRevision.present) {
      map['local_revision'] = Variable<int>(localRevision.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('OrdersCompanion(')
          ..write('id: $id, ')
          ..write('status: $status, ')
          ..write('repairDate: $repairDate, ')
          ..write('repairTime: $repairTime, ')
          ..write('reminderEnabled: $reminderEnabled, ')
          ..write('customerName: $customerName, ')
          ..write('customerNumber: $customerNumber, ')
          ..write('customerAddress: $customerAddress, ')
          ..write('deviceProblem: $deviceProblem, ')
          ..write('estimatePriceMinor: $estimatePriceMinor, ')
          ..write('paidPriceMinor: $paidPriceMinor, ')
          ..write('devicePassword: $devicePassword, ')
          ..write('devicePattern: $devicePattern, ')
          ..write('description: $description, ')
          ..write('accessoriesSim: $accessoriesSim, ')
          ..write('accessoriesSdCard: $accessoriesSdCard, ')
          ..write('accessoriesBackCover: $accessoriesBackCover, ')
          ..write('accessoriesCharger: $accessoriesCharger, ')
          ..write('notifyWhatsapp: $notifyWhatsapp, ')
          ..write('notifyEmail: $notifyEmail, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('localRevision: $localRevision, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $OrdersTable orders = $OrdersTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [orders];
}

typedef $$OrdersTableCreateCompanionBuilder = OrdersCompanion Function({
  required String id,
  required String status,
  required DateTime repairDate,
  required String repairTime,
  Value<bool> reminderEnabled,
  required String customerName,
  required String customerNumber,
  Value<String?> customerAddress,
  required String deviceProblem,
  required int estimatePriceMinor,
  required int paidPriceMinor,
  Value<String?> devicePassword,
  Value<String?> devicePattern,
  Value<String?> description,
  Value<bool> accessoriesSim,
  Value<bool> accessoriesSdCard,
  Value<bool> accessoriesBackCover,
  Value<bool> accessoriesCharger,
  Value<bool> notifyWhatsapp,
  Value<bool> notifyEmail,
  Value<String> syncStatus,
  Value<int> localRevision,
  required DateTime createdAt,
  required DateTime updatedAt,
  Value<int> rowid,
});
typedef $$OrdersTableUpdateCompanionBuilder = OrdersCompanion Function({
  Value<String> id,
  Value<String> status,
  Value<DateTime> repairDate,
  Value<String> repairTime,
  Value<bool> reminderEnabled,
  Value<String> customerName,
  Value<String> customerNumber,
  Value<String?> customerAddress,
  Value<String> deviceProblem,
  Value<int> estimatePriceMinor,
  Value<int> paidPriceMinor,
  Value<String?> devicePassword,
  Value<String?> devicePattern,
  Value<String?> description,
  Value<bool> accessoriesSim,
  Value<bool> accessoriesSdCard,
  Value<bool> accessoriesBackCover,
  Value<bool> accessoriesCharger,
  Value<bool> notifyWhatsapp,
  Value<bool> notifyEmail,
  Value<String> syncStatus,
  Value<int> localRevision,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<int> rowid,
});

class $$OrdersTableFilterComposer
    extends Composer<_$AppDatabase, $OrdersTable> {
  $$OrdersTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get status => $composableBuilder(
      column: $table.status, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get repairDate => $composableBuilder(
      column: $table.repairDate, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get repairTime => $composableBuilder(
      column: $table.repairTime, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get reminderEnabled => $composableBuilder(
      column: $table.reminderEnabled,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get customerName => $composableBuilder(
      column: $table.customerName, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get customerNumber => $composableBuilder(
      column: $table.customerNumber,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get customerAddress => $composableBuilder(
      column: $table.customerAddress,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get deviceProblem => $composableBuilder(
      column: $table.deviceProblem, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get estimatePriceMinor => $composableBuilder(
      column: $table.estimatePriceMinor,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get paidPriceMinor => $composableBuilder(
      column: $table.paidPriceMinor,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get devicePassword => $composableBuilder(
      column: $table.devicePassword,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get devicePattern => $composableBuilder(
      column: $table.devicePattern, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get description => $composableBuilder(
      column: $table.description, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get accessoriesSim => $composableBuilder(
      column: $table.accessoriesSim,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get accessoriesSdCard => $composableBuilder(
      column: $table.accessoriesSdCard,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get accessoriesBackCover => $composableBuilder(
      column: $table.accessoriesBackCover,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get accessoriesCharger => $composableBuilder(
      column: $table.accessoriesCharger,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get notifyWhatsapp => $composableBuilder(
      column: $table.notifyWhatsapp,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get notifyEmail => $composableBuilder(
      column: $table.notifyEmail, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get syncStatus => $composableBuilder(
      column: $table.syncStatus, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get localRevision => $composableBuilder(
      column: $table.localRevision, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));
}

class $$OrdersTableOrderingComposer
    extends Composer<_$AppDatabase, $OrdersTable> {
  $$OrdersTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get status => $composableBuilder(
      column: $table.status, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get repairDate => $composableBuilder(
      column: $table.repairDate, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get repairTime => $composableBuilder(
      column: $table.repairTime, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get reminderEnabled => $composableBuilder(
      column: $table.reminderEnabled,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get customerName => $composableBuilder(
      column: $table.customerName,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get customerNumber => $composableBuilder(
      column: $table.customerNumber,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get customerAddress => $composableBuilder(
      column: $table.customerAddress,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get deviceProblem => $composableBuilder(
      column: $table.deviceProblem,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get estimatePriceMinor => $composableBuilder(
      column: $table.estimatePriceMinor,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get paidPriceMinor => $composableBuilder(
      column: $table.paidPriceMinor,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get devicePassword => $composableBuilder(
      column: $table.devicePassword,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get devicePattern => $composableBuilder(
      column: $table.devicePattern,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get description => $composableBuilder(
      column: $table.description, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get accessoriesSim => $composableBuilder(
      column: $table.accessoriesSim,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get accessoriesSdCard => $composableBuilder(
      column: $table.accessoriesSdCard,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get accessoriesBackCover => $composableBuilder(
      column: $table.accessoriesBackCover,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get accessoriesCharger => $composableBuilder(
      column: $table.accessoriesCharger,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get notifyWhatsapp => $composableBuilder(
      column: $table.notifyWhatsapp,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get notifyEmail => $composableBuilder(
      column: $table.notifyEmail, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get syncStatus => $composableBuilder(
      column: $table.syncStatus, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get localRevision => $composableBuilder(
      column: $table.localRevision,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));
}

class $$OrdersTableAnnotationComposer
    extends Composer<_$AppDatabase, $OrdersTable> {
  $$OrdersTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<DateTime> get repairDate => $composableBuilder(
      column: $table.repairDate, builder: (column) => column);

  GeneratedColumn<String> get repairTime => $composableBuilder(
      column: $table.repairTime, builder: (column) => column);

  GeneratedColumn<bool> get reminderEnabled => $composableBuilder(
      column: $table.reminderEnabled, builder: (column) => column);

  GeneratedColumn<String> get customerName => $composableBuilder(
      column: $table.customerName, builder: (column) => column);

  GeneratedColumn<String> get customerNumber => $composableBuilder(
      column: $table.customerNumber, builder: (column) => column);

  GeneratedColumn<String> get customerAddress => $composableBuilder(
      column: $table.customerAddress, builder: (column) => column);

  GeneratedColumn<String> get deviceProblem => $composableBuilder(
      column: $table.deviceProblem, builder: (column) => column);

  GeneratedColumn<int> get estimatePriceMinor => $composableBuilder(
      column: $table.estimatePriceMinor, builder: (column) => column);

  GeneratedColumn<int> get paidPriceMinor => $composableBuilder(
      column: $table.paidPriceMinor, builder: (column) => column);

  GeneratedColumn<String> get devicePassword => $composableBuilder(
      column: $table.devicePassword, builder: (column) => column);

  GeneratedColumn<String> get devicePattern => $composableBuilder(
      column: $table.devicePattern, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
      column: $table.description, builder: (column) => column);

  GeneratedColumn<bool> get accessoriesSim => $composableBuilder(
      column: $table.accessoriesSim, builder: (column) => column);

  GeneratedColumn<bool> get accessoriesSdCard => $composableBuilder(
      column: $table.accessoriesSdCard, builder: (column) => column);

  GeneratedColumn<bool> get accessoriesBackCover => $composableBuilder(
      column: $table.accessoriesBackCover, builder: (column) => column);

  GeneratedColumn<bool> get accessoriesCharger => $composableBuilder(
      column: $table.accessoriesCharger, builder: (column) => column);

  GeneratedColumn<bool> get notifyWhatsapp => $composableBuilder(
      column: $table.notifyWhatsapp, builder: (column) => column);

  GeneratedColumn<bool> get notifyEmail => $composableBuilder(
      column: $table.notifyEmail, builder: (column) => column);

  GeneratedColumn<String> get syncStatus => $composableBuilder(
      column: $table.syncStatus, builder: (column) => column);

  GeneratedColumn<int> get localRevision => $composableBuilder(
      column: $table.localRevision, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$OrdersTableTableManager extends RootTableManager<
    _$AppDatabase,
    $OrdersTable,
    Order,
    $$OrdersTableFilterComposer,
    $$OrdersTableOrderingComposer,
    $$OrdersTableAnnotationComposer,
    $$OrdersTableCreateCompanionBuilder,
    $$OrdersTableUpdateCompanionBuilder,
    (Order, BaseReferences<_$AppDatabase, $OrdersTable, Order>),
    Order,
    PrefetchHooks Function()> {
  $$OrdersTableTableManager(_$AppDatabase db, $OrdersTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$OrdersTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$OrdersTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$OrdersTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> status = const Value.absent(),
            Value<DateTime> repairDate = const Value.absent(),
            Value<String> repairTime = const Value.absent(),
            Value<bool> reminderEnabled = const Value.absent(),
            Value<String> customerName = const Value.absent(),
            Value<String> customerNumber = const Value.absent(),
            Value<String?> customerAddress = const Value.absent(),
            Value<String> deviceProblem = const Value.absent(),
            Value<int> estimatePriceMinor = const Value.absent(),
            Value<int> paidPriceMinor = const Value.absent(),
            Value<String?> devicePassword = const Value.absent(),
            Value<String?> devicePattern = const Value.absent(),
            Value<String?> description = const Value.absent(),
            Value<bool> accessoriesSim = const Value.absent(),
            Value<bool> accessoriesSdCard = const Value.absent(),
            Value<bool> accessoriesBackCover = const Value.absent(),
            Value<bool> accessoriesCharger = const Value.absent(),
            Value<bool> notifyWhatsapp = const Value.absent(),
            Value<bool> notifyEmail = const Value.absent(),
            Value<String> syncStatus = const Value.absent(),
            Value<int> localRevision = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              OrdersCompanion(
            id: id,
            status: status,
            repairDate: repairDate,
            repairTime: repairTime,
            reminderEnabled: reminderEnabled,
            customerName: customerName,
            customerNumber: customerNumber,
            customerAddress: customerAddress,
            deviceProblem: deviceProblem,
            estimatePriceMinor: estimatePriceMinor,
            paidPriceMinor: paidPriceMinor,
            devicePassword: devicePassword,
            devicePattern: devicePattern,
            description: description,
            accessoriesSim: accessoriesSim,
            accessoriesSdCard: accessoriesSdCard,
            accessoriesBackCover: accessoriesBackCover,
            accessoriesCharger: accessoriesCharger,
            notifyWhatsapp: notifyWhatsapp,
            notifyEmail: notifyEmail,
            syncStatus: syncStatus,
            localRevision: localRevision,
            createdAt: createdAt,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String status,
            required DateTime repairDate,
            required String repairTime,
            Value<bool> reminderEnabled = const Value.absent(),
            required String customerName,
            required String customerNumber,
            Value<String?> customerAddress = const Value.absent(),
            required String deviceProblem,
            required int estimatePriceMinor,
            required int paidPriceMinor,
            Value<String?> devicePassword = const Value.absent(),
            Value<String?> devicePattern = const Value.absent(),
            Value<String?> description = const Value.absent(),
            Value<bool> accessoriesSim = const Value.absent(),
            Value<bool> accessoriesSdCard = const Value.absent(),
            Value<bool> accessoriesBackCover = const Value.absent(),
            Value<bool> accessoriesCharger = const Value.absent(),
            Value<bool> notifyWhatsapp = const Value.absent(),
            Value<bool> notifyEmail = const Value.absent(),
            Value<String> syncStatus = const Value.absent(),
            Value<int> localRevision = const Value.absent(),
            required DateTime createdAt,
            required DateTime updatedAt,
            Value<int> rowid = const Value.absent(),
          }) =>
              OrdersCompanion.insert(
            id: id,
            status: status,
            repairDate: repairDate,
            repairTime: repairTime,
            reminderEnabled: reminderEnabled,
            customerName: customerName,
            customerNumber: customerNumber,
            customerAddress: customerAddress,
            deviceProblem: deviceProblem,
            estimatePriceMinor: estimatePriceMinor,
            paidPriceMinor: paidPriceMinor,
            devicePassword: devicePassword,
            devicePattern: devicePattern,
            description: description,
            accessoriesSim: accessoriesSim,
            accessoriesSdCard: accessoriesSdCard,
            accessoriesBackCover: accessoriesBackCover,
            accessoriesCharger: accessoriesCharger,
            notifyWhatsapp: notifyWhatsapp,
            notifyEmail: notifyEmail,
            syncStatus: syncStatus,
            localRevision: localRevision,
            createdAt: createdAt,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable<$OrdersTable, Order>(table),
                    BaseReferences<_$AppDatabase, $OrdersTable, Order>(
                        db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$OrdersTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $OrdersTable,
    Order,
    $$OrdersTableFilterComposer,
    $$OrdersTableOrderingComposer,
    $$OrdersTableAnnotationComposer,
    $$OrdersTableCreateCompanionBuilder,
    $$OrdersTableUpdateCompanionBuilder,
    (Order, BaseReferences<_$AppDatabase, $OrdersTable, Order>),
    Order,
    PrefetchHooks Function()>;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$OrdersTableTableManager get orders =>
      $$OrdersTableTableManager(_db, _db.orders);
}
