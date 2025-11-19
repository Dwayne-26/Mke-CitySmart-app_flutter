<<<<<<< HEAD
=======
import 'package:flutter/material.dart';
import 'user.dart';

class Permit {
  final String id;
  final String permitNumber;
  final PermitType type;
  final DateTime startDate;
  final DateTime endDate;
  final PermitStatus status;
  final Vehicle vehicle;
  final String? zone;
  final double cost;
  final String qrCode;

  const Permit({
    required this.id,
    required this.permitNumber,
    required this.type,
    required this.startDate,
    required this.endDate,
    required this.status,
    required this.vehicle,
    this.zone,
    required this.cost,
    required this.qrCode,
  });

  factory Permit.fromJson(Map<String, dynamic> json) {
    return Permit(
      id: json['id'] as String,
      permitNumber: json['permitNumber'] as String,
      type: PermitType.values.firstWhere((e) => e.name == json['type']),
      startDate: DateTime.parse(json['startDate'] as String),
      endDate: DateTime.parse(json['endDate'] as String),
      status: PermitStatus.values.firstWhere((e) => e.name == json['status']),
      vehicle: Vehicle.fromJson(json['vehicle'] as Map<String, dynamic>),
      zone: json['zone'] as String?,
      cost: (json['cost'] as num).toDouble(),
      qrCode: json['qrCode'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'permitNumber': permitNumber,
      'type': type.name,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'status': status.name,
      'vehicle': vehicle.toJson(),
      'zone': zone,
      'cost': cost,
      'qrCode': qrCode,
    };
  }

  bool get isExpired => DateTime.now().isAfter(endDate);
  bool get isActive => status == PermitStatus.active && !isExpired;

  Duration get timeRemaining =>
      isExpired ? Duration.zero : endDate.difference(DateTime.now());
}

>>>>>>> 2b87afb11f152c882e984ad699e63f1ed266df51
enum PermitType {
  residential,
  visitor,
  business,
  handicap,
  monthly,
  annual,
  temporary,
}

<<<<<<< HEAD
enum PermitStatus { active, expired, inactive }

class Permit {
  const Permit({
    required this.id,
    required this.type,
    required this.status,
    required this.zone,
    required this.startDate,
    required this.endDate,
    required this.vehicleIds,
    required this.qrCodeData,
    this.offlineAccess = false,
    this.autoRenew = false,
  });

  final String id;
  final PermitType type;
  final PermitStatus status;
  final String zone;
  final DateTime startDate;
  final DateTime endDate;
  final List<String> vehicleIds;
  final String qrCodeData;
  final bool offlineAccess;
  final bool autoRenew;

  Permit copyWith({
    PermitType? type,
    PermitStatus? status,
    String? zone,
    DateTime? startDate,
    DateTime? endDate,
    List<String>? vehicleIds,
    String? qrCodeData,
    bool? offlineAccess,
    bool? autoRenew,
  }) {
    return Permit(
      id: id,
      type: type ?? this.type,
      status: status ?? this.status,
      zone: zone ?? this.zone,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      vehicleIds: vehicleIds ?? this.vehicleIds,
      qrCodeData: qrCodeData ?? this.qrCodeData,
      offlineAccess: offlineAccess ?? this.offlineAccess,
      autoRenew: autoRenew ?? this.autoRenew,
    );
  }

  bool get isExpiringSoon {
    final now = DateTime.now();
    return status == PermitStatus.active &&
        endDate.isAfter(now) &&
        endDate.difference(now).inDays <= 7;
  }

  factory Permit.fromJson(Map<String, dynamic> json) {
    return Permit(
      id: json['id'] as String,
      type: PermitType.values.firstWhere(
        (value) => value.name == json['type'],
        orElse: () => PermitType.residential,
      ),
      status: PermitStatus.values.firstWhere(
        (value) => value.name == json['status'],
        orElse: () => PermitStatus.inactive,
      ),
      zone: json['zone'] as String? ?? 'General',
      startDate: DateTime.parse(json['startDate'] as String),
      endDate: DateTime.parse(json['endDate'] as String),
      vehicleIds: (json['vehicleIds'] as List<dynamic>? ?? [])
          .map((value) => value as String)
          .toList(),
      qrCodeData: json['qrCodeData'] as String? ?? '',
      offlineAccess: json['offlineAccess'] as bool? ?? false,
      autoRenew: json['autoRenew'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type.name,
    'status': status.name,
    'zone': zone,
    'startDate': startDate.toIso8601String(),
    'endDate': endDate.toIso8601String(),
    'vehicleIds': vehicleIds,
    'qrCodeData': qrCodeData,
    'offlineAccess': offlineAccess,
    'autoRenew': autoRenew,
  };
}
=======
enum PermitStatus { active, expired, suspended, pending, cancelled }
>>>>>>> 2b87afb11f152c882e984ad699e63f1ed266df51
