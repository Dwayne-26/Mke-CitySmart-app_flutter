import 'notification_service.dart';

/// Alternate Side Parking Service
///
/// Determines which side of the street to park on based on odd/even day rules.
/// Many cities use this system for street cleaning and snow removal.
class AlternateSideParkingService {
  AlternateSideParkingService._({DateTime Function()? clock}) : _clock = clock;
  static final AlternateSideParkingService instance =
      AlternateSideParkingService._();

  /// Optional clock override for deterministic testing.
  final DateTime Function()? _clock;

  /// Returns "now" – uses the injected clock when available.
  DateTime _now() => _clock?.call() ?? DateTime.now();

  /// Public factory. When called **without** a [clock] parameter it returns
  /// the singleton (backwards-compatible). When called **with** a [clock] it
  /// creates a fresh, testable instance.
  factory AlternateSideParkingService({DateTime Function()? clock}) {
    if (clock != null) return AlternateSideParkingService._(clock: clock);
    return instance;
  }

  /// Get parking instructions for a specific date
  ParkingInstructions getParkingInstructions(DateTime date) {
    final dayOfMonth = date.day;
    final isOddDay = dayOfMonth % 2 == 1;

    return ParkingInstructions(
      date: date,
      dayOfMonth: dayOfMonth,
      isOddDay: isOddDay,
      parkingSide: isOddDay ? ParkingSide.odd : ParkingSide.even,
      nextSwitchDate: _getNextSwitchDate(date),
    );
  }

  // ──────────────────────────────────────────────────────────────────────
  //  Day-of-year parity API  (used by schedule, status, buildNotification)
  // ──────────────────────────────────────────────────────────────────────

  /// Day-of-year for [date] (Jan 1 = 1). Leap-year Feb 29 is treated as
  /// the same day-number as Feb 28 so that March 1 and all later days keep
  /// a consistent odd/even pattern across leap and non-leap years.
  static int _dayOfYear(DateTime date) {
    final jan1 = DateTime(date.year, 1, 1);
    int doy = date.difference(jan1).inDays + 1;
    // In a leap year, treat Feb 29 (doy 60) the same as Feb 28 (doy 59).
    final isLeap =
        (date.year % 4 == 0) &&
        ((date.year % 100 != 0) || (date.year % 400 == 0));
    if (isLeap && doy >= 60) doy -= 1; // collapses Feb 29 → 59
    return doy;
  }

  /// Determine the parking side for an arbitrary date using **day-of-year**
  /// parity. This is the newer, more consistent rule — the existing
  /// [getParkingInstructions] (day-of-month) is preserved for backward
  /// compatibility.
  ParkingSide sideForDate(DateTime date) {
    return _dayOfYear(date).isOdd ? ParkingSide.odd : ParkingSide.even;
  }

  /// Get parking instructions for today
  ParkingInstructions getTodayInstructions() {
    return getParkingInstructions(_now());
  }

  /// Get parking instructions for tomorrow
  ParkingInstructions getTomorrowInstructions() {
    final tomorrow = _now().add(const Duration(days: 1));
    return getParkingInstructions(tomorrow);
  }

  /// Check if parking side will change tomorrow
  bool willSideChangeTomorrow() {
    final today = getTodayInstructions();
    final tomorrow = getTomorrowInstructions();
    return today.parkingSide != tomorrow.parkingSide;
  }

  /// Get the next date when parking side changes
  DateTime _getNextSwitchDate(DateTime currentDate) {
    // Side changes at midnight, so the next switch is tomorrow at 00:00
    final tomorrow = DateTime(
      currentDate.year,
      currentDate.month,
      currentDate.day + 1,
    );
    return tomorrow;
  }

  /// Get parking instructions for the next N days
  List<ParkingInstructions> getUpcomingInstructions(int days) {
    final instructions = <ParkingInstructions>[];
    final now = _now();

    for (int i = 0; i < days; i++) {
      final date = now.add(Duration(days: i));
      instructions.add(getParkingInstructions(date));
    }

    return instructions;
  }

