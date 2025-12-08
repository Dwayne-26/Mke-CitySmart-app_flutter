import 'package:flutter_test/flutter_test.dart';
import 'package:mkeparkapp_flutter/services/alternate_side_parking_service.dart';

void main() {
  group('AlternateSideParkingService', () {
    late DateTime fixed;
    late AlternateSideParkingService service;

    setUp(() {
      fixed = DateTime(2024, 3, 15, 10, 30); // March 15, 2024 is an odd day.
      service = AlternateSideParkingService(clock: () => fixed);
    });

    test('odd days map to odd side', () {
      expect(service.sideForDate(DateTime(2024, 3, 15)), ParkingSide.odd);
    });

    test('even days map to even side', () {
      expect(service.sideForDate(DateTime(2024, 3, 16)), ParkingSide.even);
    });

    test('next switch time is at midnight of next day', () {
      final next = service.nextSwitchTime(fixed);
      expect(next, DateTime(2024, 3, 16, 0, 0));
    });

    test('schedule produces 14 entries starting today', () {
      final schedule = service.schedule();
      expect(schedule.length, 14);
      expect(schedule.first.date.year, fixed.year);
      expect(schedule.first.date.month, fixed.month);
      expect(schedule.first.date.day, fixed.day);
    });

    test('switch soon when within 2 hours', () {
      final nearMidnight = DateTime(2024, 3, 15, 23, 0);
      service = AlternateSideParkingService(clock: () => nearMidnight);
      final status = service.status(addressNumber: 101);
      expect(status.isSwitchSoon, isTrue);
    });

    test('not switch soon when more than 2 hours away', () {
      final midMorning = DateTime(2024, 3, 15, 9, 0);
      service = AlternateSideParkingService(clock: () => midMorning);
      final status = service.status(addressNumber: 101);
      expect(status.isSwitchSoon, isFalse);
    });

    test('placement correct on odd day with odd address', () {
      final status = service.status(addressNumber: 101);
      expect(status.isPlacementCorrect, isTrue);
    });

    test('placement incorrect on odd day with even address', () {
      final status = service.status(addressNumber: 200);
      expect(status.isPlacementCorrect, isFalse);
    });

    test('notification priorities map to types', () {
      final morning = service.buildNotification(
        type: NotificationType.morningReminder,
        addressNumber: 101,
      );
      final evening = service.buildNotification(
        type: NotificationType.eveningWarning,
        addressNumber: 101,
      );
      final midnight = service.buildNotification(
        type: NotificationType.midnightAlert,
        addressNumber: 101,
      );

      expect(morning.priority, NotificationPriority.low);
      expect(evening.priority, NotificationPriority.medium);
      expect(midnight.priority, NotificationPriority.high);
    });

    test('morning reminder mentions correct side', () {
      final msg = service.buildNotification(
        type: NotificationType.morningReminder,
        addressNumber: 101,
      );
      expect(msg.body.toLowerCase(), contains('odd-numbered side'));
    });

    test('month rollover handles March 31 to April 1', () {
      final march31 = DateTime(2024, 3, 31, 22, 0);
      service = AlternateSideParkingService(clock: () => march31);
      final next = service.nextSwitchTime(march31);
      expect(next, DateTime(2024, 4, 1));
      expect(service.sideForDate(next), ParkingSide.even);
    });

    test('leap year Feb 29 is treated as odd day', () {
      final leap = DateTime(2024, 2, 29, 10, 0);
      service = AlternateSideParkingService(clock: () => leap);
      expect(service.sideForDate(leap), ParkingSide.odd);
    });

    test('schedule marks tomorrow correctly', () {
      final schedule = service.schedule(days: 2);
      expect(schedule.first.isToday, isTrue);
      expect(schedule[1].isTomorrow, isTrue);
    });

    test('time until switch is computed from clock', () {
      final status = service.status(addressNumber: 101);
      expect(status.timeUntilSwitch.inHours, greaterThan(0));
      expect(status.nextSwitch, DateTime(2024, 3, 16));
    });
  });
}
