import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/customer.dart';
import '../providers/customer_provider.dart';

class AddCustomerScreen extends StatefulWidget {
  final Customer? editCustomer;
  const AddCustomerScreen({super.key, this.editCustomer});

  @override
  State<AddCustomerScreen> createState() => _AddCustomerScreenState();
}

class _AddCustomerScreenState extends State<AddCustomerScreen> {
  final _formKey = GlobalKey<FormState>();
  final _namaController = TextEditingController();
  final _noHpController = TextEditingController();
  final _alamatController = TextEditingController();
  final _catatanController = TextEditingController();
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    if (widget.editCustomer != null) {
      _namaController.text = widget.editCustomer!.nama;
      _noHpController.text = widget.editCustomer!.noHp.toString();
      _alamatController.text = widget.editCustomer!.alamat ?? '';
      _catatanController.text = widget.editCustomer!.catatan ?? '';
    }
  }

  @override
  void dispose() {
    _namaController.dispose();
    _noHpController.dispose();
    _alamatController.dispose();
    _catatanController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _loading = true);

      final customer = Customer(
        id: widget.editCustomer?.id ?? '',
        nama: _namaController.text,
        noHp: _noHpController.text,
        alamat: _alamatController.text,
        catatan: _catatanController.text,
      );
      
      if (widget.editCustomer != null) {
        await Provider.of<CustomerProvider>(context, listen: false).updateCustomer(customer);
      } else {
        await Provider.of<CustomerProvider>(context, listen: false).addCustomer(customer);
      }

      setState(() => _loading = false);
      if (!mounted) return;
      Navigator.pop(context, true); // Return true = ada perubahan data
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tambah Pelanggan')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _namaController,
                decoration: const InputDecoration(labelText: 'Nama'),
                validator: (value) => value == null || value.isEmpty ? 'Nama wajib diisi' : null,
              ),
              TextFormField(
                controller: _noHpController,
                keyboardType: TextInputType.phone, // <-- ini yang penting
                decoration: const InputDecoration(
                  labelText: 'Nomor HP',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Nomor HP wajib diisi';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _alamatController,
                decoration: const InputDecoration(labelText: 'Alamat (opsional)'),
              ),
              TextFormField(
                controller: _catatanController,
                decoration: const InputDecoration(labelText: 'Catatan (opsional)'),
              ),
              const SizedBox(height: 24),
              _loading
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton(
                      onPressed: _submit,
                      child: const Text('Simpan'),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}