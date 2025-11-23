enum SightingType { parkingEnforcer, towTruck }

class SightingReport {
  const SightingReport({
    required this.id,
    required this.type,
    required this.location,
    required this.notes,
    required this.reportedAt,
  });

  final String id;
  final SightingType type;
  final String location;
  final String notes;
  final DateTime reportedAt;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.name,
      'location': location,
      'notes': notes,
      'reportedAt': reportedAt.toIso8601String(),
    };
  }

  factory SightingReport.fromJson(Map<String, dynamic> json) {
    final typeName = json['type'] as String? ?? SightingType.parkingEnforcer.name;
    return SightingReport(
      id: json['id'] as String? ?? '',
      type: SightingType.values.firstWhere(
        (value) => value.name == typeName,
        orElse: () => SightingType.parkingEnforcer,
      ),
      location: json['location'] as String? ?? '',
      notes: json['notes'] as String? ?? '',
      reportedAt: DateTime.tryParse(json['reportedAt'] as String? ?? '') ??
          DateTime.now(),
    );
  }
}
