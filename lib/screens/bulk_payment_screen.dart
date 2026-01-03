import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/transaction.dart';
import '../models/payment.dart';
import '../providers/payment_provider.dart';
import '../providers/auth_provider.dart';

class BulkPaymentScreen extends StatefulWidget {
  final List<Transaction> transactions;
  final String customerId;

  const BulkPaymentScreen({
    super.key,
    required this.transactions,
    required this.customerId,
  });

  @override
  State<BulkPaymentScreen> createState() => _BulkPaymentScreenState();
}

class _BulkPaymentScreenState extends State<BulkPaymentScreen> {
  final Map<String, bool> _selectedTransactions = {};
  final Map<String, TextEditingController> _controllers = {};
  final _formKey = GlobalKey<FormState>();
  String _metode = 'Cash';
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    // Initialize controllers dan selection untuk transaksi belum lunas
    for (var t in widget.transactions) {
      if (t.status.toLowerCase() != 'lunas') {
        _selectedTransactions[t.id] = false;
        _controllers[t.id] = TextEditingController();
      }
    }
  }

  @override
  void dispose() {
    for (var controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void _selectAll() {
    setState(() {
      for (var key in _selectedTransactions.keys) {
        _selectedTransactions[key] = true;
        // Auto fill dengan nilai sisa
        final transaction = widget.transactions.firstWhere((t) => t.id == key);
        _controllers[key]!.text = transaction.sisa.toString();
      }
    });
  }

  void _deselectAll() {
    setState(() {
      for (var key in _selectedTransactions.keys) {
        _selectedTransactions[key] = false;
        _controllers[key]!.clear();
      }
    });
  }

  int _getTotalPayment() {
    int total = 0;
    _selectedTransactions.forEach((transactionId, isSelected) {
      if (isSelected) {
        final amount = int.tryParse(_controllers[transactionId]!.text) ?? 0;
        total += amount;
      }
    });
    return total;
  }

  Future<void> _processPayments() async {
    if (!_formKey.currentState!.validate()) return;

    final selectedCount = _selectedTransactions.values.where((v) => v).length;
    if (selectedCount == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih minimal 1 nota untuk dibayar')),
      );
      return;
    }

    // Konfirmasi
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Konfirmasi Pembayaran'),
        content: Text(
          'Proses pembayaran untuk $selectedCount nota?\n'
          'Total: Rp ${_formatNumber(_getTotalPayment())}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Proses'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isProcessing = true);

    final userId = Provider.of<AuthProvider>(context, listen: false).userId;
    if (userId == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error: User tidak terautentikasi')),
        );
      }
      setState(() => _isProcessing = false);
      return;
    }

    final paymentProvider = Provider.of<PaymentProvider>(context, listen: false);
    int successCount = 0;
    int failCount = 0;

    // Process each selected transaction
    for (var entry in _selectedTransactions.entries) {
      if (entry.value) {
        final transactionId = entry.key;
        final nominal = int.tryParse(_controllers[transactionId]!.text) ?? 0;

        if (nominal > 0) {
          try {
            final payment = Payment(
              id: '',
              userId: userId,
              transactionId: transactionId,
              tanggalPay: DateTime.now(),
              nominal: nominal,
              metode: _metode,
            );

            await paymentProvider.addPayment(payment, context, userId);
            successCount++;
          } catch (e) {
            failCount++;
          }
        }
      }
    }

    setState(() => _isProcessing = false);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Berhasil: $successCount pembayaran' +
                (failCount > 0 ? ', Gagal: $failCount' : ''),
          ),
          backgroundColor: failCount > 0 ? Colors.orange : Colors.green,
        ),
      );

      if (successCount > 0) {
        Navigator.pop(context, true); // Return true to refresh parent
      }
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
    final unpaidTransactions = widget.transactions
        .where((t) => t.status.toLowerCase() != 'lunas')
        .toList();

    if (unpaidTransactions.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Pembayaran Multiple')),
        body: const Center(
          child: Text('Semua transaksi sudah lunas'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pembayaran Multiple'),
        actions: [
          TextButton(
            onPressed: _selectAll,
            child: const Text(
              'Pilih Semua',
              style: TextStyle(color: Colors.white),
            ),
          ),
          TextButton(
            onPressed: _deselectAll,
            child: const Text(
              'Batal',
              style: TextStyle(color: Colors.white70),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Summary Card
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.blue.shade700, Colors.blue.shade500],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Total Pembayaran:',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      'Rp ${_formatNumber(_getTotalPayment())}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${_selectedTransactions.values.where((v) => v).length} nota dipilih',
                      style: const TextStyle(color: Colors.white70),
                    ),
                    DropdownButton<String>(
                      value: _metode,
                      dropdownColor: Colors.blue.shade700,
                      style: const TextStyle(color: Colors.white),
                      underline: Container(),
                      items: ['Cash', 'Transfer', 'E-Wallet']
                          .map((m) => DropdownMenuItem(value: m, child: Text(m)))
                          .toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => _metode = value);
                        }
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Transaction List
          Expanded(
            child: Form(
              key: _formKey,
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: unpaidTransactions.length,
                itemBuilder: (context, index) {
                  final t = unpaidTransactions[index];
                  final isSelected = _selectedTransactions[t.id] ?? false;

                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.blue.shade50 : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected ? Colors.blue : Colors.grey.shade300,
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: CheckboxListTile(
                      value: isSelected,
                      onChanged: (value) {
                        setState(() {
                          _selectedTransactions[t.id] = value ?? false;
                          if (value == true && _controllers[t.id]!.text.isEmpty) {
                            // Auto fill dengan sisa
                            _controllers[t.id]!.text = t.sisa.toString();
                          }
                        });
                      },
                      title: Text(
                        t.deskripsi,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 4),
                          Text('Tanggal: ${t.tanggal.day}/${t.tanggal.month}/${t.tanggal.year}'),
                          Text('Sisa: Rp ${_formatNumber(t.sisa)}'),
                          if (isSelected) ...[
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: _controllers[t.id],
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                labelText: 'Nominal Bayar',
                                prefixText: 'Rp ',
                                border: const OutlineInputBorder(),
                                filled: true,
                                fillColor: Colors.white,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Masukkan nominal';
                                }
                                final nominal = int.tryParse(value);
                                if (nominal == null || nominal <= 0) {
                                  return 'Nominal tidak valid';
                                }
                                if (nominal > t.sisa) {
                                  return 'Melebihi sisa utang (${_formatNumber(t.sisa)})';
                                }
                                return null;
                              },
                              onChanged: (_) => setState(() {}),
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),

          // Action Button
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _isProcessing ? null : _processPayments,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue.shade700,
                ),
                child: _isProcessing
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        'Proses Pembayaran',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
