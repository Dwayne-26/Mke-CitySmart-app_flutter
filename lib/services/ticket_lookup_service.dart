import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/ticket.dart';

class TicketLookupService {
  TicketLookupService({required this.baseUrl, this.authToken});

  final String baseUrl;
  final String? authToken;

  Map<String, String> _headers() {
    final headers = <String, String>{
      'Content-Type': 'application/json',
    };
    if (authToken != null && authToken!.isNotEmpty) {
      headers['Authorization'] = 'Bearer $authToken';
    }
    return headers;
  }

  Future<List<Ticket>> lookupTickets({
    required String plate,
    required String state,
  }) async {
    final uri = Uri.parse('$baseUrl/tickets')
        .replace(queryParameters: {'plate': plate, 'state': state});
    final resp = await http.get(uri, headers: _headers());
    if (resp.statusCode != 200) {
      throw Exception('Lookup failed: ${resp.statusCode}');
    }
    final data = jsonDecode(resp.body) as List<dynamic>;
    return data
        .map((json) => _ticketFromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<TicketPaymentResult> payTicket({
    required String ticketId,
    required double amount,
    required Map<String, dynamic> paymentMethod, // card/ach token or details
    String? feeWaiverCode,
    String? email,
  }) async {
    final uri = Uri.parse('$baseUrl/tickets/$ticketId/pay');
    final body = {
      'amount': amount,
      'payment': paymentMethod,
      if (feeWaiverCode != null) 'feeWaiverCode': feeWaiverCode,
      if (email != null) 'email': email,
    };
    final resp = await http.post(
      uri,
      headers: _headers(),
      body: jsonEncode(body),
    );
    if (resp.statusCode != 200) {
      throw Exception('Payment failed: ${resp.statusCode}');
    }
    final data = jsonDecode(resp.body) as Map<String, dynamic>;
    return TicketPaymentResult(
      receiptId: data['receiptId'] as String?,
      status: data['status'] as String? ?? 'unknown',
      paidAt: data['paidAt'] as String?,
      receiptUrl: data['receiptUrl'] as String?,
    );
  }

  Ticket _ticketFromJson(Map<String, dynamic> json) {
    return Ticket(
      id: json['id'] as String,
      status: _statusFromString(json['status'] as String? ?? 'open'),
      amount: (json['amount'] as num?)?.toDouble() ?? 0,
      currency: json['currency'] as String? ?? 'USD',
      dueDate: _parseDate(json['dueDate']),
      issueDate: _parseDate(json['issueDate']),
      violation: json['violation'] as String? ?? '',
      issuer: json['issuer'] as String? ?? '',
      location: json['location'] as String? ?? '',
      feeWaiverEligible: json['feeWaiverEligible'] as bool? ?? false,
      lateFees: (json['lateFees'] as num?)?.toDouble() ?? 0,
      paymentUrl: json['paymentUrl'] as String?,
    );
  }

  TicketStatus _statusFromString(String s) {
    switch (s.toLowerCase()) {
      case 'paid':
        return TicketStatus.paid;
      case 'void':
        return TicketStatus.voided;
      default:
        return TicketStatus.open;
    }
  }

  DateTime _parseDate(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is int) {
      // assume millis
      return DateTime.fromMillisecondsSinceEpoch(value);
    }
    if (value is String) {
      return DateTime.tryParse(value) ?? DateTime.now();
    }
    return DateTime.now();
  }
}

class TicketPaymentResult {
  TicketPaymentResult({
    required this.receiptId,
    required this.status,
    required this.paidAt,
    required this.receiptUrl,
  });

  final String? receiptId;
  final String status;
  final String? paidAt;
  final String? receiptUrl;
}
