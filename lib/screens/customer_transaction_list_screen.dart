import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tagihin_apps/providers/transaction_provider.dart';
import '../providers/payment_provider.dart';
import '../providers/auth_provider.dart';
import 'transaction_detail_screen.dart';
import 'add_transaction_screen.dart';

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
    return Scaffold(
      appBar: AppBar(title: Text('Transaksi')),
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
                        return ListTile(
                          title: Text(t.deskripsi),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Tanggal: ${t.tanggal.toLocal()}'),
                              Text('Total: ${t.total}'),
                              Text('Sisa: ${t.sisa}'),
                              Text('Status: ${t.status}'),
                            ],
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
}