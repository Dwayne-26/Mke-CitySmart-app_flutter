<<<<<<< HEAD
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
=======
import 'package:flutter/material.dart';

enum SweepingSide { north, south, east, west, both }

class StreetSweeping {
  final String id;
  final String streetName;
  final String fromStreet;
  final String toStreet;
  final SweepingSide side;
  final DateTime date;
  final DateTime startTime;
  final DateTime endTime;
  final double latitude;
  final double longitude;

  StreetSweeping({
    required this.id,
    required this.streetName,
    required this.fromStreet,
    required this.toStreet,
    required this.side,
    required this.date,
    required this.startTime,
    required this.endTime,
    required this.latitude,
    required this.longitude,
  });

  factory StreetSweeping.fromJson(Map<String, dynamic> json) {
    return StreetSweeping(
      id: json['id'],
      streetName: json['street_name'],
      fromStreet: json['from_street'],
      toStreet: json['to_street'],
      side: SweepingSide.values.firstWhere(
        (e) => e.toString() == 'SweepingSide.${json['side']}',
        orElse: () => SweepingSide.both,
      ),
      date: DateTime.parse(json['date']),
      startTime: DateTime.parse(json['start_time']),
      endTime: DateTime.parse(json['end_time']),
      latitude: json['latitude']?.toDouble() ?? 0.0,
      longitude: json['longitude']?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'street_name': streetName,
      'from_street': fromStreet,
      'to_street': toStreet,
      'side': side.toString().split('.').last,
      'date': date.toIso8601String(),
      'start_time': startTime.toIso8601String(),
      'end_time': endTime.toIso8601String(),
      'latitude': latitude,
      'longitude': longitude,
    };
  }
}

class StreetSweepingSchedule {
  final String id;
  final String streetName;
  final String zone;
  final DateTime scheduledDate;
  final TimeOfDay startTime;
  final TimeOfDay endTime;
  final SweepingSide side;
  final bool isEmergency;
  final String? description;

  const StreetSweepingSchedule({
    required this.id,
    required this.streetName,
    required this.zone,
    required this.scheduledDate,
    required this.startTime,
    required this.endTime,
    required this.side,
    required this.isEmergency,
    this.description,
  });

  factory StreetSweepingSchedule.fromJson(Map<String, dynamic> json) {
    return StreetSweepingSchedule(
      id: json['id'] as String,
      streetName: json['streetName'] as String,
      zone: json['zone'] as String,
      scheduledDate: DateTime.parse(json['scheduledDate'] as String),
      startTime: TimeOfDay(
        hour: json['startHour'] as int,
        minute: json['startMinute'] as int,
      ),
      endTime: TimeOfDay(
        hour: json['endHour'] as int,
        minute: json['endMinute'] as int,
      ),
      side: SweepingSide.values.firstWhere((e) => e.name == json['side']),
      isEmergency: json['isEmergency'] as bool,
      description: json['description'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'streetName': streetName,
      'zone': zone,
      'scheduledDate': scheduledDate.toIso8601String(),
      'startHour': startTime.hour,
      'startMinute': startTime.minute,
      'endHour': endTime.hour,
      'endMinute': endTime.minute,
      'side': side.name,
      'isEmergency': isEmergency,
      'description': description,
    };
  }

  bool get isToday =>
      scheduledDate.year == DateTime.now().year &&
      scheduledDate.month == DateTime.now().month &&
      scheduledDate.day == DateTime.now().day;

  bool get isUpcoming => scheduledDate.isAfter(DateTime.now());

  DateTime get fullStartDateTime => DateTime(
    scheduledDate.year,
    scheduledDate.month,
    scheduledDate.day,
    startTime.hour,
    startTime.minute,
  );

  DateTime get fullEndDateTime => DateTime(
    scheduledDate.year,
    scheduledDate.month,
    scheduledDate.day,
    endTime.hour,
    endTime.minute,
  );
}

class StreetSweepingAlert {
  final String id;
  final String scheduleId;
  final String userId;
  final AlertType alertType;
  final DateTime alertTime;
  final bool isRead;
  final String message;

  const StreetSweepingAlert({
    required this.id,
    required this.scheduleId,
    required this.userId,
    required this.alertType,
    required this.alertTime,
    required this.isRead,
    required this.message,
  });

  factory StreetSweepingAlert.fromJson(Map<String, dynamic> json) {
    return StreetSweepingAlert(
      id: json['id'] as String,
      scheduleId: json['scheduleId'] as String,
      userId: json['userId'] as String,
      alertType: AlertType.values.firstWhere(
        (e) => e.name == json['alertType'],
      ),
      alertTime: DateTime.parse(json['alertTime'] as String),
      isRead: json['isRead'] as bool,
      message: json['message'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'scheduleId': scheduleId,
      'userId': userId,
      'alertType': alertType.name,
      'alertTime': alertTime.toIso8601String(),
      'isRead': isRead,
      'message': message,
    };
  }
}

// Use existing SweepingSide enum, don't duplicate
enum AlertType { dayBefore, hourBefore, immediate, emergency }
>>>>>>> 2b87afb11f152c882e984ad699e63f1ed266df51
