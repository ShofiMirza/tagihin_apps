import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import '../models/payment.dart';
import '../services/payment_service.dart';
import '../providers/transaction_provider.dart';

class PaymentProvider with ChangeNotifier {
  final PaymentService _service = PaymentService();
  List<Payment> _payments = [];
  List<Payment> _allPayments = [];

  List<Payment> get payments => _payments;
  List<Payment> get allPayments => _allPayments;

  Future<void> fetchPayments(String transactionId) async {
    final docs = await _service.getPaymentsByTransaction(transactionId);
    _payments = docs.map((doc) => Payment.fromJson(doc.data)).toList();
    notifyListeners();
  }

  Future<void> addPayment(Payment payment, BuildContext context) async {
    await _service.addPayment(payment.toJson());
    await fetchPayments(payment.transactionId);

    // Tambahkan baris ini:
    await Provider.of<TransactionProvider>(context, listen: false)
        .updateSisaDanStatus(payment.transactionId);

    notifyListeners();
  }

  Future<void> updatePayment(Payment payment) async {
    await _service.updatePayment(payment.id, payment.toJson());
    await fetchPayments(payment.transactionId);
  }

  Future<void> deletePayment(String id, String transactionId) async {
    await _service.deletePayment(id);
    await fetchPayments(transactionId);
  }

  // Method untuk fetch semua payments
  Future<void> fetchAllPayments() async {
    try {
      // Gunakan PaymentService yang sudah ada
      final docs = await _service.getAllPayments();
      _allPayments = docs.map((doc) => Payment.fromJson(doc.data)).toList();
      notifyListeners();
    } catch (e) {
      print('Error fetching all payments: $e');
      _allPayments = [];
      notifyListeners();
    }
  }
}