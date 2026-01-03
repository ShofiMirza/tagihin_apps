import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class MidtransService {
  // IMPORTANT: Do NOT put Midtrans server key in the client.
  // This client calls your secure Appwrite Function or backend API.

  final String _createTxnUrl = dotenv.env['MIDTRANS_CREATE_TXN_URL'] ?? '';
  final String _projectId = dotenv.env['APPWRITE_PROJECT_ID'] ?? '';

  Future<({String token, String redirectUrl, String orderId})> createPremiumTransaction({
    required String userId,
    required String email,
  }) async {
    if (_createTxnUrl.isEmpty) {
      throw Exception('MIDTRANS_CREATE_TXN_URL is not configured in .env');
    }

    if (_projectId.isEmpty) {
      throw Exception('APPWRITE_PROJECT_ID is not configured in .env');
    }

    final body = jsonEncode({
      'userId': userId,
      'email': email,
      'itemId': 'premium-1month',
      'amount': 14000,
    });

    try {
      debugPrint('Calling Midtrans function: $_createTxnUrl');
      debugPrint('Request body: $body');
      debugPrint('Project ID: $_projectId');

      final res = await http.post(
        Uri.parse(_createTxnUrl),
        headers: {
          'Content-Type': 'application/json',
          'X-Appwrite-Project': _projectId,
        },
        body: jsonEncode({
          'body': body, // Appwrite Function expects 'body' parameter as string
          'async': false,
        }),
      );

      debugPrint('Response status: ${res.statusCode}');
      debugPrint('Response body: ${res.body}');

      if (res.statusCode < 200 || res.statusCode >= 300) {
        throw Exception('HTTP ${res.statusCode}: ${res.body}');
      }

      final data = jsonDecode(res.body) as Map<String, dynamic>;
      
      // Handle Appwrite function response format
      if (data.containsKey('responseBody')) {
        final responseBody = jsonDecode(data['responseBody'] as String) as Map<String, dynamic>;
        
        if (responseBody.containsKey('error')) {
          throw Exception(responseBody['error']);
        }
        
        return (
          token: responseBody['token'] as String,
          redirectUrl: responseBody['redirect_url'] as String,
          orderId: responseBody['order_id'] as String,
        );
      }
      
      // Direct response format
      if (data.containsKey('error')) {
        throw Exception(data['error']);
      }
      
      return (
        token: data['token'] as String,
        redirectUrl: data['redirect_url'] as String,
        orderId: data['order_id'] as String,
      );
    } catch (e) {
      debugPrint('Midtrans create txn error: $e');
      throw Exception('Gagal membuat transaksi Midtrans: $e');
    }
  }
}
