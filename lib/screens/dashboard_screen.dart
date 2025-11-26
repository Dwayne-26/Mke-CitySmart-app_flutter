import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('CitySmart'),
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Dashboard', style: textTheme.headlineMedium),
            const SizedBox(height: 20),
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 1.1,
                children: [
                  HomeTile(
                    icon: Icons.local_parking,
                    title: 'Parking',
                    subtitle: 'Find, monitor, pay',
                    onTap: () => Navigator.pushNamed(context, '/parking'),
                  ),
                  HomeTile(
                    icon: Icons.delete_outline,
                    title: 'Garbage Day',
                    subtitle: 'Pickup schedules',
                    onTap: () => Navigator.pushNamed(context, '/garbage'),
                  ),
                  HomeTile(
                    icon: Icons.ev_station_outlined,
                    title: 'EV Chargers',
                    subtitle: 'Nearby stations',
                    onTap: () => Navigator.pushNamed(context, '/charging'),
                  ),
                  HomeTile(
                    icon: Icons.notifications_active_outlined,
                    title: 'Alerts',
                    subtitle: 'Risks & reminders',
                    onTap: () => Navigator.pushNamed(context, '/preferences'),
                  ),
                  HomeTile(
                    icon: Icons.compare_arrows,
                    title: 'Alt-side parking',
                    subtitle: 'Today’s side + schedule',
                    onTap: () => Navigator.pushNamed(
                      context,
                      '/alternate-parking',
                    ),
                  ),
                  HomeTile(
                    icon: Icons.map,
                    title: 'Parking heatmap',
                    subtitle: 'Where to find a spot',
                    onTap: () =>
                        Navigator.pushNamed(context, '/parking-heatmap'),
                  ),
                  HomeTile(
                    icon: Icons.warning_amber_rounded,
                    title: 'Report sighting',
                    subtitle: 'Tow/Enforcer',
                    onTap: () =>
                        Navigator.pushNamed(context, '/report-sighting'),
                  ),
                  HomeTile(
                    icon: Icons.receipt_long,
                    title: 'Tickets',
                    subtitle: 'Lookup & pay',
                    onTap: () => Navigator.pushNamed(context, '/tickets'),
                  ),
                  HomeTile(
                    icon: Icons.workspace_premium,
                    title: 'Subscriptions',
                    subtitle: 'Plans & waivers',
                    onTap: () =>
                        Navigator.pushNamed(context, '/subscriptions'),
                  ),
                  HomeTile(
                    icon: Icons.settings,
                    title: 'City settings',
                    subtitle: 'City & language',
                    onTap: () =>
                        Navigator.pushNamed(context, '/city-settings'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            PromoBannerCard(
              text: 'Start saving today with Auto Insurance?',
              onTap: () => Navigator.pushNamed(context, '/subscriptions'),
            ),
          ],
        ),
      ),
    );
  }
}

class HomeTile extends StatelessWidget {
  const HomeTile({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    const tileBg = Color(0xFF0D2A26);
    const tileBorder = Color(0xFF174139);
    const accent = Color(0xFFF8C660);
    const textColor = Colors.white;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap ?? () {},
        child: Ink(
          decoration: BoxDecoration(
            color: tileBg,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: tileBorder, width: 1),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, size: 40, color: accent),
              const Spacer(),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: textColor,
                ),
              ),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: textColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class PromoBannerCard extends StatelessWidget {
  const PromoBannerCard({
    super.key,
    required this.text,
    required this.onTap,
  });

  final String text;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: kCitySmartYellow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          child: Text(
            text,
            style: const TextStyle(
              color: kCitySmartGreen,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}
