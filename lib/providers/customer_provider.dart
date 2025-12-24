import 'package:flutter/material.dart';
import '../models/customer.dart';
import '../services/appwrite_service.dart';

class CustomerProvider with ChangeNotifier {
  final AppwriteService _service = AppwriteService();
  List<Customer> _customers = [];

  List<Customer> get customers => _customers;

  Future<void> fetchCustomers(String userId) async {
    final data = await _service.getCustomers(userId);
    _customers = data.map((json) => Customer.fromJson(json)).toList();
    notifyListeners();
  }

  Future<void> addCustomer(Customer customer, String userId) async {
    await _service.addCustomer(customer.toJson());
    await fetchCustomers(userId); // refresh data setelah tambah
  }

  Future<void> updateCustomer(Customer customer, String userId) async {
    await _service.updateCustomer(customer.id, customer.toJson());
    await fetchCustomers(userId);
  }

  Future<void> deleteCustomer(String id, String userId) async {
    await _service.deleteCustomer(id);
    await fetchCustomers(userId);
  }

  void clear() {
    _customers = [];
    notifyListeners();
  }
}