import 'package:flutter/foundation.dart';
<<<<<<< HEAD

import '../models/permit.dart';
import '../models/reservation.dart';
import '../models/street_sweeping.dart';
import '../models/user_preferences.dart';
import '../models/user_profile.dart';
import '../models/vehicle.dart';
import '../services/user_repository.dart';

class UserProvider extends ChangeNotifier {
  UserProvider({required UserRepository userRepository})
    : _repository = userRepository;

  final UserRepository _repository;

  UserProfile? _profile;
  bool _initializing = true;
  bool _guestMode = false;
  List<Permit> _guestPermits = const [];
  List<Reservation> _guestReservations = const [];
  List<StreetSweepingSchedule> _guestSweepingSchedules = const [];

  bool get isInitializing => _initializing;
  bool get isLoggedIn => _profile != null;
  bool get isGuest => _guestMode;
  UserProfile? get profile => _profile;
  List<Permit> get permits => _profile?.permits ?? _guestPermits;
  List<Reservation> get reservations =>
      _profile?.reservations ?? _guestReservations;
  List<StreetSweepingSchedule> get sweepingSchedules =>
      _profile?.sweepingSchedules ?? _guestSweepingSchedules;
  List<String> get cityParkingSuggestions {
    final set = <String>{};
    for (final schedule in sweepingSchedules) {
      set.addAll(schedule.alternativeParking);
    }
    return set.toList();
  }

  Future<void> initialize() async {
    _profile = await _repository.loadProfile();
    _initializing = false;
    _guestMode = false;
    _guestPermits = const [];
    _guestReservations = const [];
    _guestSweepingSchedules = const [];
    notifyListeners();
  }

  void continueAsGuest() {
    _guestMode = true;
    _profile = null;
    _guestPermits = _seedPermits();
    _guestReservations = _seedReservations();
    _guestSweepingSchedules = _seedSweepingSchedules();
    notifyListeners();
  }

  Future<String?> register({
    required String name,
    required String email,
    required String password,
    String? phone,
  }) async {
    if (_profile != null) {
      return 'An account is already signed in on this device.';
    }
    if (name.isEmpty || email.isEmpty || password.isEmpty) {
      return 'All fields are required.';
    }

    final newProfile = UserProfile(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      email: email,
      password: password,
      phone: phone,
      preferences: UserPreferences.defaults(),
      vehicles: const [],
      permits: _seedPermits(ownerHint: name),
      reservations: _seedReservations(ownerHint: name),
      sweepingSchedules: _seedSweepingSchedules(ownerHint: name),
    );
    await _repository.saveProfile(newProfile);
    _profile = newProfile;
    _guestMode = false;
    notifyListeners();
    return null;
  }

  Future<String?> login(String email, String password) async {
    final stored = await _repository.loadProfile();
    if (stored == null) {
      return 'No account found on this device.';
    }
    if (stored.email.trim().toLowerCase() != email.trim().toLowerCase() ||
        stored.password != password) {
      return 'Invalid email or password.';
    }
    _profile = stored;
    _guestMode = false;
    notifyListeners();
    return null;
  }

  Future<void> logout() async {
    _profile = null;
    _guestMode = false;
    _guestPermits = const [];
    _guestReservations = const [];
    _guestSweepingSchedules = const [];
    await _repository.clearProfile();
    notifyListeners();
  }

  Future<void> updateProfile({
    String? name,
    String? email,
    String? phone,
    String? address,
  }) async {
    if (_profile == null) return;
    final updated = _profile!.copyWith(
      name: name ?? _profile!.name,
      email: email ?? _profile!.email,
      phone: phone ?? _profile!.phone,
      address: address ?? _profile!.address,
    );
    _profile = updated;
    await _repository.saveProfile(updated);
    notifyListeners();
  }

  Future<void> changePassword(String password) async {
    if (_profile == null || password.isEmpty) return;
    _profile = _profile!.copyWith(password: password);
    await _repository.saveProfile(_profile!);
    notifyListeners();
  }

  Future<void> addVehicle(Vehicle vehicle) async {
    if (_profile == null) return;
    final currentVehicles = List<Vehicle>.from(_profile!.vehicles)
      ..add(vehicle);
    final prefs = _profile!.preferences.defaultVehicleId == null
        ? _profile!.preferences.copyWith(defaultVehicleId: vehicle.id)
        : _profile!.preferences;
    _profile = _profile!.copyWith(
      vehicles: currentVehicles,
      preferences: prefs,
    );
    await _repository.saveProfile(_profile!);
    notifyListeners();
  }

