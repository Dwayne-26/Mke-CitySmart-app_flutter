class ParkingZone {
  const ParkingZone({
    required this.id,
    required this.name,
    required this.description,
    required this.side,
    required this.latitude,
    required this.longitude,
    required this.radiusMeters,
    required this.nextSweep,
    required this.frequency,
    required this.allowedSide,
  });

  final String id;
  final String name;
  final String description;
  final String side;
  final double latitude;
  final double longitude;
  final double radiusMeters;
  final DateTime nextSweep;
  final String frequency;
  final String allowedSide;

  ParkingZone copyWith({DateTime? nextSweep}) {
    return ParkingZone(
      id: id,
      name: name,
      description: description,
      side: side,
      latitude: latitude,
      longitude: longitude,
      radiusMeters: radiusMeters,
      nextSweep: nextSweep ?? this.nextSweep,
      frequency: frequency,
      allowedSide: allowedSide,
    );
  }
}
