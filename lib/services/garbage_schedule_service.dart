import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/garbage_schedule.dart';

class GarbageScheduleService {
  GarbageScheduleService({required this.baseUrl, this.authToken});

  final String baseUrl;
  final String? authToken;

  Map<String, String> _headers() {
    final headers = <String, String>{
      'Content-Type': 'application/json',
    };
    if (authToken != null && authToken!.isNotEmpty) {
      headers['Authorization'] = 'Bearer $authToken';
    }
    return headers;
  }

  Future<List<GarbageSchedule>> fetchByLocation({
    required double latitude,
    required double longitude,
  }) async {
    final uri = Uri.parse('$baseUrl/query').replace(queryParameters: {
      'f': 'json',
      'geometry': '$longitude,$latitude',
      'geometryType': 'esriGeometryPoint',
      'inSR': '4326',
      'spatialRel': 'esriSpatialRelIntersects',
      'outFields': '*',
      'returnGeometry': 'false',
    });
    final resp = await http.get(uri, headers: _headers());
    if (resp.statusCode != 200) {
      throw Exception('Failed to fetch schedule: ${resp.statusCode}');
    }
    final data = jsonDecode(resp.body) as Map<String, dynamic>;
    final features = (data['features'] as List<dynamic>? ?? [])
        .cast<Map<String, dynamic>>();
    return features.map(_fromFeature).toList();
  }

  Future<List<GarbageSchedule>> fetchByAddress(String address) async {
    final where = "UPPER(ADDRESS) LIKE '%${address.toUpperCase()}%'";
    final uri = Uri.parse('$baseUrl/query').replace(queryParameters: {
      'f': 'json',
      'where': where,
      'outFields': '*',
      'returnGeometry': 'false',
    });
    final resp = await http.get(uri, headers: _headers());
    if (resp.statusCode != 200) {
      throw Exception('Failed to fetch schedule: ${resp.statusCode}');
    }
    final data = jsonDecode(resp.body) as Map<String, dynamic>;
    final features = (data['features'] as List<dynamic>? ?? [])
        .cast<Map<String, dynamic>>();
    return features.map(_fromFeature).toList();
  }

  GarbageSchedule _fromFeature(Map<String, dynamic> feature) {
    final attrs = feature['attributes'] as Map<String, dynamic>? ?? {};
    final typeStr =
        (attrs['type'] ?? attrs['service'] ?? attrs['material'] ?? '')
            .toString()
            .toLowerCase();
    final type = typeStr.contains('recycl') ? PickupType.recycling : PickupType.garbage;
    final route = (attrs['route'] ??
            attrs['routeId'] ??
            attrs['ROUTE'] ??
            'unknown')
        .toString();
    final addr = (attrs['address'] ??
            attrs['ADDRESS'] ??
            attrs['location'] ??
            attrs['LOCATION'] ??
            '')
        .toString();
    final pickupDate = _parseDate(
      attrs['pickupDate'] ??
          attrs['PICKUPDATE'] ??
          attrs['nextPickup'] ??
          attrs['NEXT_PICKUP'],
    );
    return GarbageSchedule(
      routeId: route,
      address: addr,
      pickupDate: pickupDate,
      type: type,
    );
  }

  DateTime _parseDate(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is int) {
      return DateTime.fromMillisecondsSinceEpoch(value);
    }
    if (value is String) {
      return DateTime.tryParse(value) ?? DateTime.now();
    }
    return DateTime.now();
  }
}