  Future<void> updateVehicle(Vehicle vehicle) async {
    if (_profile == null) return;
    final updatedVehicles = _profile!.vehicles
        .map((existing) => existing.id == vehicle.id ? vehicle : existing)
        .toList();
    _profile = _profile!.copyWith(vehicles: updatedVehicles);
    await _repository.saveProfile(_profile!);
    notifyListeners();
  }

  Future<void> removeVehicle(String vehicleId) async {
    if (_profile == null) return;
    final updatedVehicles = _profile!.vehicles
        .where((vehicle) => vehicle.id != vehicleId)
        .toList();
    var preferences = _profile!.preferences;
    if (preferences.defaultVehicleId == vehicleId) {
      preferences = preferences.copyWith(
        defaultVehicleId: updatedVehicles.isEmpty
            ? null
            : updatedVehicles.first.id,
      );
    }
    _profile = _profile!.copyWith(
      vehicles: updatedVehicles,
      preferences: preferences,
    );
    await _repository.saveProfile(_profile!);
    notifyListeners();
  }

  Future<void> updatePreferences({
    bool? parkingNotifications,
    bool? towAlerts,
    bool? reminderNotifications,
    String? defaultVehicleId,
  }) async {
    if (_profile == null) return;
    final prefs = _profile!.preferences.copyWith(
      parkingNotifications: parkingNotifications,
      towAlerts: towAlerts,
      reminderNotifications: reminderNotifications,
      defaultVehicleId: defaultVehicleId,
    );
    _profile = _profile!.copyWith(preferences: prefs);
    await _repository.saveProfile(_profile!);
    notifyListeners();
  }

  Future<void> addPermit(Permit permit) async {
    final updated = List<Permit>.from(permits)..add(permit);
    await _updatePermitList(updated);
  }

  Future<void> renewPermit(String permitId) async {
    await _mutatePermit(permitId, (permit) {
      final now = DateTime.now();
      final start = permit.endDate.isAfter(now) ? permit.endDate : now;
      return permit.copyWith(
        status: PermitStatus.active,
        startDate: start,
        endDate: start.add(_permitDuration(permit.type)),
      );
    });
  }

  Future<void> updatePermitStatus(String permitId, PermitStatus status) async {
    await _mutatePermit(permitId, (permit) => permit.copyWith(status: status));
  }

  Future<void> toggleOfflineAccess(String permitId) async {
    await _mutatePermit(
      permitId,
      (permit) => permit.copyWith(offlineAccess: !permit.offlineAccess),
    );
  }

  Future<void> updatePermitVehicles(
    String permitId,
    List<String> vehicleIds,
  ) async {
    await _mutatePermit(
      permitId,
      (permit) => permit.copyWith(vehicleIds: vehicleIds),
    );
  }

  Future<void> updateAutoRenew(String permitId, bool enabled) async {
    await _mutatePermit(
      permitId,
      (permit) => permit.copyWith(autoRenew: enabled),
    );
  }

  Future<void> createReservation(Reservation reservation) async {
    final updated = List<Reservation>.from(reservations)..add(reservation);
    await _saveReservations(updated);
  }

  Future<void> updateReservationStatus(
    String reservationId,
    ReservationStatus status,
  ) async {
    await _mutateReservation(
      reservationId,
      (reservation) => reservation.copyWith(status: status),
    );
  }

  Future<void> recordPayment({
    required String reservationId,
    required String paymentMethod,
    required double amount,
    required String transactionId,
  }) async {
    await _mutateReservation(
      reservationId,
      (reservation) => reservation.copyWith(
        paymentMethod: paymentMethod,
        totalPaid: amount,
        transactionId: transactionId,
        status: ReservationStatus.completed,
      ),
    );
  }

  Future<void> updateSweepingNotifications(
    String id, {
    bool? gpsMonitoring,
    bool? advance24h,
    bool? final2h,
    int? customMinutes,
  }) async {
    await _mutateSweeping(
      id,
      (schedule) => schedule.copyWith(
        gpsMonitoring: gpsMonitoring,
        advance24h: advance24h,
        final2h: final2h,
        customMinutes: customMinutes,
      ),
    );
  }

  Future<void> logVehicleMoved(String id) async {
    await _mutateSweeping(
      id,
      (schedule) => schedule.copyWith(
        cleanStreakDays: schedule.cleanStreakDays + 1,
        violationsPrevented: schedule.violationsPrevented + 1,
      ),
    );
  }

