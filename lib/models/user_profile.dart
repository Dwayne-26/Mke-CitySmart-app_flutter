import 'permit.dart';
import 'reservation.dart';
import 'street_sweeping.dart';
import 'user_preferences.dart';
import 'ad_preferences.dart';
import 'subscription_plan.dart';
import 'vehicle.dart';

class UserProfile {
  const UserProfile({
    required this.id,
    required this.name,
    required this.email,
    required this.password,
    this.phone,
    this.address,
    this.vehicles = const [],
    this.preferences = const UserPreferences(
      parkingNotifications: true,
      towAlerts: true,
      reminderNotifications: true,
    ),
    this.permits = const [],
    this.reservations = const [],
    this.sweepingSchedules = const [],
    this.adPreferences = const AdPreferences(),
    this.tier = SubscriptionTier.free,
  });

  final String id;
  final String name;
  final String email;
  final String password;
  final String? phone;
  final String? address;
  final List<Vehicle> vehicles;
  final UserPreferences preferences;
  final AdPreferences adPreferences;
  final SubscriptionTier tier;
  final List<Permit> permits;
  final List<Reservation> reservations;
  final List<StreetSweepingSchedule> sweepingSchedules;

  UserProfile copyWith({
    String? name,
    String? email,
    String? password,
    String? phone,
    String? address,
    List<Vehicle>? vehicles,
    UserPreferences? preferences,
    List<Permit>? permits,
    List<Reservation>? reservations,
    List<StreetSweepingSchedule>? sweepingSchedules,
    AdPreferences? adPreferences,
    SubscriptionTier? tier,
  }) {
    return UserProfile(
      id: id,
      name: name ?? this.name,
      email: email ?? this.email,
      password: password ?? this.password,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      vehicles: vehicles ?? this.vehicles,
      preferences: preferences ?? this.preferences,
      adPreferences: adPreferences ?? this.adPreferences,
      tier: tier ?? this.tier,
      permits: permits ?? this.permits,
      reservations: reservations ?? this.reservations,
      sweepingSchedules: sweepingSchedules ?? this.sweepingSchedules,
    );
  }

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    final vehiclesJson = json['vehicles'] as List<dynamic>? ?? [];
    final permitsJson = json['permits'] as List<dynamic>? ?? [];
    final reservationsJson = json['reservations'] as List<dynamic>? ?? [];
    final sweepingJson = json['sweepingSchedules'] as List<dynamic>? ?? [];
    return UserProfile(
      id: json['id'] as String,
      name: json['name'] as String? ?? '',
      email: json['email'] as String? ?? '',
      password: json['password'] as String? ?? '',
      phone: json['phone'] as String?,
      address: json['address'] as String?,
      vehicles: vehiclesJson
          .map((vehicle) => Vehicle.fromJson(vehicle as Map<String, dynamic>))
          .toList(),
      preferences: json['preferences'] != null
          ? UserPreferences.fromJson(
              json['preferences'] as Map<String, dynamic>,
            )
          : UserPreferences.defaults(),
      adPreferences: json['adPreferences'] != null
          ? AdPreferences.fromJson(
              json['adPreferences'] as Map<String, dynamic>,
            )
          : const AdPreferences(),
      tier: SubscriptionTier.values.firstWhere(
        (value) => value.name == (json['tier'] as String? ?? 'free'),
        orElse: () => SubscriptionTier.free,
      ),
      permits: permitsJson
          .map((permit) => Permit.fromJson(permit as Map<String, dynamic>))
          .toList(),
      reservations: reservationsJson
          .map(
            (reservation) =>
                Reservation.fromJson(reservation as Map<String, dynamic>),
          )
          .toList(),
      sweepingSchedules: sweepingJson
          .map(
            (schedule) => StreetSweepingSchedule.fromJson(
              schedule as Map<String, dynamic>,
            ),
          )
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'email': email,
    'password': password,
    'phone': phone,
    'address': address,
    'vehicles': vehicles.map((vehicle) => vehicle.toJson()).toList(),
    'preferences': preferences.toJson(),
    'adPreferences': adPreferences.toJson(),
    'tier': tier.name,
    'permits': permits.map((permit) => permit.toJson()).toList(),
    'reservations': reservations.map((r) => r.toJson()).toList(),
    'sweepingSchedules': sweepingSchedules
        .map((schedule) => schedule.toJson())
        .toList(),
  };
}
