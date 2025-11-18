import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/parking_zone.dart';
import '../providers/location_provider.dart';

class LocationScreen extends StatelessWidget {
  const LocationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF003E29),
      appBar: AppBar(
        backgroundColor: const Color(0xFF003E29),
        title: const Text('Location & Navigation'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => context.read<LocationProvider>().refreshLocation(),
          ),
        ],
      ),
      body: Consumer<LocationProvider>(
        builder: (context, provider, _) {
          final zones = provider.sortedZones;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _LocationStatusCard(provider: provider),
              if (provider.emergencyMessage != null) ...[
                const SizedBox(height: 12),
                _EmergencyBanner(
                  message: provider.emergencyMessage!,
                  onDismissed: provider.acknowledgeEmergency,
                ),
              ],
              const SizedBox(height: 12),
              Text(
                'Zone schedules',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              ...zones.map(
                (zone) => _ZoneListTile(
                  zone: zone,
                  isSelected: provider.selectedZone?.id == zone.id,
                  onTap: () => provider.selectZone(zone),
                ),
              ),
              const SizedBox(height: 16),
              _SearchCard(provider: provider),
              const SizedBox(height: 16),
              _DirectionsCard(provider: provider),
              const SizedBox(height: 16),
              _ViolationHistory(provider: provider),
            ],
          );
        },
      ),
    );
  }
}

class _LocationStatusCard extends StatelessWidget {
  const _LocationStatusCard({required this.provider});

  final LocationProvider provider;

  @override
  Widget build(BuildContext context) {
    final position = provider.position;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.gps_fixed,
                  color: provider.gpsDenied ? Colors.redAccent : Colors.green,
                ),
                const SizedBox(width: 8),
                Text(
                  provider.gpsDenied
                      ? 'GPS permissions required'
                      : 'GPS tracking active',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (position == null)
              Text(
                provider.gpsDenied
                    ? 'Enable location services to unlock GPS alerts.'
                    : 'Locating…',
              )
            else
              Text(
                'Lat: ${position.latitude.toStringAsFixed(4)}, '
                'Lng: ${position.longitude.toStringAsFixed(4)}',
              ),
            const SizedBox(height: 8),
            Text(
              provider.insideGeofence
                  ? 'Inside an active sweeping zone'
                  : 'Outside sweeping zones',
              style: TextStyle(
                color: provider.insideGeofence ? Colors.red : Colors.black54,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmergencyBanner extends StatelessWidget {
  const _EmergencyBanner({required this.message, required this.onDismissed});

  final String message;
  final VoidCallback onDismissed;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.orange.shade100,
      child: ListTile(
        leading: const Icon(Icons.warning, color: Colors.orange),
        title: Text(message),
        trailing: IconButton(
          icon: const Icon(Icons.close),
          onPressed: onDismissed,
        ),
      ),
    );
  }
}

class _ZoneListTile extends StatelessWidget {
  const _ZoneListTile({
    required this.zone,
    required this.isSelected,
    required this.onTap,
  });

  final ParkingZone zone;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final subtitle =
        '${zone.description}\nNext sweep ${DateFormat('MMM d – h:mm a').format(zone.nextSweep)}';
    return Card(
      color: isSelected ? const Color(0xFFFFC107) : Colors.white,
      child: ListTile(
        onTap: onTap,
        title: Text(zone.name),
        subtitle: Text(subtitle),
        trailing: Icon(
          Icons.chevron_right,
          color: isSelected ? Colors.black : Colors.grey,
        ),
      ),
    );
  }
}

class _SearchCard extends StatelessWidget {
  const _SearchCard({required this.provider});

  final LocationProvider provider;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Address lookup',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            TextField(
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                hintText: 'Search an address or landmark',
              ),
              onChanged: provider.searchAddress,
            ),
            const SizedBox(height: 8),
            ...provider.addressSuggestions.map(
              (suggestion) => ListTile(
                leading: const Icon(Icons.place),
                title: Text(suggestion),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DirectionsCard extends StatelessWidget {
  const _DirectionsCard({required this.provider});

  final LocationProvider provider;

  @override
  Widget build(BuildContext context) {
    final zone = provider.selectedZone;
    if (zone == null) {
      return const SizedBox.shrink();
    }
    final directions = provider.walkingDirections;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Walking directions',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              zone.name,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            if (directions.isEmpty)
              const Text('Select a zone to view walking directions.')
            else
              ...directions.map(
                (step) => ListTile(
                  leading: const Icon(Icons.directions_walk),
                  title: Text(step),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ViolationHistory extends StatelessWidget {
  const _ViolationHistory({required this.provider});

  final LocationProvider provider;

  @override
  Widget build(BuildContext context) {
    final history = provider.violationHistory;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Violation history',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            Text(
              '${provider.preventedViolations} prevented • ${provider.ticketsReceived} tickets on record',
              style: const TextStyle(color: Colors.black54),
            ),
            const SizedBox(height: 12),
            ...history.map(
              (record) => ListTile(
                leading: Icon(
                  record.status == 'Prevented'
                      ? Icons.verified
                      : Icons.report_problem,
                  color: record.status == 'Prevented'
                      ? Colors.green
                      : Colors.redAccent,
                ),
                title: Text(record.zoneName),
                subtitle: Text(record.preventionReason),
                trailing: Text(
                  DateFormat('MMM d').format(record.date),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
