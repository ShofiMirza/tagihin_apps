import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tagihin_apps/providers/transaction_provider.dart';
import '../providers/payment_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/customer_provider.dart';
import 'transaction_detail_screen.dart';
import 'add_transaction_screen.dart';
import 'bulk_payment_screen.dart';
import 'wa_reminder_screen.dart';

class CustomerTransactionListScreen extends StatefulWidget {
  final String customerId;
  final String customerName;
  const CustomerTransactionListScreen({
    super.key,
    required this.customerId,
    required this.customerName,
  });

  @override
  State<CustomerTransactionListScreen> createState() => _CustomerTransactionListScreenState();
}

class _CustomerTransactionListScreenState extends State<CustomerTransactionListScreen> {
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    if (!mounted) return;
    setState(() => _loading = true);
    final userId = Provider.of<AuthProvider>(context, listen: false).userId;
    if (userId != null) {
      await Provider.of<TransactionProvider>(context, listen: false)
          .fetchTransactions(widget.customerId, userId);
    }
    if (mounted) {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final transactions = Provider.of<TransactionProvider>(context).transactions;
    final unpaidCount = transactions.where((t) => t.status.toLowerCase() != 'lunas').length;
    
    return Scaffold(
      appBar: AppBar(
        title: Text('Transaksi'),
        actions: [
          if (unpaidCount > 1)
            IconButton(
              icon: Stack(
                children: [
                  const Icon(Icons.payments),
                  if (unpaidCount > 0)
                    Positioned(
                      right: 0,
                      top: 0,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 16,
                          minHeight: 16,
                        ),
                        child: Text(
                          '$unpaidCount',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              ),
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => BulkPaymentScreen(
                      transactions: transactions,
                      customerId: widget.customerId,
                    ),
                  ),
                );
                if (result == true) {
                  await _refresh();
                }
              },
              tooltip: 'Bayar Multiple Nota',
            ),
          if (unpaidCount > 0)
            IconButton(
              icon: Stack(
                children: [
                  const Icon(Icons.message),
                  if (unpaidCount > 0)
                    Positioned(
                      right: 0,
                      top: 0,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: Colors.green,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 16,
                          minHeight: 16,
                        ),
                        child: Text(
                          '$unpaidCount',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              ),
              onPressed: () async {
                // Dapatkan data customer
                final customerProvider = Provider.of<CustomerProvider>(context, listen: false);
                final customer = customerProvider.customers.firstWhere(
                  (c) => c.id == widget.customerId,
                  orElse: () => throw Exception('Customer not found'),
                );

                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => WaReminderScreen(
                      transactions: transactions,
                      customer: customer,
                    ),
                  ),
                );
              },
              tooltip: 'Kirim Pengingat WA',
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _refresh,
              child: transactions.isEmpty
                  ? const Center(child: Text('Belum ada transaksi'))
                  : ListView.builder(
                      itemCount: transactions.length,
                      itemBuilder: (context, index) {
                        final t = transactions[index];
                        final isLunas = t.status.toLowerCase() == 'lunas';
                        final statusColor = isLunas ? Colors.green : Colors.red;
                        
                        return Container(
                          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border(
                              left: BorderSide(color: statusColor, width: 4),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.withOpacity(0.1),
                                spreadRadius: 1,
                                blurRadius: 3,
                                offset: const Offset(0, 1),
                              ),
                            ],
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            title: Text(
                              t.deskripsi,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                              ),
                            ),
                            subtitle: Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(Icons.calendar_today, size: 14, color: Colors.grey.shade600),
                                      const SizedBox(width: 4),
                                      Text(
                                        '${t.tanggal.day}/${t.tanggal.month}/${t.tanggal.year}',
                                        style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          'Total: Rp ${_formatNumber(t.total)}',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w500,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: statusColor.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Text(
                                          isLunas ? 'LUNAS' : 'Sisa: Rp ${_formatNumber(t.sisa)}',
                                          style: TextStyle(
                                            color: statusColor,
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            trailing: PopupMenuButton<String>(
                            onSelected: (value) async {
                              if (value == 'edit') {
                                await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => AddTransactionScreen(
                                      customerId: widget.customerId,
                                      editTransaction: t,
                                    ),
                                  ),
                                );
                                // Setelah edit, fetch ulang transaksi
                                final userId = Provider.of<AuthProvider>(context, listen: false).userId;
                                if (userId != null) {
                                  await Provider.of<TransactionProvider>(context, listen: false)
                                      .fetchTransactions(widget.customerId, userId);
                                }
                                setState(() {});
                              } else if (value == 'delete') {
                                final confirm = await showDialog(
                                  context: context,
                                  builder: (ctx) => AlertDialog(
                                    title: const Text('Hapus Transaksi?'),
                                    content: const Text('Data akan dihapus permanen.'),
                                    actions: [
                                      TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
                                      TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Hapus')),
                                    ],
                                  ),
                                );
                                if (confirm == true) {
                                  final userId = Provider.of<AuthProvider>(context, listen: false).userId;
                                  if (userId != null) {
                                    await Provider.of<TransactionProvider>(context, listen: false)
                                        .deleteTransaction(t.id, widget.customerId, userId);
                                  }
                                  setState(() {});
                                }
                              }
                            },
                            itemBuilder: (context) => [
                              const PopupMenuItem(value: 'edit', child: Text('Edit')),
                              const PopupMenuItem(value: 'delete', child: Text('Hapus')),
                            ],
                          ),
                            onTap: () async {
                              // Ambil pembayaran dari PaymentProvider
                              final userId = Provider.of<AuthProvider>(context, listen: false).userId;
                              if (userId != null) {
                                await Provider.of<PaymentProvider>(context, listen: false)
                                    .fetchPayments(t.id, userId);
                              }
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => TransactionDetailScreen(
                                    transaction: t,
                                  ),
                                ),
                              );
                            },
                          ),
                        );
                      },
                    ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AddTransactionScreen(customerId: widget.customerId),
            ),
          );
          if (result == true) {
            await _refresh();
            // Jika ada perubahan transaksi, beri tahu parent
            if (mounted) Navigator.pop(context, true);
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  String _formatNumber(int number) {
    return number.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]}.',
    );
  }
}