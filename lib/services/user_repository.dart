import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/sighting_report.dart';
import '../models/payment_receipt.dart';
import '../models/ticket.dart';
import '../models/user_profile.dart';

class UserRepository {
  UserRepository._(this._prefs);

  final SharedPreferences _prefs;

  static const _profileKey = 'user_profile_v1';
  static const _sightingsKey = 'sighting_reports_v1';
  static const _ticketsKey = 'tickets_v1';
  static const _receiptsKey = 'receipts_v1';

  static Future<UserRepository> create() async {
    final prefs = await SharedPreferences.getInstance();
    return UserRepository._(prefs);
  }

  Future<UserProfile?> loadProfile() async {
    final stored = _prefs.getString(_profileKey);
    if (stored == null) return null;
    try {
      final json = jsonDecode(stored) as Map<String, dynamic>;
      return UserProfile.fromJson(json);
    } catch (_) {
      return null;
    }
  }

  Future<void> saveProfile(UserProfile profile) async {
    await _prefs.setString(_profileKey, jsonEncode(profile.toJson()));
  }

  Future<void> clearProfile() async {
    await _prefs.remove(_profileKey);
  }

  Future<List<SightingReport>> loadSightings() async {
    final stored = _prefs.getString(_sightingsKey);
    if (stored == null) return [];
    try {
      final jsonList = jsonDecode(stored) as List<dynamic>;
      return jsonList
          .map((item) => SightingReport.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> saveSightings(List<SightingReport> reports) async {
    final serialized = reports.map((report) => report.toJson()).toList();
    await _prefs.setString(_sightingsKey, jsonEncode(serialized));
  }

  Future<List<Ticket>> loadTickets() async {
    final stored = _prefs.getString(_ticketsKey);
    if (stored == null) return [];
    try {
      final jsonList = jsonDecode(stored) as List<dynamic>;
      return jsonList
          .map((item) => Ticket.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> saveTickets(List<Ticket> tickets) async {
    final serialized = tickets.map((ticket) => ticket.toJson()).toList();
    await _prefs.setString(_ticketsKey, jsonEncode(serialized));
  }

  Future<List<PaymentReceipt>> loadReceipts() async {
    final stored = _prefs.getString(_receiptsKey);
    if (stored == null) return [];
    try {
      final jsonList = jsonDecode(stored) as List<dynamic>;
      return jsonList
          .map(
            (item) => PaymentReceipt.fromJson(item as Map<String, dynamic>),
          )
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> saveReceipts(List<PaymentReceipt> receipts) async {
    final serialized = receipts.map((r) => r.toJson()).toList();
    await _prefs.setString(_receiptsKey, jsonEncode(serialized));
  }
}
