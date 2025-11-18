enum PermitType {
  residential,
  visitor,
  business,
  handicap,
  monthly,
  annual,
  temporary,
}

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
