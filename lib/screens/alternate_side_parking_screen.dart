import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../citysmart/theme.dart';
import '../providers/user_provider.dart';
import '../services/alternate_side_parking_service.dart';
import '../widgets/alternate_side_parking_card.dart';

class AlternateSideParkingScreen extends StatefulWidget {
  const AlternateSideParkingScreen({super.key});

  @override
  State<AlternateSideParkingScreen> createState() =>
      _AlternateSideParkingScreenState();
}

class _AlternateSideParkingScreenState
    extends State<AlternateSideParkingScreen> {
  final _service = AlternateSideParkingService();
  bool _morning = true;
  bool _evening = true;
  bool _midnight = true;

  int _addressNumberFromProfile(UserProvider provider) {
    final address = provider.profile?.address;
    if (address == null) return 0;
    final match = RegExp(r'(\\d+)').firstMatch(address);
    if (match == null) return 0;
    return int.tryParse(match.group(0) ?? '0') ?? 0;
  }

  Color _sideColor(ParkingSide side) =>
      side == ParkingSide.odd ? Colors.orange : Colors.blueAccent;

  String _sideLabel(ParkingSide side) =>
      side == ParkingSide.odd ? 'Odd side' : 'Even side';

  @override
  Widget build(BuildContext context) {
    return Consumer<UserProvider>(
      builder: (context, provider, _) {
        final addressNumber = _addressNumberFromProfile(provider);
        final status = _service.status(addressNumber: addressNumber);
        final schedule = _service.schedule();

        return Scaffold(
          appBar: AppBar(
            title: const Text('Alternate-side parking'),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AlternateSideParkingCard(
                  addressNumber: addressNumber,
                  service: _service,
                ),
                const SizedBox(height: 16),
                _InfoCard(
                  title: 'Today & tomorrow',
                  child: Column(
                    children: [
                      _DayRow(
                        label: 'Today',
                        date: status.now,
                        side: status.sideToday,
                        isSoon: status.isSwitchSoon,
                        subtitle:
                            'Switch at ${TimeOfDay.fromDateTime(status.nextSwitch).format(context)}',
                      ),
                      const Divider(height: 24),
                      _DayRow(
                        label: 'Tomorrow',
                        date: status.now.add(const Duration(days: 1)),
                        side: status.sideTomorrow,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                _InfoCard(
                  title: 'Upcoming 14 days',
                  child: Column(
                    children: schedule
                        .map(
                          (day) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            child: Row(
                              children: [
                                Container(
                                  width: 32,
                                  height: 32,
                                  decoration: BoxDecoration(
                                    color: _sideColor(day.side).withValues(alpha: 0.16),
                                    shape: BoxShape.circle,
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(
                                    day.date.day.toString(),
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      color: _sideColor(day.side),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '${_weekday(day.date)} • ${_sideLabel(day.side)}',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                          color: CSTheme.text,
                                        ),
                                      ),
                                      if (day.isToday)
                                        const Text(
                                          'Today',
                                          style: TextStyle(
                                            color: CSTheme.textMuted,
                                          ),
                                        )
                                      else if (day.isTomorrow)
                                        const Text(
                                          'Tomorrow',
                                          style: TextStyle(
                                            color: CSTheme.textMuted,
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ),
                const SizedBox(height: 16),
                _InfoCard(
                  title: 'How it works',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      _Bullet(text: 'Odd calendar days → park on odd-numbered addresses.'),
                      _Bullet(text: 'Even calendar days → park on even-numbered addresses.'),
                      _Bullet(text: 'Side flips automatically at midnight.'),
                      _Bullet(text: 'Warnings if a flip is within 2 hours.'),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                _InfoCard(
                  title: 'Notification settings',
                  child: Column(
                    children: [
                      SwitchListTile.adaptive(
                        title: const Text('Morning reminder'),
                        subtitle:
                            const Text('Low priority, daily context on the correct side.'),
                        value: _morning,
                        onChanged: (value) => setState(() => _morning = value),
                      ),
                      SwitchListTile.adaptive(
                        title: const Text('Evening warning'),
                        subtitle:
                            const Text('Medium priority, warns before the midnight flip.'),
                        value: _evening,
                        onChanged: (value) => setState(() => _evening = value),
                      ),
                      SwitchListTile.adaptive(
                        title: const Text('Midnight alert'),
                        subtitle: const Text(
                            'High priority, alerts when the side changes at midnight.'),
                        value: _midnight,
                        onChanged: (value) => setState(() => _midnight = value),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Notification toggles shown for UX; connect to your push scheduling service to persist.',
                        style: TextStyle(color: CSTheme.textMuted),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                _InfoCard(
                  title: 'Tips',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      _Bullet(text: 'Move early if you see a “switch soon” warning.'),
                      _Bullet(text: 'Double-check after midnight if you park late.'),
                      _Bullet(text: 'If your address is unknown, we default to showing the rule.'),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _weekday(DateTime date) {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return days[date.weekday - 1];
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: CSTheme.text,
              ),
            ),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}

class _DayRow extends StatelessWidget {
  const _DayRow({
    required this.label,
    required this.date,
    required this.side,
    this.isSoon = false,
    this.subtitle,
  });

  final String label;
  final DateTime date;
  final ParkingSide side;
  final bool isSoon;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final color = side == ParkingSide.odd ? Colors.orange : Colors.blueAccent;
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.calendar_today, size: 16, color: color),
              const SizedBox(width: 6),
              Text(
                '$label • ${date.month}/${date.day}',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                side == ParkingSide.odd ? 'Odd side' : 'Even side',
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  color: CSTheme.text,
                ),
              ),
              if (subtitle != null)
                Text(
                  subtitle!,
                  style: const TextStyle(color: CSTheme.textMuted),
                ),
            ],
          ),
        ),
        if (isSoon)
          const Icon(Icons.warning_amber_rounded,
              color: Colors.redAccent, size: 20),
      ],
    );
  }
}

class _Bullet extends StatelessWidget {
  const _Bullet({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('• ',
              style: TextStyle(fontWeight: FontWeight.bold, color: CSTheme.text)),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(color: CSTheme.textMuted),
            ),
          ),
        ],
      ),
    );
  }
}
