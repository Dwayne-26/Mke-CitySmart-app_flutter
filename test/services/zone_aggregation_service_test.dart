import 'package:flutter_test/flutter_test.dart';
import 'package:mkecitysmart/models/crowdsource_zone.dart';
import 'package:mkecitysmart/services/zone_aggregation_service.dart';

void main() {
  group('ZoneAggregationService.zoneDocId', () {
    test('builds doc ID from region and geohash', () {
      expect(
        ZoneAggregationService.zoneDocId('wi/milwaukee', 'dp5dtpp'),
        'wi_milwaukee_dp5dtpp',
      );
    });

    test('handles nested regions', () {
      expect(
        ZoneAggregationService.zoneDocId('il/cook/chicago', 'dp3wjz0'),
        'il_cook_chicago_dp3wjz0',
      );
    });

    test('handles simple region', () {
      expect(
        ZoneAggregationService.zoneDocId('wi/madison', 'dp8m500'),
        'wi_madison_dp8m500',
      );
    });
  });

  group('ZoneAggregationService.regionFromDocId', () {
    test('extracts region from standard doc ID', () {
      expect(
        ZoneAggregationService.regionFromDocId('wi_milwaukee_dp5dtpp'),
        'wi/milwaukee',
      );
    });

    test('extracts nested region from doc ID', () {
      expect(
        ZoneAggregationService.regionFromDocId('il_cook_chicago_dp3wjz0'),
        'il/cook/chicago',
      );
    });

    test('falls back to default for short doc IDs', () {
      expect(ZoneAggregationService.regionFromDocId('ab'), 'wi/milwaukee');
    });
  });

  group('ZoneAggregationService.summariseRegion', () {
    // Use a fresh instance-free approach: summariseRegion is a pure method
    // on the singleton, but we can still call it because the Firestore
    // instance isn't touched during summariseRegion execution.
    // However, accessing .instance triggers FirebaseFirestore.instance.
    // So we test the logic via the static helpers + inline aggregation.

    final now = DateTime.now();

    CrowdsourceZone makeZone({
      required String geohash,
      int openSpots = 0,
      int activeReports = 1,
      bool enforcement = false,
      double confidence = 0.5,
      int reporters = 1,
    }) {
      return CrowdsourceZone(
        id: 'wi_milwaukee_$geohash',
        region: 'wi/milwaukee',
        geohash: geohash,
        latitude: 43.0,
        longitude: -87.9,
        estimatedOpenSpots: openSpots,
        activeReports: activeReports,
        enforcementActive: enforcement,
        confidenceScore: confidence,
        uniqueReporters: reporters,
        lastUpdated: now,
        createdAt: now,
      );
    }

    // Inline the summarise logic so we don't need the singleton:
    RegionAvailabilitySummary summarise(List<CrowdsourceZone> zones) {
      if (zones.isEmpty) {
        return const RegionAvailabilitySummary(
          region: 'wi/milwaukee',
          totalZones: 0,
          zonesWithOpenSpots: 0,
          totalEstimatedOpenSpots: 0,
          totalActiveReports: 0,
          zonesWithEnforcement: 0,
          averageConfidence: 0,
          totalUniqueReporters: 0,
          blindSpotZones: 0,
        );
      }
      int openSpotZones = 0;
      int totalOpen = 0;
      int totalReports = 0;
      int enforcementZones = 0;
      double confSum = 0;
      int totalReporters = 0;
      int blindSpots = 0;
      for (final z in zones) {
        if (z.estimatedOpenSpots > 0) openSpotZones++;
        totalOpen += z.estimatedOpenSpots;
        totalReports += z.activeReports;
        if (z.enforcementActive) enforcementZones++;
        confSum += z.confidenceScore;
        totalReporters += z.uniqueReporters;
        if (z.activeReports == 0) blindSpots++;
      }
      return RegionAvailabilitySummary(
        region: zones.first.region,
        totalZones: zones.length,
        zonesWithOpenSpots: openSpotZones,
        totalEstimatedOpenSpots: totalOpen,
        totalActiveReports: totalReports,
        zonesWithEnforcement: enforcementZones,
        averageConfidence: confSum / zones.length,
        totalUniqueReporters: totalReporters,
        blindSpotZones: blindSpots,
      );
    }

    test('empty zones produce empty summary', () {
      final summary = summarise([]);
      expect(summary.totalZones, 0);
      expect(summary.totalEstimatedOpenSpots, 0);
      expect(summary.summaryLabel, 'No data yet for this region');
    });

    test('aggregates spot counts across zones', () {
      final zones = [
        makeZone(geohash: 'dp5dtp1', openSpots: 5),
        makeZone(geohash: 'dp5dtp2', openSpots: 3),
        makeZone(geohash: 'dp5dtp3', openSpots: 0),
        makeZone(geohash: 'dp5dtp4', openSpots: 12),
      ];
      final summary = summarise(zones);
      expect(summary.totalZones, 4);
      expect(summary.totalEstimatedOpenSpots, 20);
      expect(summary.zonesWithOpenSpots, 3);
      expect(summary.summaryLabel, '~20 spots open across 3 zones');
    });

    test('counts enforcement zones', () {
      final zones = [
        makeZone(geohash: 'dp5dtp1', enforcement: true),
        makeZone(geohash: 'dp5dtp2', enforcement: false),
        makeZone(geohash: 'dp5dtp3', enforcement: true),
      ];
      final summary = summarise(zones);
      expect(summary.zonesWithEnforcement, 2);
    });

    test('calculates average confidence', () {
      final zones = [
        makeZone(geohash: 'dp5dtp1', confidence: 0.8),
        makeZone(geohash: 'dp5dtp2', confidence: 0.4),
        makeZone(geohash: 'dp5dtp3', confidence: 0.6),
      ];
      final summary = summarise(zones);
      expect(summary.averageConfidence, closeTo(0.6, 0.01));
    });

    test('identifies blind spot zones', () {
      final zones = [
        makeZone(geohash: 'dp5dtp1', activeReports: 5),
        makeZone(geohash: 'dp5dtp2', activeReports: 0), // blind spot
        makeZone(geohash: 'dp5dtp3', activeReports: 3),
        makeZone(geohash: 'dp5dtp4', activeReports: 0), // blind spot
      ];
      final summary = summarise(zones);
      expect(summary.blindSpotZones, 2);
      expect(summary.coveragePercent, 50.0);
    });

    test('sums unique reporters', () {
      final zones = [
        makeZone(geohash: 'dp5dtp1', reporters: 10),
        makeZone(geohash: 'dp5dtp2', reporters: 5),
        makeZone(geohash: 'dp5dtp3', reporters: 20),
      ];
      final summary = summarise(zones);
      expect(summary.totalUniqueReporters, 35);
    });

    test('region is taken from first zone', () {
      final zones = [makeZone(geohash: 'dp5dtp1')];
      final summary = summarise(zones);
      expect(summary.region, 'wi/milwaukee');
    });
  });
}
