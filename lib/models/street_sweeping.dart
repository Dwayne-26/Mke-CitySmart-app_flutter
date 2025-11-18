class StreetSweepingSchedule {
  const StreetSweepingSchedule({
    required this.id,
    required this.zone,
    required this.side,
    required this.nextSweep,
    required this.gpsMonitoring,
    required this.advance24h,
    required this.final2h,
    required this.customMinutes,
    required this.alternativeParking,
    required this.cleanStreakDays,
    required this.violationsPrevented,
  });

  final String id;
  final String zone;
  final String side;
  final DateTime nextSweep;
  final bool gpsMonitoring;
  final bool advance24h;
  final bool final2h;
  final int customMinutes;
  final List<String> alternativeParking;
  final int cleanStreakDays;
  final int violationsPrevented;

  StreetSweepingSchedule copyWith({
    bool? gpsMonitoring,
    bool? advance24h,
    bool? final2h,
    int? customMinutes,
    DateTime? nextSweep,
    int? cleanStreakDays,
    int? violationsPrevented,
    List<String>? alternativeParking,
  }) {
    return StreetSweepingSchedule(
      id: id,
      zone: zone,
      side: side,
      nextSweep: nextSweep ?? this.nextSweep,
      gpsMonitoring: gpsMonitoring ?? this.gpsMonitoring,
      advance24h: advance24h ?? this.advance24h,
      final2h: final2h ?? this.final2h,
      customMinutes: customMinutes ?? this.customMinutes,
      alternativeParking: alternativeParking ?? this.alternativeParking,
      cleanStreakDays: cleanStreakDays ?? this.cleanStreakDays,
      violationsPrevented: violationsPrevented ?? this.violationsPrevented,
    );
  }

  factory StreetSweepingSchedule.fromJson(Map<String, dynamic> json) {
    return StreetSweepingSchedule(
      id: json['id'] as String,
      zone: json['zone'] as String,
      side: json['side'] as String,
      nextSweep: DateTime.parse(json['nextSweep'] as String),
      gpsMonitoring: json['gpsMonitoring'] as bool? ?? false,
      advance24h: json['advance24h'] as bool? ?? true,
      final2h: json['final2h'] as bool? ?? true,
      customMinutes: json['customMinutes'] as int? ?? 60,
      alternativeParking: (json['alternativeParking'] as List<dynamic>? ?? [])
          .map((value) => value as String)
          .toList(),
      cleanStreakDays: json['cleanStreakDays'] as int? ?? 0,
      violationsPrevented: json['violationsPrevented'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'zone': zone,
    'side': side,
    'nextSweep': nextSweep.toIso8601String(),
    'gpsMonitoring': gpsMonitoring,
    'advance24h': advance24h,
    'final2h': final2h,
    'customMinutes': customMinutes,
    'alternativeParking': alternativeParking,
    'cleanStreakDays': cleanStreakDays,
    'violationsPrevented': violationsPrevented,
  };
}
