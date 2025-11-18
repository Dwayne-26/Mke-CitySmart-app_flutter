class ViolationRecord {
  const ViolationRecord({
    required this.date,
    required this.zoneName,
    required this.status,
    required this.preventionReason,
  });

  final DateTime date;
  final String zoneName;
  final String status;
  final String preventionReason;
}
