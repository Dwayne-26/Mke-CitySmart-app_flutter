import 'package:flutter_test/flutter_test.dart';
import 'package:mkecitysmart/services/alternate_side_parking_service.dart';

void main() {
  group('AlternateSideParkingService', () {
    late AlternateSideParkingService service;

    setUp(() {
      service = AlternateSideParkingService.instance;
    });

    test('identifies odd days correctly', () {
      // Test odd days
      final jan1 = DateTime(2025, 1, 1); // Day 1 (odd)
      final jan3 = DateTime(2025, 1, 3); // Day 3 (odd)
      final jan15 = DateTime(2025, 1, 15); // Day 15 (odd)
      final jan31 = DateTime(2025, 1, 31); // Day 31 (odd)

      expect(service.getParkingInstructions(jan1).isOddDay, true);
      expect(service.getParkingInstructions(jan3).isOddDay, true);
      expect(service.getParkingInstructions(jan15).isOddDay, true);
      expect(service.getParkingInstructions(jan31).isOddDay, true);

      expect(service.getParkingInstructions(jan1).parkingSide, ParkingSide.odd);
      expect(service.getParkingInstructions(jan3).parkingSide, ParkingSide.odd);
    });

    test('identifies even days correctly', () {
      // Test even days
      final jan2 = DateTime(2025, 1, 2); // Day 2 (even)
      final jan4 = DateTime(2025, 1, 4); // Day 4 (even)
      final jan16 = DateTime(2025, 1, 16); // Day 16 (even)
      final jan30 = DateTime(2025, 1, 30); // Day 30 (even)

      expect(service.getParkingInstructions(jan2).isOddDay, false);
      expect(service.getParkingInstructions(jan4).isOddDay, false);
      expect(service.getParkingInstructions(jan16).isOddDay, false);
      expect(service.getParkingInstructions(jan30).isOddDay, false);

      expect(
        service.getParkingInstructions(jan2).parkingSide,
        ParkingSide.even,
      );
      expect(
        service.getParkingInstructions(jan4).parkingSide,
        ParkingSide.even,
      );
    });

    test('generates correct side labels', () {
      final jan1 = DateTime(2025, 1, 1); // Odd
      final jan2 = DateTime(2025, 1, 2); // Even

      final oddInstructions = service.getParkingInstructions(jan1);
      final evenInstructions = service.getParkingInstructions(jan2);

      expect(oddInstructions.sideLabel, 'Odd');
      expect(oddInstructions.sideExamples, '1, 3, 5, 7, 9...');

      expect(evenInstructions.sideLabel, 'Even');
      expect(evenInstructions.sideExamples, '2, 4, 6, 8, 10...');
    });

    test('calculates next switch date correctly', () {
      final jan15at3pm = DateTime(2025, 1, 15, 15, 30); // 3:30 PM on Jan 15
      final instructions = service.getParkingInstructions(jan15at3pm);

      // Next switch should be Jan 16 at midnight
      expect(instructions.nextSwitchDate.year, 2025);
      expect(instructions.nextSwitchDate.month, 1);
      expect(instructions.nextSwitchDate.day, 16);
      expect(instructions.nextSwitchDate.hour, 0);
      expect(instructions.nextSwitchDate.minute, 0);
      expect(instructions.nextSwitchDate.second, 0);
    });

    test('detects if parking side will change tomorrow', () {
      // This test depends on current date, so we test the logic indirectly
      final today = service.getTodayInstructions();
      final tomorrow = service.getTomorrowInstructions();

      // Side should always change between today and tomorrow
      expect(today.parkingSide != tomorrow.parkingSide, true);
      expect(service.willSideChangeTomorrow(), true);
    });

    test('generates upcoming instructions correctly', () {
      final upcoming = service.getUpcomingInstructions(7);

      expect(upcoming.length, 7);

      // Each consecutive day should alternate sides
      for (int i = 0; i < upcoming.length - 1; i++) {
        final current = upcoming[i];
        final next = upcoming[i + 1];

        // Day numbers should increment
        expect(
          next.dayOfMonth - current.dayOfMonth,
          isIn([1, -27, -28, -29, -30, -31]),
        ); // Account for month rollover

        // Sides should match day parity
        expect(current.isOddDay, current.dayOfMonth % 2 == 1);
        expect(next.isOddDay, next.dayOfMonth % 2 == 1);
      }
    });

    test('validates vehicle parking on correct side', () {
      final jan1 = DateTime(2025, 1, 1); // Odd day
      final jan2 = DateTime(2025, 1, 2); // Even day

      // On odd day, odd side is correct
      expect(service.isCorrectSide(ParkingSide.odd, forDate: jan1), true);
      expect(service.isCorrectSide(ParkingSide.even, forDate: jan1), false);

      // On even day, even side is correct
      expect(service.isCorrectSide(ParkingSide.even, forDate: jan2), true);
      expect(service.isCorrectSide(ParkingSide.odd, forDate: jan2), false);
    });

    test('generates appropriate notification messages', () {
      final jan1 = DateTime(2025, 1, 1); // Odd day

      final morningMsg = service.getNotificationMessage(
        type: NotificationType.morningReminder,
        forDate: jan1,
      );
      expect(morningMsg.title, contains('Parking Reminder'));
      expect(morningMsg.body, contains('odd'));
      expect(morningMsg.priority, NotificationPriority.normal);

      final eveningMsg = service.getNotificationMessage(
        type: NotificationType.eveningWarning,
        forDate: jan1,
      );
      expect(eveningMsg.title, contains('Changes Tonight'));
      expect(eveningMsg.body, contains('Move your car'));
      expect(eveningMsg.priority, NotificationPriority.high);

      final midnightMsg = service.getNotificationMessage(
        type: NotificationType.midnightAlert,
        forDate: jan1,
      );
      expect(midnightMsg.title, contains('Switch'));
      expect(midnightMsg.priority, NotificationPriority.urgent);
    });

    test('formats parking reminders correctly', () {
      final jan1 = DateTime(2025, 1, 1); // Odd day
      final jan2 = DateTime(2025, 1, 2); // Even day

      final oddReminder = service.getParkingReminder(forDate: jan1);
      expect(oddReminder, contains('odd-numbered side'));
      expect(oddReminder, contains('1'));

      final evenReminder = service.getParkingReminder(forDate: jan2);
      expect(evenReminder, contains('even-numbered side'));
      expect(evenReminder, contains('2'));
    });

    test('JSON serialization works correctly', () {
      final jan15 = DateTime(2025, 1, 15, 10, 30);
      final instructions = service.getParkingInstructions(jan15);

      final json = instructions.toJson();
      expect(json['dayOfMonth'], 15);
      expect(json['isOddDay'], true);
      expect(json['parkingSide'], 'odd');

      final restored = ParkingInstructions.fromJson(json);
      expect(restored.dayOfMonth, instructions.dayOfMonth);
      expect(restored.isOddDay, instructions.isOddDay);
      expect(restored.parkingSide, instructions.parkingSide);
    });

    test('handles month transitions correctly', () {
      // Test end of month to beginning of next month
      final jan31 = DateTime(2025, 1, 31); // Day 31 (odd)
      final feb1 = DateTime(2025, 2, 1); // Day 1 (odd)

      final jan31Instructions = service.getParkingInstructions(jan31);
      final feb1Instructions = service.getParkingInstructions(feb1);

      expect(jan31Instructions.isOddDay, true);
      expect(feb1Instructions.isOddDay, true);

      // Both are odd, so same side
      expect(jan31Instructions.parkingSide, feb1Instructions.parkingSide);
    });

    test('handles February 28/29 transitions', () {
      // Leap year 2024
      final feb29_2024 = DateTime(2024, 2, 29); // Day 29 (odd)
      final mar1_2024 = DateTime(2024, 3, 1); // Day 1 (odd)

      expect(service.getParkingInstructions(feb29_2024).isOddDay, true);
      expect(service.getParkingInstructions(mar1_2024).isOddDay, true);

      // Non-leap year 2025
      final feb28_2025 = DateTime(2025, 2, 28); // Day 28 (even)
      final mar1_2025 = DateTime(2025, 3, 1); // Day 1 (odd)

      expect(service.getParkingInstructions(feb28_2025).isOddDay, false);
      expect(service.getParkingInstructions(mar1_2025).isOddDay, true);
    });
  });
}
