import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/payment.dart';
import '../models/transaction.dart';
import '../providers/payment_provider.dart';
import '../providers/auth_provider.dart';

class AddPaymentScreen extends StatefulWidget {
  final Transaction transaction;
  final Payment? editPayment;
  const AddPaymentScreen({super.key, required this.transaction, this.editPayment});

  @override
  State<AddPaymentScreen> createState() => _AddPaymentScreenState();
}

class _AddPaymentScreenState extends State<AddPaymentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nominalController = TextEditingController();
  String _metode = 'Cash';
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    if (widget.editPayment != null) {
      _nominalController.text = widget.editPayment!.nominal.toString();
      _metode = widget.editPayment!.metode;
    }
  }

  @override
  void dispose() {
    _nominalController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_formKey.currentState!.validate()) {
      final userId = Provider.of<AuthProvider>(context, listen: false).userId;
      if (userId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error: User tidak terautentikasi')),
        );
        return;
      }

      final nominal = int.tryParse(_nominalController.text) ?? 0;
      
      // Validasi: nominal tidak boleh melebihi sisa utang (kecuali saat edit)
      if (widget.editPayment == null && nominal > widget.transaction.sisa) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Nominal pembayaran (Rp ${_formatNumber(nominal)}) '
              'melebihi sisa utang (Rp ${_formatNumber(widget.transaction.sisa)})'
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
        return;
      }

      final payment = Payment(
        id: widget.editPayment?.id ?? '',
        userId: widget.editPayment?.userId ?? userId,
        transactionId: widget.transaction.id,
        tanggalPay: widget.editPayment?.tanggalPay ?? DateTime.now(),
        nominal: nominal,
        metode: _metode,
      );
      if (widget.editPayment != null) {
        await Provider.of<PaymentProvider>(context, listen: false).updatePayment(payment, userId);
      } else {
        await Provider.of<PaymentProvider>(context, listen: false)
            .addPayment(payment, context, userId);
      }
      Navigator.pop(context);
    }
  }

  String _formatNumber(int number) {
    return number.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]}.',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tambah Pembayaran')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _nominalController,
                decoration: const InputDecoration(labelText: 'Nominal'),
                keyboardType: TextInputType.number,
                validator: (v) => v == null || v.isEmpty ? 'Wajib diisi' : null,
              ),
              DropdownButtonFormField<String>(
                value: _metode,
                items: const [
                  DropdownMenuItem(value: 'Cash', child: Text('Cash')),
                  DropdownMenuItem(value: 'Transfer', child: Text('Transfer')),
                ],
                onChanged: (v) => setState(() => _metode = v ?? 'cash'),
                decoration: const InputDecoration(labelText: 'Metode Pembayaran'),
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