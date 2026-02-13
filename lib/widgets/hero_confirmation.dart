import 'dart:math';

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Shows a "Community Hero" confirmation bottom sheet after a user submits
/// a sighting or parking report — emotional reward for protecting others.
Future<void> showHeroConfirmation(
  BuildContext context, {
  required String reportType,
  int usersWarned = 0,
}) {
  return showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (_) =>
        _HeroSheet(reportType: reportType, usersWarned: usersWarned),
  );
}

// ──────────────────────────────────────────────────────────────────────────
// Rotating messages — they personalise the emotional impact
// ──────────────────────────────────────────────────────────────────────────

const _sightingMessages = [
  "You just helped a single parent avoid a ticket they can't afford.",
  'Someone on a tight budget just got warned — because of you.',
  'A college student just dodged a tow truck. You did that.',
  'A nurse coming off a double shift just got a heads-up. Thank you.',
  "You're now a neighborhood hero. Drivers near you are safer.",
  "Because of you, someone won't have to choose between a ticket and groceries.",
  'You just saved someone from a really bad day. Seriously.',
  'A family on a tight budget just breathed a sigh of relief.',
];

const _parkingMessages = [
  'Someone circling the block just found their spot — thanks to you.',
  'You just saved a driver 15 minutes of frustration. That matters.',
  'A parent running late for pickup just got a break. You did that.',
  'Less circling means less exhaust. You just helped the neighborhood breathe.',
  "You made parking a little less painful for someone. That's huge.",
  'Someone who was about to give up just scored a spot. Thank you.',
  "You're making Milwaukee a little kinder, one report at a time.",
  'A delivery driver on a deadline just got a lead. Nice work.',
];

class _HeroSheet extends StatefulWidget {
  const _HeroSheet({required this.reportType, required this.usersWarned});

  final String reportType;
  final int usersWarned;

  @override
  State<_HeroSheet> createState() => _HeroSheetState();
}

class _HeroSheetState extends State<_HeroSheet>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scaleAnim;
  late final Animation<double> _fadeAnim;
  late final String _message;

  bool get _isSighting =>
      widget.reportType == 'Parking Enforcer' ||
      widget.reportType == 'Tow Truck';

  @override
  void initState() {
    super.initState();
    final rng = Random();
    final pool = _isSighting ? _sightingMessages : _parkingMessages;
    _message = pool[rng.nextInt(pool.length)];

    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _scaleAnim = CurvedAnimation(parent: _ctrl, curve: Curves.elasticOut);
    _fadeAnim = CurvedAnimation(parent: _ctrl, curve: Curves.easeIn);
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewPadding.bottom;

    return Container(
      decoration: const BoxDecoration(
        color: kCitySmartCard,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(24, 28, 24, 20 + bottom),
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (context, child) =>
            Opacity(opacity: _fadeAnim.value, child: child),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Hero badge
            ScaleTransition(
              scale: _scaleAnim,
              child: Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [
                      kCitySmartYellow,
                      kCitySmartYellow.withValues(alpha: 0.7),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: const Icon(
                  Icons.shield_rounded,
                  color: kCitySmartGreen,
                  size: 38,
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Title
            const Text(
              'Community Hero',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: kCitySmartYellow,
                letterSpacing: 0.4,
              ),
            ),
            const SizedBox(height: 6),

            // Report type label
            Text(
              '${widget.reportType} reported',
              style: const TextStyle(fontSize: 14, color: kCitySmartMuted),
            ),
            const SizedBox(height: 20),

            // Impact count (only for sightings with actual fan-out)
            if (_isSighting && widget.usersWarned > 0)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: _ImpactCounter(count: widget.usersWarned),
              ),

            // Emotional message
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                _message,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  color: kCitySmartText,
                  height: 1.45,
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Dismiss
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                style: TextButton.styleFrom(
                  foregroundColor: kCitySmartYellow,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(
                      color: kCitySmartYellow.withValues(alpha: 0.3),
                    ),
                  ),
                ),
                child: const Text(
                  'Keep Protecting MKE',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────
// "X drivers warned" counter with an animated count-up
// ──────────────────────────────────────────────────────────────────────────

class _ImpactCounter extends StatelessWidget {
  const _ImpactCounter({required this.count});
  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        color: kCitySmartYellow.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.notifications_active_rounded,
            color: kCitySmartYellow,
            size: 20,
          ),
          const SizedBox(width: 8),
          TweenAnimationBuilder<int>(
            tween: IntTween(begin: 0, end: count),
            duration: const Duration(milliseconds: 900),
            curve: Curves.easeOutCubic,
            builder: (context, value, _) => Text(
              '$value driver${value == 1 ? '' : 's'} warned',
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: kCitySmartYellow,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
