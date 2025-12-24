import 'package:flutter/material.dart';
import '../models/transaction.dart';
import '../services/transaction_service.dart';
import '../services/payment_service.dart';
import '../models/payment.dart';

class TransactionProvider with ChangeNotifier {
  final TransactionService _service = TransactionService();
  final PaymentService _paymentService = PaymentService();

  List<Transaction> _transactions = [];
  List<Transaction> get transactions => _transactions;

  List<Transaction> _allTransactions = [];
  List<Transaction> get allTransactions => _allTransactions;

  Future<void> fetchTransactions(String customerId, String userId) async {
    final docs = await _service.getTransactionsByCustomer(customerId, userId);
    _transactions = docs.map((doc) => Transaction.fromJson(doc.data)).toList();
    notifyListeners();
  }

  // Method untuk fetch semua transactions
  Future<void> fetchAllTransactions(String userId) async {
    try {
      final response = await _service.getAllTransactions(userId);

      _allTransactions = response.map((doc) => Transaction.fromJson(doc.data)).toList();
      notifyListeners();
    } catch (e) {
      print('Error fetching all transactions: $e');
      _allTransactions = [];
      notifyListeners();
    }
  }

  Future<void> addTransaction(Transaction trx) async {
    await _service.addTransaction(trx.toJson());
    await fetchTransactions(trx.customerId, trx.userId);
  }

  Future<void> updateTransaction(Transaction trx) async {
    await _service.updateTransaction(trx.id, trx.toJson());
    await fetchTransactions(trx.customerId, trx.userId);
  }

  Future<void> deleteTransaction(String id, String customerId, String userId) async {
    // Hapus semua payment terkait transaksi ini
    await _paymentService.deletePaymentsByTransaction(id, userId);
    // Hapus transaksi
    await _service.deleteTransaction(id);
    await fetchTransactions(customerId, userId);
  }

  Future<void> updateSisaDanStatus(String transactionId, String userId) async {
    final trxDoc = await _service.getTransactionById(transactionId);
    final trx = Transaction.fromJson(trxDoc.data);

    final payments = await _paymentService.getPaymentsByTransaction(transactionId, userId);
    final totalBayar = payments.fold<int>(0, (sum, doc) => sum + Payment.fromJson(doc.data).nominal);

    final sisa = trx.total - totalBayar;
    final status = sisa <= 0 ? 'lunas' : 'belumlunas';

    await _service.updateTransaction(transactionId, {
      'sisa': sisa,
      'status': status,
    });

    await fetchTransactions(trx.customerId, userId);
    notifyListeners();
  }

  void clear() {
    _transactions = [];
    _allTransactions = [];
    notifyListeners();
  }
}