  Duration _permitDuration(PermitType type) {
    switch (type) {
      case PermitType.residential:
      case PermitType.visitor:
      case PermitType.business:
      case PermitType.handicap:
      case PermitType.monthly:
        return const Duration(days: 30);
      case PermitType.annual:
        return const Duration(days: 365);
      case PermitType.temporary:
        return const Duration(days: 7);
    }
  }

  Future<void> _mutatePermit(
    String permitId,
    Permit Function(Permit permit) transform,
  ) async {
    final updated = permits
        .map((permit) => permit.id == permitId ? transform(permit) : permit)
        .toList();
    await _updatePermitList(updated);
  }

  Future<void> _updatePermitList(List<Permit> updated) async {
    if (_profile != null) {
      _profile = _profile!.copyWith(permits: updated);
      await _repository.saveProfile(_profile!);
    } else {
      _guestPermits = updated;
    }
    notifyListeners();
  }

  Future<void> _mutateReservation(
    String reservationId,
    Reservation Function(Reservation reservation) transform,
  ) async {
    final updated = reservations
        .map(
          (reservation) => reservation.id == reservationId
              ? transform(reservation)
              : reservation,
        )
        .toList();
    await _saveReservations(updated);
  }

  Future<void> _saveReservations(List<Reservation> updated) async {
    if (_profile != null) {
      _profile = _profile!.copyWith(reservations: updated);
      await _repository.saveProfile(_profile!);
    } else {
      _guestReservations = updated;
    }
    notifyListeners();
  }

  Future<void> _mutateSweeping(
    String id,
    StreetSweepingSchedule Function(StreetSweepingSchedule schedule) transform,
  ) async {
    final updated = sweepingSchedules
        .map((schedule) => schedule.id == id ? transform(schedule) : schedule)
        .toList();
    if (_profile != null) {
      _profile = _profile!.copyWith(sweepingSchedules: updated);
      await _repository.saveProfile(_profile!);
    } else {
      _guestSweepingSchedules = updated;
    }
    notifyListeners();
  }

