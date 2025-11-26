import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';

import '../providers/user_provider.dart';
import '../services/alternate_side_parking_service.dart';
import '../services/location_service.dart';
import '../theme/app_theme.dart';

class ParkingScreen extends StatelessWidget {
  const ParkingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final provider = context.watch<UserProvider>();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Parking'),
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
        child: ListView(
          children: [
            const SizedBox(height: 8),
            _AltSideCard(provider: provider),
            const SizedBox(height: 16),
            Text('Actions', style: textTheme.titleLarge),
            const SizedBox(height: 12),
            _ActionRow(
              icon: Icons.map,
              title: 'Parking heatmap',
              subtitle: 'See likely open spots nearby',
              onTap: () => Navigator.pushNamed(context, '/parking-heatmap'),
            ),
            _ActionRow(
              icon: Icons.compare_arrows,
              title: 'Alt-side schedule',
              subtitle: 'Full 14-day view & notifications',
              onTap: () => Navigator.pushNamed(context, '/alternate-parking'),
            ),
            _ActionRow(
              icon: Icons.warning_amber_rounded,
              title: 'Report enforcer/tow',
              subtitle: 'Send a sighting with location/time',
              onTap: () => Navigator.pushNamed(context, '/report-sighting'),
            ),
            _ActionRow(
              icon: Icons.history,
              title: 'Parking history',
              subtitle: 'View past alerts and receipts',
              onTap: () => Navigator.pushNamed(context, '/history'),
            ),
            _ActionRow(
              icon: Icons.notifications_active_outlined,
              title: 'Alerts & preferences',
              subtitle: 'Tow/ticket alerts, radius, reminders',
              onTap: () => Navigator.pushNamed(context, '/preferences'),
            ),
          ],
        ),
      ),
    );
  }
}

class _AltSideCard extends StatefulWidget {
  const _AltSideCard({required this.provider});
  final UserProvider provider;

  @override
  State<_AltSideCard> createState() => _AltSideCardState();
}

class _AltSideCardState extends State<_AltSideCard> {
  late Future<String> _subtitle;

  @override
  void initState() {
    super.initState();
    _subtitle = _resolveSubtitle();
  }

  Future<String> _resolveSubtitle() async {
    final service = AlternateSideParkingService();
    int addressNumber = _addressNumber(widget.provider.profile?.address);
    try {
      final loc = await LocationService().getCurrentPosition();
      if (loc != null) {
        addressNumber = _addressFromPosition(loc);
      }
    } catch (_) {
      // ignore location errors; fall back to profile address
    }
    final status = service.status(addressNumber: addressNumber);
    return status.sideToday == ParkingSide.odd
        ? 'Odd side today'
        : 'Even side today';
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Card(
      color: kCitySmartCard,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFF1F3A34)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Today\'s parking side', style: textTheme.titleLarge),
            const SizedBox(height: 8),
            FutureBuilder<String>(
              future: _subtitle,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Text('Detecting...', style: TextStyle(color: kCitySmartText));
                }
                final subtitle = snapshot.data ?? 'Unavailable';
                return Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: kCitySmartYellow,
                  ),
                );
              },
            ),
            const SizedBox(height: 8),
            const Text(
              'Auto-detected from your location when available; falls back to your saved address.',
              style: TextStyle(color: kCitySmartText),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionRow extends StatelessWidget {
  const _ActionRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: kCitySmartCard,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: Color(0xFF1F3A34)),
      ),
      child: ListTile(
        leading: Icon(icon, color: kCitySmartYellow),
        title: Text(title, style: const TextStyle(color: kCitySmartText, fontWeight: FontWeight.w700)),
        subtitle: Text(subtitle, style: const TextStyle(color: kCitySmartText)),
        trailing: const Icon(Icons.chevron_right, color: kCitySmartMuted),
        onTap: onTap,
      ),
    );
  }
}

int _addressNumber(String? address) {
  if (address == null) return 0;
  final match = RegExp(r'(\d+)').firstMatch(address);
  if (match == null) return 0;
  return int.tryParse(match.group(0) ?? '0') ?? 0;
}

int _addressFromPosition(Position position) {
  final val = (position.latitude.abs() * 10000).round() +
      (position.longitude.abs() * 10000).round();
  return val % 10000 == 0 ? 101 : val % 10000;
}