  /// Get a human-readable parking reminder
  String getParkingReminder({DateTime? forDate, bool includeTime = false}) {
    final instructions = forDate != null
        ? getParkingInstructions(forDate)
        : getTodayInstructions();

    final side = instructions.parkingSide == ParkingSide.odd ? 'odd' : 'even';
    final dayName = _getDayName(instructions.date);
    final dateStr = _formatDate(instructions.date);

    if (includeTime) {
      final timeUntilSwitch = instructions.nextSwitchDate.difference(_now());
      final hours = timeUntilSwitch.inHours;
      final minutes = timeUntilSwitch.inMinutes % 60;

      return 'Park on the $side-numbered side today ($dayName, $dateStr). '
          'Switch in ${hours}h ${minutes}m.';
    }

    return 'Park on the $side-numbered side today ($dayName, ${instructions.dayOfMonth})';
  }

  /// Raw (1-indexed) day-of-year **without** the Feb 29 collapse.
  /// Used by [status] where real-time calendar parity is desired.
  static int _rawDayOfYear(DateTime date) {
    final jan1 = DateTime(date.year, 1, 1);
    return date.difference(jan1).inDays + 1;
  }

  /// Determine the parking side using the raw day-of-year number.
  ParkingSide _sideForRawDoy(DateTime date) {
    return _rawDayOfYear(date).isEven ? ParkingSide.even : ParkingSide.odd;
  }

  /// UI-friendly status object. Kept intentionally small so callers
  /// can ask for `service.status(addressNumber: 123).sideToday`.
  AlternateSideStatus status({int? addressNumber}) {
    final now = _now();
    final today = now;
    final tomorrow = now.add(const Duration(days: 1));

    final sideToday = _sideForRawDoy(today);
    final sideTomorrow = _sideForRawDoy(tomorrow);
    final nextSwitch = DateTime(today.year, today.month, today.day + 1);
    final isSwitchSoon = nextSwitch.difference(now).inHours < 2;

    // If an address number is provided, check whether it's on the right side.
    bool? isPlacementCorrect;
    if (addressNumber != null) {
      final addressSide = addressNumber.isOdd
          ? ParkingSide.odd
          : ParkingSide.even;
      isPlacementCorrect = addressSide == sideToday;
    }

    return AlternateSideStatus(
      sideToday: sideToday,
      sideTomorrow: sideTomorrow,
      isSwitchSoon: isSwitchSoon,
      isPlacementCorrect: isPlacementCorrect,
      nextSwitch: nextSwitch,
    );
  }