  List<Permit> _seedPermits({String? ownerHint}) {
    final now = DateTime.now();
    final baseName = ownerHint ?? 'Guest';
    return [
      Permit(
        id: 'permit-res',
        type: PermitType.residential,
        status: PermitStatus.active,
        zone: 'Zone 3 - North Riverwest',
        startDate: now.subtract(const Duration(days: 40)),
        endDate: now.add(const Duration(days: 20)),
        vehicleIds: ['MKE-5123', 'EV-2108'],
        qrCodeData: 'RES-$baseName-${now.year}',
        offlineAccess: true,
        autoRenew: true,
      ),
      Permit(
        id: 'permit-visitor',
        type: PermitType.visitor,
        status: PermitStatus.active,
        zone: 'Zone 1 - Historic Third Ward',
        startDate: now,
        endDate: now.add(const Duration(days: 6)),
        vehicleIds: ['VIS-LOANER'],
        qrCodeData: 'VISITOR-$baseName-${now.millisecondsSinceEpoch}',
        offlineAccess: false,
      ),
      Permit(
        id: 'permit-business',
        type: PermitType.business,
        status: PermitStatus.expired,
        zone: 'Zone 6 - Harbor District',
        startDate: now.subtract(const Duration(days: 430)),
        endDate: now.subtract(const Duration(days: 60)),
        vehicleIds: ['FLEET-42'],
        qrCodeData: 'BIZ-$baseName',
        offlineAccess: true,
      ),
      Permit(
        id: 'permit-handicap',
        type: PermitType.handicap,
        status: PermitStatus.inactive,
        zone: 'Citywide',
        startDate: now,
        endDate: now.add(const Duration(days: 365)),
        vehicleIds: ['ACCESS-01'],
        qrCodeData: 'ADA-$baseName',
        offlineAccess: true,
=======
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';
import '../models/permit.dart';
import '../services/storage_service.dart';
import '../utils/config.dart';

class UserProvider extends ChangeNotifier {
  User? _currentUser;
  List<Vehicle> _vehicles = [];
  List<Permit> _permits = [];
  UserPreferences? _preferences;
  bool _isLoading = false;
  bool _isAuthenticated = false;
  String? _errorMessage;

  User? get currentUser => _currentUser;
  List<Vehicle> get vehicles => _vehicles;
  List<Permit> get permits => _permits;
  UserPreferences? get preferences => _preferences;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _isAuthenticated;
  String? get errorMessage => _errorMessage;

  Future<void> initializeUser() async {
    _setLoading(true);
    _clearError();

    try {
      // Try to load user from storage service first
      final cachedUser = await StorageService.getUser();
      if (cachedUser != null) {
        _currentUser = cachedUser;
        _isAuthenticated = true;

        // Load additional data
        await _loadUserVehicles();
        await _loadUserPermits();
        await _loadUserPreferences();

        _setLoading(false);
        notifyListeners();
        return;
      }

      // Check for token in preferences
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(PreferenceKeys.userToken);

      if (token != null) {
        _isAuthenticated = true;
        await _loadUserProfile();
        await _loadUserVehicles();
        await _loadUserPermits();
        await _loadUserPreferences();

        // Cache the user data
        if (_currentUser != null) {
          await StorageService.saveUser(_currentUser!);
        }
      } else {
        _createMockUser(); // For development
        if (_currentUser != null) {
          await StorageService.saveUser(_currentUser!);
        }
      }
    } catch (e) {
      _setError('Error initializing user: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> loginUser(String email, String password) async {
    _setLoading(true);
    _clearError();

    try {
      // Mock login for development
      await Future.delayed(Duration(seconds: 1)); // Simulate API call

      _isAuthenticated = true;
      _createMockUser();

      // Save token
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(PreferenceKeys.userToken, 'mock_token_123');

      return true;
    } catch (e) {
      _setError('Login failed: ${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> logoutUser() async {
    _setLoading(true);

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(PreferenceKeys.userToken);
      await prefs.remove(PreferenceKeys.userProfile);

      // Clear storage service data
      await StorageService.clearUser();
      await StorageService.clearCache();

      _currentUser = null;
      _vehicles.clear();
      _permits.clear();
      _preferences = null;
      _isAuthenticated = false;
    } catch (e) {
      _setError('Error logging out: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> addVehicle(Vehicle vehicle) async {
    _setLoading(true);
    _clearError();

    try {
      // Mock API call
      await Future.delayed(Duration(milliseconds: 500));

      _vehicles.add(vehicle);
      await _saveVehiclesToStorage();
    } catch (e) {
      _setError('Error adding vehicle: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> removeVehicle(String vehicleId) async {
    _setLoading(true);
    _clearError();

    try {
      _vehicles.removeWhere((v) => v.id == vehicleId);
      await _saveVehiclesToStorage();
    } catch (e) {
      _setError('Error removing vehicle: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> updatePreferences(UserPreferences newPreferences) async {
    _setLoading(true);
    _clearError();

    try {
      _preferences = newPreferences;
      await _savePreferencesToStorage();
    } catch (e) {
      _setError('Error updating preferences: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  Vehicle? getDefaultVehicle() {
    return _vehicles.firstWhere(
      (vehicle) => vehicle.isDefault,
      orElse: () => _vehicles.isNotEmpty
          ? _vehicles.first
          : Vehicle(
              id: 'mock_vehicle',
              licensePlate: 'MOCK123',
              make: 'Toyota',
              model: 'Camry',
              year: 2020,
              color: 'Blue',
              type: VehicleType.car,
              isDefault: true,
            ),
    );
  }

  List<Permit> getActivePermits() {
    return _permits.where((permit) => permit.isActive).toList();
  }

  // Private methods
  Future<void> _loadUserProfile() async {
    // Mock implementation - would normally load from API
    _createMockUser();
  }

  Future<void> _loadUserVehicles() async {
    final prefs = await SharedPreferences.getInstance();
    // Load vehicles from storage or create mock data
    _createMockVehicles();
  }

  Future<void> _loadUserPermits() async {
    // Try to load from cache first
    final cachedPermits = await StorageService.getCachedPermits();
    if (cachedPermits != null) {
      _permits = cachedPermits;
      notifyListeners();
      return;
    }

    // Load permits from API or create mock data
    _createMockPermits();

    // Cache the permits
    if (_permits.isNotEmpty) {
      await StorageService.cachePermits(_permits);
    }
  }

  Future<void> _loadUserPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    // Load preferences from storage or create defaults
    _preferences = UserPreferences(
      pushNotifications: prefs.getBool('push_notifications') ?? true,
      streetSweepingAlerts: prefs.getBool('street_sweeping_alerts') ?? true,
      parkingReminders: prefs.getBool('parking_reminders') ?? true,
      preferredPaymentMethod:
          prefs.getString('payment_method') ?? 'credit_card',
      searchRadius: prefs.getDouble('search_radius') ?? 1.0,
    );
  }

  Future<void> _saveVehiclesToStorage() async {
    final prefs = await SharedPreferences.getInstance();
    final vehiclesJson = _vehicles.map((v) => v.toJson()).toList();
    await prefs.setString('vehicles', vehiclesJson.toString());
  }

  Future<void> _savePreferencesToStorage() async {
    if (_preferences == null) return;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('push_notifications', _preferences!.pushNotifications);
    await prefs.setBool(
      'street_sweeping_alerts',
      _preferences!.streetSweepingAlerts,
    );
    await prefs.setBool('parking_reminders', _preferences!.parkingReminders);
    await prefs.setString(
      'payment_method',
      _preferences!.preferredPaymentMethod,
    );
    await prefs.setDouble('search_radius', _preferences!.searchRadius);
  }

  void _createMockUser() {
    _currentUser = User(
      id: 'user_123',
      email: 'user@milwaukee.gov',
      firstName: 'John',
      lastName: 'Doe',
      phoneNumber: '(414) 555-0123',
      vehicles: [],
      preferences: UserPreferences(
        pushNotifications: true,
        streetSweepingAlerts: true,
        parkingReminders: true,
        preferredPaymentMethod: 'credit_card',
        searchRadius: 1.0,
      ),
      createdAt: DateTime.now().subtract(Duration(days: 30)),
      updatedAt: DateTime.now(),
    );
  }

  void _createMockVehicles() {
    _vehicles = [
      Vehicle(
        id: 'vehicle_1',
        licensePlate: 'ABC123',
        make: 'Toyota',
        model: 'Camry',
        year: 2020,
        color: 'Blue',
        type: VehicleType.car,
        isDefault: true,
      ),
    ];
  }

  void _createMockPermits() {
    final now = DateTime.now();
    _permits = [
      Permit(
        id: 'permit_1',
        permitNumber: 'MKE2024-001',
        type: PermitType.residential,
        startDate: now.subtract(Duration(days: 10)),
        endDate: now.add(Duration(days: 355)),
        status: PermitStatus.active,
        vehicle: _vehicles.first,
        zone: 'Zone A',
        cost: 85.00,
        qrCode: 'QR_CODE_DATA_HERE',
>>>>>>> 2b87afb11f152c882e984ad699e63f1ed266df51
      ),
    ];
  }

<<<<<<< HEAD
  List<Reservation> _seedReservations({String? ownerHint}) {
    final now = DateTime.now();
    final baseName = ownerHint ?? 'Guest';
    return [
      Reservation(
        id: 'res-001',
        spotId: 'EV-18',
        location: '3rd Ward Garage',
        status: ReservationStatus.reserved,
        startTime: now.add(const Duration(hours: 1)),
        endTime: now.add(const Duration(hours: 3)),
        ratePerHour: 2.5,
        vehiclePlate: 'MKE-5123',
        paymentMethod: 'Apple Pay',
        transactionId: 'txn-${DateTime.now().millisecondsSinceEpoch}',
        totalPaid: 0,
      ),
      Reservation(
        id: 'res-002',
        spotId: 'OUT-09',
        location: 'East Side Meter 221',
        status: ReservationStatus.completed,
        startTime: now.subtract(const Duration(days: 1, hours: 3)),
        endTime: now.subtract(const Duration(days: 1, hours: 1)),
        ratePerHour: 1.5,
        vehiclePlate: 'EV-2108',
        paymentMethod: 'Visa **** 8211',
        transactionId: 'txn-${baseName.toUpperCase()}-002',
        totalPaid: 3.0,
      ),
    ];
  }

  List<StreetSweepingSchedule> _seedSweepingSchedules({String? ownerHint}) {
    final now = DateTime.now();
    return [
      StreetSweepingSchedule(
        id: 'sweep-1',
        zone: 'Riverwest Sector A',
        side: 'Odd side',
        nextSweep: now.add(const Duration(days: 3, hours: 5)),
        gpsMonitoring: true,
        advance24h: true,
        final2h: true,
        customMinutes: 90,
        alternativeParking: const [
          'Booth St lot – 0.2 mi',
          'Holton & Center ramp',
        ],
        cleanStreakDays: 21,
        violationsPrevented: 4,
      ),
      StreetSweepingSchedule(
        id: 'sweep-2',
        zone: 'Downtown East',
        side: 'Even side',
        nextSweep: now.add(const Duration(days: 5, hours: 2)),
        gpsMonitoring: false,
        advance24h: true,
        final2h: true,
        customMinutes: 60,
        alternativeParking: const ['Market St garage', 'Broadway public lot'],
        cleanStreakDays: 12,
        violationsPrevented: 2,
      ),
    ];
=======
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _errorMessage = error;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
    notifyListeners();
>>>>>>> 2b87afb11f152c882e984ad699e63f1ed266df51
  }
}
