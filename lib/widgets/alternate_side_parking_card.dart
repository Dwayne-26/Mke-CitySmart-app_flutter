import 'package:flutter/material.dart';

import '../citysmart/theme.dart';
import '../services/alternate_side_parking_service.dart';

class AlternateSideParkingCard extends StatelessWidget {
  const AlternateSideParkingCard({
    super.key,
    required this.addressNumber,
    this.onTap,
    this.service,
  });

  final int addressNumber;
  final VoidCallback? onTap;
  final AlternateSideParkingService? service;

  Color _badgeColor(ParkingSide side) {
    return side == ParkingSide.odd ? Colors.orange : Colors.blueAccent;
  }

  String _sideLabel(ParkingSide side) {
    return side == ParkingSide.odd ? 'Odd side' : 'Even side';
  }

  @override
  Widget build(BuildContext context) {
    final svc = service ?? AlternateSideParkingService();
    final status = svc.status(addressNumber: addressNumber);
    final schedule = svc.schedule(days: 3);
    final today = schedule.first;
    final tomorrow = schedule.length > 1 ? schedule[1] : null;

    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: CSTheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: CSTheme.border),
          boxShadow: const [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 16,
              offset: Offset(0, 10),
            ),
          ],
        ),
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: _badgeColor(today.side).withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.calendar_today,
                          size: 18, color: _badgeColor(today.side)),
                      const SizedBox(width: 8),
                      Text(
                        'Today: ${_sideLabel(today.side)}',
                        style: TextStyle(
                          color: _badgeColor(today.side),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                if (status.isSwitchSoon)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.redAccent),
                    ),
                    child: Row(
                      children: const [
                        Icon(Icons.warning_amber_rounded,
                            color: Colors.redAccent, size: 18),
                        SizedBox(width: 6),
                        Text(
                          'Switch soon',
                          style: TextStyle(
                            color: Colors.redAccent,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Next switch at ${TimeOfDay.fromDateTime(status.nextSwitch).format(context)}',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: CSTheme.text,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              status.isPlacementCorrect
                  ? 'You are parked on the correct side for today.'
                  : 'Move to the ${_sideLabel(today.side)} to avoid a ticket.',
              style: TextStyle(
                color: status.isPlacementCorrect
                    ? CSTheme.textMuted
                    : Colors.redAccent,
                fontWeight:
                    status.isPlacementCorrect ? FontWeight.w500 : FontWeight.w700,
              ),
            ),
            if (tomorrow != null) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.north_east,
                      size: 18, color: _badgeColor(tomorrow.side)),
                  const SizedBox(width: 8),
                  Text(
                    'Tomorrow: ${_sideLabel(tomorrow.side)}',
                    style: TextStyle(
                      color: _badgeColor(tomorrow.side),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