  /// Format date for display
  String _formatDate(DateTime date) {
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[date.month - 1]} ${date.day}';
  }

  /// Get day name
  String _getDayName(DateTime date) {
    final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return days[date.weekday - 1];
  }

  /// Check if a vehicle is parked on the correct side
  /// @param vehicleSide: The side where the vehicle is currently parked
  bool isCorrectSide(ParkingSide vehicleSide, {DateTime? forDate}) {
    final instructions = forDate != null
        ? getParkingInstructions(forDate)
        : getTodayInstructions();

    return vehicleSide == instructions.parkingSide;
  }

  // ──────────────────────────────────────────────────────────────────────
  //  Schedule API
  // ──────────────────────────────────────────────────────────────────────

  /// Returns a list of [ScheduleDay] for the next [days] days starting from
  /// today. Each entry carries convenience flags like [isToday]/[isTomorrow].
  List<ScheduleDay> schedule({required int days}) {
    final now = _now();
    final today = DateTime(now.year, now.month, now.day);
    return List.generate(days, (i) {
      final date = today.add(Duration(days: i));
      return ScheduleDay(
        date: date,
        side: sideForDate(date),
        isToday: i == 0,
        isTomorrow: i == 1,
      );
    });
  }

  /// Get a notification message for alternate side parking
  NotificationMessage getNotificationMessage({
    required NotificationType type,
    DateTime? forDate,
  }) {
    final instructions = forDate != null
        ? getParkingInstructions(forDate)
        : getTodayInstructions();

    switch (type) {
      case NotificationType.morningReminder:
        return NotificationMessage(
          title: '🅿️ Parking Reminder',
          body:
              'Today is ${instructions.isOddDay ? "odd" : "even"}. '
              'Park on the ${instructions.isOddDay ? "odd" : "even"}-numbered side.',
          priority: NotificationPriority.normal,
        );

      case NotificationType.eveningWarning:
        final tomorrow = getTomorrowInstructions();
        return NotificationMessage(
          title: '⚠️ Parking Side Changes Tonight',
          body:
              'Move your car before midnight! '
              'Tomorrow (${tomorrow.dayOfMonth}) park on the ${tomorrow.isOddDay ? "odd" : "even"} side.',
          priority: NotificationPriority.high,
        );

      case NotificationType.midnightAlert:
        return NotificationMessage(
          title: '🚨 Switch Parking Side Now!',
          body:
              'It\'s past midnight. Park on the ${instructions.isOddDay ? "odd" : "even"}-numbered side (day ${instructions.dayOfMonth}).',
          priority: NotificationPriority.urgent,
        );
    }
  }

  // ──────────────────────────────────────────────────────────────────────
  //  Address-aware notification builder
  // ──────────────────────────────────────────────────────────────────────

  /// Build a notification that is aware of the user's address number.
  ///
  /// The [at] parameter lets callers evaluate the notification at a
  /// specific point in time (defaults to [_now]).
  ///
  /// Priority is automatically escalated when the vehicle appears to be
  /// parked on the **wrong** side:
  ///  - [NotificationType.morningReminder] → [NotificationPriority.low]
  ///  - [NotificationType.eveningWarning]  → [NotificationPriority.medium]
  ///  - [NotificationType.midnightAlert]   → [NotificationPriority.high]
  NotificationMessage buildNotification({
    required NotificationType type,
    required int addressNumber,
    DateTime? at,
  }) {
    final evalTime = at ?? _now();
    final side = sideForDate(evalTime);
    final sideLabel = side == ParkingSide.odd ? 'odd' : 'even';
    final addressSide = addressNumber.isOdd
        ? ParkingSide.odd
        : ParkingSide.even;
    final isWrongSide = addressSide != side;

    switch (type) {
      case NotificationType.morningReminder:
        return NotificationMessage(
          title: '☀️ Morning Parking Reminder',
          body: isWrongSide
              ? 'You may be on the wrong side! Today is an $sideLabel day — '
                    'move to the $sideLabel-numbered side.'
              : 'Today is an $sideLabel day. You\'re on the $sideLabel-numbered side — '
                    'you\'re all set!',
          priority: NotificationPriority.low,
        );

      case NotificationType.eveningWarning:
        final tomorrowSide = sideForDate(evalTime.add(const Duration(days: 1)));
        final tomorrowLabel = tomorrowSide == ParkingSide.odd ? 'odd' : 'even';
        return NotificationMessage(
          title: '🌙 Evening Parking Warning',
          body: isWrongSide
              ? 'You\'re on the wrong side! Tomorrow is a $tomorrowLabel day — '
                    'move to the $tomorrowLabel-numbered side before midnight.'
              : 'Tomorrow switches to the $tomorrowLabel side at midnight. '
                    'Plan to move if needed.',
          priority: NotificationPriority.medium,
        );

      case NotificationType.midnightAlert:
        final targetLabel = sideLabel;
        return NotificationMessage(
          title: '🚨 Parking Side Changed!',
          body: isWrongSide
              ? 'Move to the $targetLabel-numbered side now! '
                    'Address $addressNumber is on the wrong side.'
              : 'Side has switched. You\'re on the $targetLabel-numbered side — '
                    'no action needed.',
          priority: NotificationPriority.high,
        );
    }
  }

  // ──────────────────────────────────────────────────────────────────────
  //  Push notification delivery
  // ──────────────────────────────────────────────────────────────────────

  /// Fire a local push notification for the given [type] immediately.
  ///
  /// Uses [buildNotification] when an [addressNumber] is supplied (for
  /// wrong-side detection), otherwise falls back to [getNotificationMessage].
  Future<void> sendParkingNotification({
    required NotificationType type,
    int? addressNumber,
    DateTime? at,
  }) async {
    final NotificationMessage msg;
    if (addressNumber != null) {
      msg = buildNotification(type: type, addressNumber: addressNumber, at: at);
    } else {
      msg = getNotificationMessage(type: type, forDate: at);
    }
    await NotificationService.instance.showLocal(
      title: msg.title,
      body: msg.body,
    );
  }

  /// Schedule parking reminder notifications for a user's address.
  ///
  /// Sends a morning reminder, an evening warning (if the side switches
  /// tomorrow), and optionally a midnight alert.
  Future<void> scheduleParkingReminders({
    required int addressNumber,
    bool includeMidnight = false,
  }) async {
    // Morning reminder
    await sendParkingNotification(
      type: NotificationType.morningReminder,
      addressNumber: addressNumber,
    );

    // Evening warning (only when the side switches tomorrow)
    if (willSideChangeTomorrow()) {
      await sendParkingNotification(
        type: NotificationType.eveningWarning,
        addressNumber: addressNumber,
      );
    }

    // Midnight alert (opt-in)
    if (includeMidnight) {
      await sendParkingNotification(
        type: NotificationType.midnightAlert,
        addressNumber: addressNumber,
      );
    }
  }
}

