enum TicketStatus { open, paid, waived }

class Ticket {
  const Ticket({
    required this.id,
    required this.plate,
    required this.amount,
    required this.reason,
    required this.location,
    required this.issuedAt,
    required this.dueDate,
    this.status = TicketStatus.open,
    this.paidAt,
    this.waiverReason,
    this.paymentMethod,
  });

  final String id;
  final String plate;
  final double amount;
  final String reason;
  final String location;
  final DateTime issuedAt;
  final DateTime dueDate;
  final TicketStatus status;
  final DateTime? paidAt;
  final String? waiverReason;
  final String? paymentMethod;

  bool get isOverdue => DateTime.now().isAfter(dueDate) && status == TicketStatus.open;

  Ticket copyWith({
    TicketStatus? status,
    DateTime? paidAt,
    String? waiverReason,
    String? paymentMethod,
  }) {
    return Ticket(
      id: id,
      plate: plate,
      amount: amount,
      reason: reason,
      location: location,
      issuedAt: issuedAt,
      dueDate: dueDate,
      status: status ?? this.status,
      paidAt: paidAt ?? this.paidAt,
      waiverReason: waiverReason ?? this.waiverReason,
      paymentMethod: paymentMethod ?? this.paymentMethod,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'plate': plate,
      'amount': amount,
      'reason': reason,
      'location': location,
      'issuedAt': issuedAt.toIso8601String(),
      'dueDate': dueDate.toIso8601String(),
      'status': status.name,
      'paidAt': paidAt?.toIso8601String(),
      'waiverReason': waiverReason,
      'paymentMethod': paymentMethod,
    };
  }

  factory Ticket.fromJson(Map<String, dynamic> json) {
    final statusName = json['status'] as String? ?? TicketStatus.open.name;
    return Ticket(
      id: json['id'] as String? ?? '',
      plate: json['plate'] as String? ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? 0,
      reason: json['reason'] as String? ?? '',
      location: json['location'] as String? ?? '',
      issuedAt: DateTime.tryParse(json['issuedAt'] as String? ?? '') ??
          DateTime.now(),
      dueDate: DateTime.tryParse(json['dueDate'] as String? ?? '') ??
          DateTime.now(),
      status: TicketStatus.values.firstWhere(
        (value) => value.name == statusName,
        orElse: () => TicketStatus.open,
      ),
      paidAt: DateTime.tryParse(json['paidAt'] as String? ?? ''),
      waiverReason: json['waiverReason'] as String?,
      paymentMethod: json['paymentMethod'] as String?,
    );
  }
}
