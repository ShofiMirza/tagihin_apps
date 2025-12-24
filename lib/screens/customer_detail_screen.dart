import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/customer.dart';
import '../providers/customer_provider.dart';
import '../providers/auth_provider.dart';
import 'add_customer_screen.dart';
import 'customer_transaction_list_screen.dart';

class CustomerDetailScreen extends StatelessWidget {
  final Customer customer;
  const CustomerDetailScreen({super.key, required this.customer});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(customer.nama),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AddCustomerScreen(editCustomer: customer),
                ),
              );
              Navigator.pop(context); // kembali setelah edit
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () async {
              final confirm = await showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Hapus Pelanggan?'),
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
                  await Provider.of<CustomerProvider>(context, listen: false).deleteCustomer(customer.id, userId);
                  Navigator.pop(context); // kembali setelah hapus
                }
              }
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('No. HP: ${customer.noHp}'),
            if (customer.alamat != null && customer.alamat!.isNotEmpty)
              Text('Alamat: ${customer.alamat}'),
            if (customer.catatan != null && customer.catatan!.isNotEmpty)
              Text('Catatan: ${customer.catatan}'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => CustomerTransactionListScreen(
                      customerId: customer.id,
                      customerName: customer.nama,
                    ),
                  ),
                );
              },
              child: const Text('Lihat Transaksi'),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddCustomerScreen()),
          );
          // Hapus baris ini jika tidak perlu:
          // await _refresh();
        },
        label: const Text('Tambah Pelanggan'),
        icon: const Icon(Icons.add),
      ),
    );
  }
}