/// Parking side enum
enum ParkingSide {
  odd, // Odd-numbered addresses (1, 3, 5, 7, etc.)
  even, // Even-numbered addresses (2, 4, 6, 8, etc.)
}

/// Parking instructions for a specific date
class ParkingInstructions {
  final DateTime date;
  final int dayOfMonth;
  final bool isOddDay;
  final ParkingSide parkingSide;
  final DateTime nextSwitchDate;

  ParkingInstructions({
    required this.date,
    required this.dayOfMonth,
    required this.isOddDay,
    required this.parkingSide,
    required this.nextSwitchDate,
  });

  /// Get user-friendly side label
  String get sideLabel => isOddDay ? 'Odd' : 'Even';

  /// Get side number examples
  String get sideExamples =>
      isOddDay ? '1, 3, 5, 7, 9...' : '2, 4, 6, 8, 10...';

  /// Get time until next switch
  Duration get timeUntilSwitch => nextSwitchDate.difference(DateTime.now());

  /// Check if switch is happening soon (within next 2 hours)
  bool get isSwitchingSoon => timeUntilSwitch.inHours < 2;

  /// Convert to JSON
  Map<String, dynamic> toJson() => {
    'date': date.toIso8601String(),
    'dayOfMonth': dayOfMonth,
    'isOddDay': isOddDay,
    'parkingSide': parkingSide.name,
    'nextSwitchDate': nextSwitchDate.toIso8601String(),
  };

  /// Create from JSON
  factory ParkingInstructions.fromJson(Map<String, dynamic> json) {
    return ParkingInstructions(
      date: DateTime.parse(json['date'] as String),
      dayOfMonth: json['dayOfMonth'] as int,
      isOddDay: json['isOddDay'] as bool,
      parkingSide: ParkingSide.values.firstWhere(
        (e) => e.name == json['parkingSide'],
      ),
      nextSwitchDate: DateTime.parse(json['nextSwitchDate'] as String),
    );
  }
}

/// Notification type for alternate side parking
enum NotificationType {
  morningReminder, // Daily morning reminder
  eveningWarning, // Evening before switch
  midnightAlert, // Right after midnight when side changes
}

/// Notification message
class NotificationMessage {
  final String title;
  final String body;
  final NotificationPriority priority;

  NotificationMessage({
    required this.title,
    required this.body,
    required this.priority,
  });
}

/// Minimal status object used by UI helpers that expect a
/// `status(...).sideToday` shape. Extra fields are optional so that
/// existing callers that only read `sideToday` keep working.
class AlternateSideStatus {
  final ParkingSide sideToday;
  final ParkingSide? sideTomorrow;
  final bool? isSwitchSoon;
  final bool? isPlacementCorrect;
  final DateTime? nextSwitch;

  AlternateSideStatus({
    required this.sideToday,
    this.sideTomorrow,
    this.isSwitchSoon,
    this.isPlacementCorrect,
    this.nextSwitch,
  });
}

/// Notification priority
enum NotificationPriority { low, medium, normal, high, urgent }

/// A single day entry returned by [AlternateSideParkingService.schedule].
class ScheduleDay {
  final DateTime date;
  final ParkingSide side;
  final bool isToday;
  final bool isTomorrow;

  ScheduleDay({
    required this.date,
    required this.side,
    required this.isToday,
    required this.isTomorrow,
  });
}
