import 'package:flutter/material.dart';
import '../models/customer.dart';
import '../services/appwrite_service.dart';

class CustomerProvider with ChangeNotifier {
  final AppwriteService _service = AppwriteService();
  List<Customer> _customers = [];

  List<Customer> get customers => _customers;

  Future<void> fetchCustomers() async {
    final data = await _service.getCustomers();
    _customers = data.map((json) => Customer.fromJson(json)).toList();
    notifyListeners();
  }

  Future<void> addCustomer(Customer customer) async {
    await _service.addCustomer(customer.toJson());
    await fetchCustomers(); // refresh data setelah tambah
  }

  Future<void> updateCustomer(Customer customer) async {
    await _service.updateCustomer(customer.id, customer.toJson());
    await fetchCustomers();
  }

  Future<void> deleteCustomer(String id) async {
    await _service.deleteCustomer(id);
    await fetchCustomers();
  }
}