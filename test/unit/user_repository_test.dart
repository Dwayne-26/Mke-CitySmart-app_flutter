import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mkeparkapp_flutter/models/user_profile.dart';
import 'package:mkeparkapp_flutter/models/ticket.dart';
import 'package:mkeparkapp_flutter/models/payment_receipt.dart';
import 'package:mkeparkapp_flutter/models/sighting_report.dart';
import 'package:mkeparkapp_flutter/models/maintenance_report.dart';
import 'package:mkeparkapp_flutter/services/user_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('UserRepository', () {
    test('saves and loads profile scoped by user id', () async {
      final repo = await UserRepository.create();

      await repo.setActiveUser('user1');
      final profile1 = UserProfile(id: 'user1', name: 'Alice', email: 'a@x.com');
      await repo.saveProfile(profile1);

      await repo.setActiveUser('user2');
      final profile2 = UserProfile(id: 'user2', name: 'Bob', email: 'b@x.com');
      await repo.saveProfile(profile2);

      await repo.setActiveUser('user1');
      final loaded1 = await repo.loadProfile();
      expect(loaded1?.name, 'Alice');

      await repo.setActiveUser('user2');
      final loaded2 = await repo.loadProfile();
      expect(loaded2?.name, 'Bob');
    });

    test('clears active user and scoped data', () async {
      final repo = await UserRepository.create();
      await repo.setActiveUser('user1');
      final profile = UserProfile(id: 'user1', name: 'Test', email: 't@x.com');
      await repo.saveProfile(profile);

      await repo.clearProfile();
      final loaded = await repo.loadProfile();
      expect(loaded, isNull);

      await repo.setActiveUser(null);
      expect(repo.activeUserId, isNull);
    });

    test('persists scoped domain data (tickets, receipts, sightings)', () async {
      final repo = await UserRepository.create();
      await repo.setActiveUser('user1');

      final tickets = [
        Ticket(
          id: 't1',
          plate: 'ABC',
          amount: 50,
          reason: 'Test',
          location: 'Loc',
          issuedAt: DateTime(2024, 1, 1),
          dueDate: DateTime(2024, 2, 1),
        ),
      ];
      final receipts = [
        PaymentReceipt(
          id: 'r1',
          amountCharged: 10,
          method: 'card',
          reference: 'ref1',
          createdAt: DateTime(2024, 3, 1),
        ),
      ];
      final sightings = [
        SightingReport(
          id: 's1',
          type: SightingType.parkingEnforcer,
          location: 'Main',
          notes: 'note',
          reportedAt: DateTime(2024, 4, 1),
        ),
      ];

      await repo.saveTickets(tickets);
      await repo.saveReceipts(receipts);
      await repo.saveSightings(sightings);

      expect((await repo.loadTickets()).single.id, 't1');
      expect((await repo.loadReceipts()).single.id, 'r1');
      expect((await repo.loadSightings()).single.id, 's1');

      final reports = [
        MaintenanceReport(
          id: 'm1',
          category: MaintenanceCategory.pothole,
          description: 'desc',
          location: 'loc',
          createdAt: DateTime(2024, 5, 1),
        ),
      ];
      await repo.saveMaintenanceReports(reports);
      expect((await repo.loadMaintenanceReports()).single.id, 'm1');
    });
  });
}
