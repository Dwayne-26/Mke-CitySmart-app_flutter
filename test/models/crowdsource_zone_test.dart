import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mkecitysmart/models/crowdsource_zone.dart';

void main() {
  group('CrowdsourceZone', () {
    late CrowdsourceZone zone;
    late DateTime now;

    setUp(() {
      now = DateTime(2026, 2, 7, 14, 30);
      zone = CrowdsourceZone(
        id: 'wi_milwaukee_dp5dtpp',
        region: 'wi/milwaukee',
        geohash: 'dp5dtpp',
        name: 'Third Ward – N Water St',
        latitude: 43.0389,
        longitude: -87.9065,
        totalReportsAllTime: 150,
        activeReports: 12,
        estimatedOpenSpots: 7,
        activeAvailableSignals: 9,
        activeTakenSignals: 2,
        enforcementActive: false,
        sweepingActive: false,
        parkingBlocked: false,
        hourlyAvgOpenSpots: {8: 12.5, 9: 8.3, 17: 2.1},
        dailyAvgOpenSpots: {1: 10.0, 5: 4.5, 7: 15.0},
        enforcementPeakHours: [8, 9, 17],
        confidenceScore: 0.75,
        uniqueReporters: 30,
        lastUpdated: now,
        createdAt: now.subtract(const Duration(days: 30)),
      );
    });

    test('basic properties', () {
      expect(zone.id, 'wi_milwaukee_dp5dtpp');
      expect(zone.region, 'wi/milwaukee');
      expect(zone.geohash, 'dp5dtpp');
      expect(zone.name, 'Third Ward – N Water St');
      expect(zone.latitude, 43.0389);
      expect(zone.longitude, -87.9065);
      expect(zone.totalReportsAllTime, 150);
      expect(zone.activeReports, 12);
      expect(zone.estimatedOpenSpots, 7);
    });

    test('spotCountLabel shows estimated count', () {
      expect(zone.spotCountLabel, '~7 spots open');
    });

    test('spotCountLabel singular for 1 spot', () {
      final one = zone.copyWith(estimatedOpenSpots: 1);
      expect(one.spotCountLabel, '~1 spot open');
    });

    test('spotCountLabel for zero spots', () {
      final zero = zone.copyWith(estimatedOpenSpots: 0);
      expect(zero.spotCountLabel, 'No spots reported');
    });

    test('spotCountLabel with no reports', () {
      final noData = zone.copyWith(activeReports: 0);
      expect(noData.spotCountLabel, 'No reports yet');
    });

    test('availabilityLabel tiers', () {
      expect(
        zone.copyWith(estimatedOpenSpots: 15).availabilityLabel,
        'Plenty of spots',
      );
      expect(
        zone.copyWith(estimatedOpenSpots: 6).availabilityLabel,
        'Good availability',
      );
      expect(
        zone.copyWith(estimatedOpenSpots: 3).availabilityLabel,
        'Limited spots',
      );
      expect(
        zone.copyWith(estimatedOpenSpots: 1).availabilityLabel,
        'Very few spots',
      );
      expect(
        zone.copyWith(estimatedOpenSpots: 0).availabilityLabel,
        'No spots reported',
      );
      expect(zone.copyWith(activeReports: 0).availabilityLabel, 'No data');
    });

    test('availabilityColor based on spot count', () {
      expect(
        zone.copyWith(estimatedOpenSpots: 10).availabilityColor,
        Colors.green,
      );
      expect(
        zone.copyWith(estimatedOpenSpots: 3).availabilityColor,
        Colors.orange,
      );
      expect(
        zone.copyWith(estimatedOpenSpots: 0).availabilityColor,
        Colors.red,
      );
      expect(zone.copyWith(activeReports: 0).availabilityColor, Colors.grey);
    });

    test('confidenceLabel tiers', () {
      expect(
        zone.copyWith(confidenceScore: 0.8).confidenceLabel,
        'High confidence',
      );
      expect(
        zone.copyWith(confidenceScore: 0.5).confidenceLabel,
        'Moderate confidence',
      );
      expect(
        zone.copyWith(confidenceScore: 0.2).confidenceLabel,
        'Low confidence',
      );
    });

    test('hasAlerts reflects enforcement/sweeping/blocked', () {
      expect(zone.hasAlerts, isFalse);
      expect(zone.copyWith(enforcementActive: true).hasAlerts, isTrue);
      expect(zone.copyWith(sweepingActive: true).hasAlerts, isTrue);
      expect(zone.copyWith(parkingBlocked: true).hasAlerts, isTrue);
    });

    test('predictedSpotsForHour returns hourly avg or fallback', () {
      expect(zone.predictedSpotsForHour(8), 12.5);
      expect(zone.predictedSpotsForHour(17), 2.1);
      // Falls back to current estimate for unknown hours
      expect(zone.predictedSpotsForHour(3), 7.0);
    });

    test('predictedSpotsForDay returns daily avg or fallback', () {
      expect(zone.predictedSpotsForDay(1), 10.0); // Monday
      expect(zone.predictedSpotsForDay(7), 15.0); // Sunday
      expect(zone.predictedSpotsForDay(3), 7.0); // Wednesday — fallback
    });

    test('toJson / fromJson round-trip', () {
      final json = zone.toJson();
      expect(json['id'], 'wi_milwaukee_dp5dtpp');
      expect(json['region'], 'wi/milwaukee');
      expect(json['geohash'], 'dp5dtpp');
      expect(json['estimatedOpenSpots'], 7);
      expect(json['confidenceScore'], 0.75);

      final restored = CrowdsourceZone.fromJson(json);
      expect(restored.id, zone.id);
      expect(restored.region, zone.region);
      expect(restored.geohash, zone.geohash);
      expect(restored.estimatedOpenSpots, zone.estimatedOpenSpots);
      expect(restored.hourlyAvgOpenSpots[8], 12.5);
      expect(restored.dailyAvgOpenSpots[7], 15.0);
      expect(restored.enforcementPeakHours, [8, 9, 17]);
      expect(restored.confidenceScore, zone.confidenceScore);
    });

    test('fromJson handles missing optional fields', () {
      final minimal = {
        'id': 'wi_milwaukee_dp5dtqq',
        'region': 'wi/milwaukee',
        'geohash': 'dp5dtqq',
        'latitude': 43.04,
        'longitude': -87.91,
        'lastUpdated': now.toIso8601String(),
        'createdAt': now.toIso8601String(),
      };
      final parsed = CrowdsourceZone.fromJson(minimal);
      expect(parsed.name, isNull);
      expect(parsed.totalReportsAllTime, 0);
      expect(parsed.activeReports, 0);
      expect(parsed.estimatedOpenSpots, 0);
      expect(parsed.hourlyAvgOpenSpots, isEmpty);
      expect(parsed.dailyAvgOpenSpots, isEmpty);
      expect(parsed.enforcementPeakHours, isEmpty);
      expect(parsed.confidenceScore, 0.0);
    });

    test('copyWith creates modified copy', () {
      final updated = zone.copyWith(
        estimatedOpenSpots: 20,
        enforcementActive: true,
        confidenceScore: 0.9,
      );
      expect(updated.estimatedOpenSpots, 20);
      expect(updated.enforcementActive, isTrue);
      expect(updated.confidenceScore, 0.9);
      // Unchanged fields preserved
      expect(updated.id, zone.id);
      expect(updated.region, zone.region);
      expect(updated.geohash, zone.geohash);
      expect(updated.name, zone.name);
    });

    test('equality based on id', () {
      final duplicate = CrowdsourceZone(
        id: 'wi_milwaukee_dp5dtpp',
        region: 'different/region',
        geohash: 'xyz',
        latitude: 0,
        longitude: 0,
        lastUpdated: now,
        createdAt: now,
      );
      expect(zone, equals(duplicate));
      expect(zone.hashCode, duplicate.hashCode);

      final other = CrowdsourceZone(
        id: 'wi_milwaukee_dp5dtqq',
        region: 'wi/milwaukee',
        geohash: 'dp5dtqq',
        latitude: 43.04,
        longitude: -87.91,
        lastUpdated: now,
        createdAt: now,
      );
      expect(zone, isNot(equals(other)));
    });

    test('toString includes useful info', () {
      final str = zone.toString();
      expect(str, contains('wi_milwaukee_dp5dtpp'));
      expect(str, contains('wi/milwaukee'));
      expect(str, contains('dp5dtpp'));
      expect(str, contains('openSpots: 7'));
    });

    test('parseIntDoubleMap handles various inputs', () {
      expect(CrowdsourceZone.parseIntDoubleMap(null), isEmpty);
      expect(CrowdsourceZone.parseIntDoubleMap('not a map'), isEmpty);
      expect(CrowdsourceZone.parseIntDoubleMap({'8': 12.5, '17': 2.1}), {
        8: 12.5,
        17: 2.1,
      });
    });
  });

  group('RegionAvailabilitySummary', () {
    test('summaryLabel with data', () {
      final summary = RegionAvailabilitySummary(
        region: 'wi/milwaukee',
        totalZones: 50,
        zonesWithOpenSpots: 12,
        totalEstimatedOpenSpots: 47,
        totalActiveReports: 200,
        zonesWithEnforcement: 3,
        averageConfidence: 0.65,
        totalUniqueReporters: 80,
        blindSpotZones: 10,
      );
      expect(summary.summaryLabel, '~47 spots open across 12 zones');
      expect(summary.coveragePercent, 80.0);
    });

    test('summaryLabel singular zone', () {
      final summary = RegionAvailabilitySummary(
        region: 'wi/milwaukee',
        totalZones: 5,
        zonesWithOpenSpots: 1,
        totalEstimatedOpenSpots: 3,
        totalActiveReports: 10,
        zonesWithEnforcement: 0,
        averageConfidence: 0.4,
        totalUniqueReporters: 5,
        blindSpotZones: 2,
      );
      expect(summary.summaryLabel, '~3 spots open across 1 zone');
    });

    test('summaryLabel with no data', () {
      final summary = RegionAvailabilitySummary(
        region: 'wi/madison',
        totalZones: 0,
        zonesWithOpenSpots: 0,
        totalEstimatedOpenSpots: 0,
        totalActiveReports: 0,
        zonesWithEnforcement: 0,
        averageConfidence: 0,
        totalUniqueReporters: 0,
        blindSpotZones: 0,
      );
      expect(summary.summaryLabel, 'No data yet for this region');
      expect(summary.coveragePercent, 0);
    });

    test('summaryLabel with no open spots', () {
      final summary = RegionAvailabilitySummary(
        region: 'wi/milwaukee',
        totalZones: 10,
        zonesWithOpenSpots: 0,
        totalEstimatedOpenSpots: 0,
        totalActiveReports: 50,
        zonesWithEnforcement: 2,
        averageConfidence: 0.5,
        totalUniqueReporters: 20,
        blindSpotZones: 0,
      );
      expect(summary.summaryLabel, 'No open spots reported');
    });

    test('coveragePercent calculation', () {
      final full = RegionAvailabilitySummary(
        region: 'wi/milwaukee',
        totalZones: 100,
        zonesWithOpenSpots: 50,
        totalEstimatedOpenSpots: 200,
        totalActiveReports: 500,
        zonesWithEnforcement: 5,
        averageConfidence: 0.7,
        totalUniqueReporters: 100,
        blindSpotZones: 0,
      );
      expect(full.coveragePercent, 100.0);

      final half = RegionAvailabilitySummary(
        region: 'wi/milwaukee',
        totalZones: 100,
        zonesWithOpenSpots: 25,
        totalEstimatedOpenSpots: 100,
        totalActiveReports: 300,
        zonesWithEnforcement: 2,
        averageConfidence: 0.5,
        totalUniqueReporters: 50,
        blindSpotZones: 50,
      );
      expect(half.coveragePercent, 50.0);
    });
  });
}
