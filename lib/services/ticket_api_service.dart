import 'dart:async';

import '../data/sample_tickets.dart';
import '../models/ticket.dart';

/// Mock backend service. Replace with real HTTP client when API is available.
class TicketApiService {
  Future<List<Ticket>> fetchTickets() async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
    return List<Ticket>.from(sampleTickets);
  }

  Future<void> syncTickets(List<Ticket> tickets) async {
    await Future<void>.delayed(const Duration(milliseconds: 150));
    // noop for mock; wire to POST/PUT in real implementation
  }
}
