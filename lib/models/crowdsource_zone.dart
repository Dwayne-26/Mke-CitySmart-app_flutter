import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

/// A geographic parking zone with aggregated crowdsource intelligence.
///
/// Zones are the core unit for scaling. Each zone covers a ~150m × 150m area
/// (geohash precision 7) and accumulates data from crowdsource reports over
/// time. Zones are organised under a region path so the same architecture
/// works for Milwaukee today and any other city tomorrow.
///
/// Firestore path: `crowdsourceZones/{docId}`
///   where docId = `{region}_{geohash}`, e.g. `wi_milwaukee_dp5dtpp`
class CrowdsourceZone {
  final String id;

  /// Region path, e.g. "wi/milwaukee". Used for partitioning and multi-region
  /// queries. Forward slashes replaced with underscores in Firestore doc ids.
  final String region;

  /// Geohash of the zone centre (precision 7 ≈ 150m × 150m).
  final String geohash;

  /// Human-readable name for the zone (e.g. "Third Ward – N Water St").
  /// May be null until populated by geocoding or admin.
  final String? name;

  /// Centre-point coordinates (derived from the geohash).
  final double latitude;
  final double longitude;

  // ── Live aggregate counters (updated on every report) ──────────────────

  /// Total number of reports ever recorded in this zone.
  final int totalReportsAllTime;

  /// Number of currently-active (non-expired) reports.
  final int activeReports;

  /// Current estimated open spots in this zone.
  ///
  /// Derived from: (leavingSpot + spotAvailable) − (parkedHere + spotTaken)
  /// in the active report window, floored to 0.
  final int estimatedOpenSpots;

  /// Current count of active "taken" signals.
  final int activeTakenSignals;

  /// Current count of active "available" signals.
  final int activeAvailableSignals;

  /// Whether enforcement has been recently reported in this zone.
  final bool enforcementActive;

  /// Whether street sweeping is currently active.
  final bool sweepingActive;

  /// Whether parking is currently blocked (construction, event, etc.).
  final bool parkingBlocked;

  // ── Historical patterns (rolled up periodically) ───────────────────────

  /// Average estimated open spots per hour of day (0-23).
  /// e.g. {8: 12.5, 9: 8.3, 17: 2.1}
  /// Empty until enough data accumulates.
  final Map<int, double> hourlyAvgOpenSpots;

  /// Average estimated open spots per day of week (1=Mon, 7=Sun).
  final Map<int, double> dailyAvgOpenSpots;

  /// Peak enforcement hours observed in this zone.
  final List<int> enforcementPeakHours;

  // ── Confidence & coverage ──────────────────────────────────────────────

  /// Confidence score for this zone's data (0.0 – 1.0).
  /// Based on report volume and recency: more recent data = higher confidence.
  final double confidenceScore;

  /// Number of unique reporters who have submitted data for this zone.
  final int uniqueReporters;

  /// When this zone was last updated by a report.
  final DateTime lastUpdated;

  /// When this zone document was first created.
  final DateTime createdAt;

  const CrowdsourceZone({
    required this.id,
    required this.region,
    required this.geohash,
    this.name,
    required this.latitude,
    required this.longitude,
    this.totalReportsAllTime = 0,
    this.activeReports = 0,
    this.estimatedOpenSpots = 0,
    this.activeTakenSignals = 0,
    this.activeAvailableSignals = 0,
    this.enforcementActive = false,
    this.sweepingActive = false,
    this.parkingBlocked = false,
    this.hourlyAvgOpenSpots = const {},
    this.dailyAvgOpenSpots = const {},
    this.enforcementPeakHours = const [],
    this.confidenceScore = 0.0,
    this.uniqueReporters = 0,
    required this.lastUpdated,
    required this.createdAt,
  });

  // ── Firestore serialisation ────────────────────────────────────────────

