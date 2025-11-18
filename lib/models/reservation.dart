enum ReservationStatus { reserved, checkedIn, completed, cancelled }

class Reservation {
  const Reservation({
    required this.id,
    required this.spotId,
    required this.location,
    required this.status,
    required this.startTime,
    required this.endTime,
    required this.ratePerHour,
    required this.vehiclePlate,
    required this.paymentMethod,
    required this.transactionId,
    required this.totalPaid,
  });

  final String id;
  final String spotId;
  final String location;
  final ReservationStatus status;
  final DateTime startTime;
  final DateTime endTime;
  final double ratePerHour;
  final String vehiclePlate;
  final String paymentMethod;
  final String transactionId;
  final double totalPaid;

  Duration get duration => endTime.difference(startTime);

  double get calculatedTotal {
    final hours = duration.inMinutes / 60;
    return double.parse((hours * ratePerHour).toStringAsFixed(2));
  }

  Reservation copyWith({
    ReservationStatus? status,
    DateTime? startTime,
    DateTime? endTime,
    double? ratePerHour,
    String? vehiclePlate,
    String? paymentMethod,
    String? transactionId,
    double? totalPaid,
  }) {
    return Reservation(
      id: id,
      spotId: spotId,
      location: location,
      status: status ?? this.status,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      ratePerHour: ratePerHour ?? this.ratePerHour,
      vehiclePlate: vehiclePlate ?? this.vehiclePlate,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      transactionId: transactionId ?? this.transactionId,
      totalPaid: totalPaid ?? this.totalPaid,
    );
  }

  factory Reservation.fromJson(Map<String, dynamic> json) {
    return Reservation(
      id: json['id'] as String,
      spotId: json['spotId'] as String,
      location: json['location'] as String? ?? 'Downtown zone',
      status: ReservationStatus.values.firstWhere(
        (value) => value.name == json['status'],
        orElse: () => ReservationStatus.reserved,
      ),
      startTime: DateTime.parse(json['startTime'] as String),
      endTime: DateTime.parse(json['endTime'] as String),
      ratePerHour: (json['ratePerHour'] as num).toDouble(),
      vehiclePlate: json['vehiclePlate'] as String? ?? '',
      paymentMethod: json['paymentMethod'] as String? ?? 'Card',
      transactionId: json['transactionId'] as String? ?? '',
      totalPaid: (json['totalPaid'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'spotId': spotId,
    'location': location,
    'status': status.name,
    'startTime': startTime.toIso8601String(),
    'endTime': endTime.toIso8601String(),
    'ratePerHour': ratePerHour,
    'vehiclePlate': vehiclePlate,
    'paymentMethod': paymentMethod,
    'transactionId': transactionId,
    'totalPaid': totalPaid,
  };
}
