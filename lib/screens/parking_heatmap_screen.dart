import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/user_provider.dart';
import '../services/location_service.dart';
import '../services/parking_prediction_service.dart';
import '../services/parking_risk_service.dart';
import '../widgets/parking_risk_badge.dart';

class ParkingHeatmapScreen extends StatefulWidget {
  const ParkingHeatmapScreen({super.key});

  @override
  State<ParkingHeatmapScreen> createState() => _ParkingHeatmapScreenState();
}

class _ParkingHeatmapScreenState extends State<ParkingHeatmapScreen> {
  final _service = ParkingPredictionService();
  final _riskService = ParkingRiskService.instance;
  double _centerLat = 43.0389;
  double _centerLng = -87.9065;
  final _eventLoad = 0.2;
  List<PredictedPoint> _points = const [];
  bool _loading = true;
  String? _error;
  
  // Citation-based risk data
  LocationRisk? _locationRisk;
  List<RiskZone> _riskZones = [];
  bool _showCitationRisk = true; // Toggle between prediction and citation data

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    double lat = _centerLat;
    double lng = _centerLng;
    final userProvider = context.read<UserProvider>();
    try {
      final loc = await LocationService().getCurrentPosition();
      if (loc != null) {
        lat = loc.latitude;
        lng = loc.longitude;
      }
    } catch (e) {
      _error = 'Location unavailable; showing defaults.';
    }
    if (!mounted) return;
    
    // Load prediction points (local)
    final cityBias = _cityBias(userProvider.cityId);
    _points = _service.predictNearby(
      when: DateTime.now(),
      latitude: lat,
      longitude: lng,
      eventLoad: _eventLoad,
      samples: 60,
      cityBias: cityBias,
    );
    
    // Load citation-based risk data (from backend)
    try {
      final results = await Future.wait([
        _riskService.getRiskForLocation(lat, lng),
        _riskService.getRiskZones(
          minLat: lat - 0.05,
          maxLat: lat + 0.05,
          minLng: lng - 0.05,
          maxLng: lng + 0.05,
        ),
      ]);
      _locationRisk = results[0] as LocationRisk?;
      _riskZones = results[1] as List<RiskZone>;
    } catch (e) {
      debugPrint('Failed to load citation risk: $e');
    }
    
    setState(() {
      _centerLat = lat;
      _centerLng = lng;
      _loading = false;
    });
  }

  Color _scoreColor(double score) {
    // 0 -> red, 0.5 -> yellow, 1 -> green
    if (score < 0.33) {
      return Colors.redAccent.withValues(alpha: 0.6 + score * 0.2);
    } else if (score < 0.66) {
      return Colors.orangeAccent.withValues(alpha: 0.6 + (score - 0.33) * 0.2);
    }
    return Colors.greenAccent.withValues(alpha: 0.6 + (score - 0.66) * 0.2);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Parking Heatmap'),
        actions: [
          // Toggle between prediction and citation risk views
          IconButton(
            icon: Icon(_showCitationRisk ? Icons.warning : Icons.map),
            tooltip: _showCitationRisk ? 'Show availability' : 'Show risk zones',
            onPressed: () => setState(() => _showCitationRisk = !_showCitationRisk),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Risk badge at top when we have location risk data
            if (_locationRisk != null && _showCitationRisk) ...[
              ParkingRiskBadge(risk: _locationRisk!),
              const SizedBox(height: 16),
            ],
            Text(
              _showCitationRisk ? 'Citation Risk Zones' : 'Predicted availability',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  _error!,
                  style: const TextStyle(color: Colors.orangeAccent),
                ),
              ),
            if (_loading)
              const Expanded(
                child: Center(child: CircularProgressIndicator()),
              )
            else
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  // Map coords to a simple grid for demo purposes.
                  final minLat = _centerLat - 0.02;
                  final maxLat = _centerLat + 0.02;
                  final minLng = _centerLng - 0.02;
                  final maxLng = _centerLng + 0.02;

                  double toX(double lng) =>
                      ((lng - minLng) / (maxLng - minLng)) *
                      constraints.maxWidth;
                  double toY(double lat) =>
                      constraints.maxHeight -
                      ((lat - minLat) / (maxLat - minLat)) *
                          constraints.maxHeight;

                  return Stack(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.black12,
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      // Show citation risk zones when toggled
                      if (_showCitationRisk)
                        ..._riskZones.map((zone) {
                          final x = toX(zone.lng);
                          final y = toY(zone.lat);
                          if (x < 0 || x > constraints.maxWidth || 
                              y < 0 || y > constraints.maxHeight) {
                            return const SizedBox.shrink();
                          }
                          return Positioned(
                            left: x - 25,
                            top: y - 25,
                            child: _RiskZoneCircle(zone: zone),
                          );
                        })
                      else
                        ..._points.map((p) {
                          final x = toX(p.longitude);
                          final y = toY(p.latitude);
                          return Positioned(
                            left: x - 10,
                            top: y - 10,
                            child: Container(
                              width: 20,
                              height: 20,
                              decoration: BoxDecoration(
                                color: _scoreColor(p.score),
                                shape: BoxShape.circle,
                              ),
                            ),
                          );
                        }),
                      // Current location marker
                      Positioned(
                        left: toX(_centerLng) - 8,
                        top: toY(_centerLat) - 8,
                        child: Container(
                          width: 16,
                          height: 16,
                          decoration: BoxDecoration(
                            color: Colors.blue,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                        ),
                      ),
                      Positioned(
                        right: 12,
                        top: 12,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: _showCitationRisk
                              ? const [
                                  _LegendDot(color: Color(0xFFE53935), label: 'High risk'),
                                  SizedBox(height: 6),
                                  _LegendDot(color: Color(0xFFFFA726), label: 'Medium'),
                                  SizedBox(height: 6),
                                  _LegendDot(color: Color(0xFF66BB6A), label: 'Low risk'),
                                ]
                              : const [
                                  _LegendDot(color: Colors.greenAccent, label: 'High chance'),
                                  SizedBox(height: 6),
                                  _LegendDot(color: Colors.orangeAccent, label: 'Medium'),
                                  SizedBox(height: 6),
                                  _LegendDot(color: Colors.redAccent, label: 'Lower'),
                                ],
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Circle widget for risk zones
class _RiskZoneCircle extends StatelessWidget {
  const _RiskZoneCircle({required this.zone});
  final RiskZone zone;

  @override
  Widget build(BuildContext context) {
    final color = Color(_getColorValue());
    // Size based on citation count (more citations = larger circle)
    final size = 30.0 + (zone.totalCitations / 10000).clamp(0, 30);
    
    return Tooltip(
      message: '${zone.riskScore}% risk (${zone.totalCitations} citations)',
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.6),
          shape: BoxShape.circle,
          border: Border.all(color: color, width: 2),
        ),
        child: Center(
          child: Text(
            '${zone.riskScore}',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 10,
            ),
          ),
        ),
      ),
    );
  }

  int _getColorValue() {
    switch (zone.riskLevel) {
      case RiskLevel.high:
        return 0xFFE53935; // Red
      case RiskLevel.medium:
        return 0xFFFFA726; // Orange
      case RiskLevel.low:
        return 0xFF66BB6A; // Green
    }
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color, required this.label});
  final Color color;
  final String label;
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

double _cityBias(String cityId) {
  switch (cityId.toLowerCase()) {
    case 'milwaukee':
    case 'milwaukee-county':
      return 0.05;
    case 'chicago':
      return 0.08;
    case 'new-york':
    case 'nyc':
      return 0.1;
    default:
      return 0.04;
  }
}