  factory CrowdsourceZone.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final d = doc.data()!;
    return CrowdsourceZone(
      id: doc.id,
      region: d['region'] as String? ?? '',
      geohash: d['geohash'] as String? ?? '',
      name: d['name'] as String?,
      latitude: (d['latitude'] as num?)?.toDouble() ?? 0,
      longitude: (d['longitude'] as num?)?.toDouble() ?? 0,
      totalReportsAllTime: (d['totalReportsAllTime'] as num?)?.toInt() ?? 0,
      activeReports: (d['activeReports'] as num?)?.toInt() ?? 0,
      estimatedOpenSpots: (d['estimatedOpenSpots'] as num?)?.toInt() ?? 0,
      activeTakenSignals: (d['activeTakenSignals'] as num?)?.toInt() ?? 0,
      activeAvailableSignals:
          (d['activeAvailableSignals'] as num?)?.toInt() ?? 0,
      enforcementActive: d['enforcementActive'] as bool? ?? false,
      sweepingActive: d['sweepingActive'] as bool? ?? false,
      parkingBlocked: d['parkingBlocked'] as bool? ?? false,
      hourlyAvgOpenSpots: parseIntDoubleMap(d['hourlyAvgOpenSpots']),
      dailyAvgOpenSpots: parseIntDoubleMap(d['dailyAvgOpenSpots']),
      enforcementPeakHours: (d['enforcementPeakHours'] as List<dynamic>?)
              ?.map((e) => (e as num).toInt())
              .toList() ??
          const [],
      confidenceScore: (d['confidenceScore'] as num?)?.toDouble() ?? 0.0,
      uniqueReporters: (d['uniqueReporters'] as num?)?.toInt() ?? 0,
      lastUpdated:
          (d['lastUpdated'] as Timestamp?)?.toDate() ?? DateTime.now(),
      createdAt: (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'region': region,
      'geohash': geohash,
      'name': name,
      'latitude': latitude,
      'longitude': longitude,
      'totalReportsAllTime': totalReportsAllTime,
      'activeReports': activeReports,
      'estimatedOpenSpots': estimatedOpenSpots,
      'activeTakenSignals': activeTakenSignals,
      'activeAvailableSignals': activeAvailableSignals,
      'enforcementActive': enforcementActive,
      'sweepingActive': sweepingActive,
      'parkingBlocked': parkingBlocked,
      'hourlyAvgOpenSpots': hourlyAvgOpenSpots.map(
        (k, v) => MapEntry(k.toString(), v),
      ),
      'dailyAvgOpenSpots': dailyAvgOpenSpots.map(
        (k, v) => MapEntry(k.toString(), v),
      ),
      'enforcementPeakHours': enforcementPeakHours,
      'confidenceScore': confidenceScore,
      'uniqueReporters': uniqueReporters,
      'lastUpdated': Timestamp.fromDate(lastUpdated),
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  // ── JSON serialisation (local cache) ───────────────────────────────────

  factory CrowdsourceZone.fromJson(Map<String, dynamic> json) {
    return CrowdsourceZone(
      id: json['id'] as String,
      region: json['region'] as String? ?? '',
      geohash: json['geohash'] as String? ?? '',
      name: json['name'] as String?,
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0,
      totalReportsAllTime:
          (json['totalReportsAllTime'] as num?)?.toInt() ?? 0,
      activeReports: (json['activeReports'] as num?)?.toInt() ?? 0,
      estimatedOpenSpots: (json['estimatedOpenSpots'] as num?)?.toInt() ?? 0,
      activeTakenSignals: (json['activeTakenSignals'] as num?)?.toInt() ?? 0,
      activeAvailableSignals:
          (json['activeAvailableSignals'] as num?)?.toInt() ?? 0,
      enforcementActive: json['enforcementActive'] as bool? ?? false,
      sweepingActive: json['sweepingActive'] as bool? ?? false,
      parkingBlocked: json['parkingBlocked'] as bool? ?? false,
      hourlyAvgOpenSpots: parseIntDoubleMap(json['hourlyAvgOpenSpots']),
      dailyAvgOpenSpots: parseIntDoubleMap(json['dailyAvgOpenSpots']),
      enforcementPeakHours: (json['enforcementPeakHours'] as List<dynamic>?)
              ?.map((e) => (e as num).toInt())
              .toList() ??
          const [],
      confidenceScore: (json['confidenceScore'] as num?)?.toDouble() ?? 0.0,
      uniqueReporters: (json['uniqueReporters'] as num?)?.toInt() ?? 0,
      lastUpdated: DateTime.parse(json['lastUpdated'] as String),
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'region': region,
      'geohash': geohash,
      'name': name,
      'latitude': latitude,
      'longitude': longitude,
      'totalReportsAllTime': totalReportsAllTime,
      'activeReports': activeReports,
      'estimatedOpenSpots': estimatedOpenSpots,
      'activeTakenSignals': activeTakenSignals,
      'activeAvailableSignals': activeAvailableSignals,
      'enforcementActive': enforcementActive,
      'sweepingActive': sweepingActive,
      'parkingBlocked': parkingBlocked,
      'hourlyAvgOpenSpots': hourlyAvgOpenSpots.map(
        (k, v) => MapEntry(k.toString(), v),
      ),
      'dailyAvgOpenSpots': dailyAvgOpenSpots.map(
        (k, v) => MapEntry(k.toString(), v),
      ),
      'enforcementPeakHours': enforcementPeakHours,
      'confidenceScore': confidenceScore,
      'uniqueReporters': uniqueReporters,
      'lastUpdated': lastUpdated.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
    };
  }

  // ── Derived properties ─────────────────────────────────────────────────

  /// Availability label for display.
  String get availabilityLabel {
    if (activeReports == 0) return 'No data';
    if (estimatedOpenSpots >= 10) return 'Plenty of spots';
    if (estimatedOpenSpots >= 5) return 'Good availability';
    if (estimatedOpenSpots >= 2) return 'Limited spots';
    if (estimatedOpenSpots >= 1) return 'Very few spots';
    return 'No spots reported';
  }

  /// Short availability text with count (e.g. "~12 spots open").
  String get spotCountLabel {
    if (activeReports == 0) return 'No reports yet';
    if (estimatedOpenSpots <= 0) return 'No spots reported';
    return '~$estimatedOpenSpots spot${estimatedOpenSpots == 1 ? '' : 's'} open';
  }

  /// Colour representing current availability.
  Color get availabilityColor {
    if (activeReports == 0) return Colors.grey;
    if (estimatedOpenSpots >= 5) return Colors.green;
    if (estimatedOpenSpots >= 2) return Colors.orange;
    return Colors.red;
  }

  /// Confidence label (low / moderate / high).
  String get confidenceLabel {
    if (confidenceScore >= 0.7) return 'High confidence';
    if (confidenceScore >= 0.4) return 'Moderate confidence';
    return 'Low confidence';
  }

  /// Whether this zone has any active alerts (enforcement, sweeping, blocked).
  bool get hasAlerts => enforcementActive || sweepingActive || parkingBlocked;

  /// Predicted open spots for a given hour (falls back to current estimate).
  double predictedSpotsForHour(int hour) {
    return hourlyAvgOpenSpots[hour] ?? estimatedOpenSpots.toDouble();
  }

  /// Predicted open spots for a given day of week (1=Mon, 7=Sun).
  double predictedSpotsForDay(int dayOfWeek) {
    return dailyAvgOpenSpots[dayOfWeek] ?? estimatedOpenSpots.toDouble();
  }

  CrowdsourceZone copyWith({
    String? id,
    String? region,
    String? geohash,
    String? name,
    double? latitude,
    double? longitude,
    int? totalReportsAllTime,
    int? activeReports,
    int? estimatedOpenSpots,
    int? activeTakenSignals,
    int? activeAvailableSignals,
    bool? enforcementActive,
    bool? sweepingActive,
    bool? parkingBlocked,
    Map<int, double>? hourlyAvgOpenSpots,
    Map<int, double>? dailyAvgOpenSpots,
    List<int>? enforcementPeakHours,
    double? confidenceScore,
    int? uniqueReporters,
    DateTime? lastUpdated,
    DateTime? createdAt,
  }) {
    return CrowdsourceZone(
      id: id ?? this.id,
      region: region ?? this.region,
      geohash: geohash ?? this.geohash,
      name: name ?? this.name,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      totalReportsAllTime:
          totalReportsAllTime ?? this.totalReportsAllTime,
      activeReports: activeReports ?? this.activeReports,
      estimatedOpenSpots: estimatedOpenSpots ?? this.estimatedOpenSpots,
      activeTakenSignals: activeTakenSignals ?? this.activeTakenSignals,
      activeAvailableSignals:
          activeAvailableSignals ?? this.activeAvailableSignals,
      enforcementActive: enforcementActive ?? this.enforcementActive,
      sweepingActive: sweepingActive ?? this.sweepingActive,
      parkingBlocked: parkingBlocked ?? this.parkingBlocked,
      hourlyAvgOpenSpots: hourlyAvgOpenSpots ?? this.hourlyAvgOpenSpots,
      dailyAvgOpenSpots: dailyAvgOpenSpots ?? this.dailyAvgOpenSpots,
      enforcementPeakHours:
          enforcementPeakHours ?? this.enforcementPeakHours,
      confidenceScore: confidenceScore ?? this.confidenceScore,
      uniqueReporters: uniqueReporters ?? this.uniqueReporters,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CrowdsourceZone &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'CrowdsourceZone(id: $id, region: $region, geohash: $geohash, '
      'openSpots: $estimatedOpenSpots, confidence: '
      '${confidenceScore.toStringAsFixed(2)})';

  // ── Helpers ────────────────────────────────────────────────────────────

  /// Firestore stores map keys as strings — convert back to int keys.
  // ignore: library_private_types_in_public_api
  static Map<int, double> parseIntDoubleMap(dynamic raw) {
    if (raw == null || raw is! Map) return {};
    return raw.map<int, double>(
      (k, v) => MapEntry(int.parse(k.toString()), (v as num).toDouble()),
    );
  }
}

/// Summary of spot availability across multiple zones in a region.
class RegionAvailabilitySummary {
  /// Region path, e.g. "wi/milwaukee".
  final String region;

  /// Total zones with data in this region.
  final int totalZones;

  /// Zones that currently have at least one open spot.
  final int zonesWithOpenSpots;

  /// Total estimated open spots across all zones.
  final int totalEstimatedOpenSpots;

  /// Total active reports across all zones.
  final int totalActiveReports;

  /// Zones with active enforcement.
  final int zonesWithEnforcement;

  /// Average confidence across all zones.
  final double averageConfidence;

  /// Total unique reporters across all zones.
  final int totalUniqueReporters;

  /// Zones with no data (need more coverage).
  final int blindSpotZones;

  const RegionAvailabilitySummary({
    required this.region,
    required this.totalZones,
    required this.zonesWithOpenSpots,
    required this.totalEstimatedOpenSpots,
    required this.totalActiveReports,
    required this.zonesWithEnforcement,
    required this.averageConfidence,
    required this.totalUniqueReporters,
    required this.blindSpotZones,
  });

  /// Human-friendly summary string, e.g. "~47 spots open across 12 zones".
  String get summaryLabel {
    if (totalActiveReports == 0) return 'No data yet for this region';
    if (totalEstimatedOpenSpots <= 0) return 'No open spots reported';
    return '~$totalEstimatedOpenSpots spot${totalEstimatedOpenSpots == 1 ? '' : 's'} '
        'open across $zonesWithOpenSpots zone${zonesWithOpenSpots == 1 ? '' : 's'}';
  }

  /// Coverage percentage: zones with data / total zones.
  double get coveragePercent {
    if (totalZones == 0) return 0;
    return ((totalZones - blindSpotZones) / totalZones * 100).clamp(0, 100);
  }
}
