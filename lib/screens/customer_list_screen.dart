import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tagihin_apps/models/customer.dart';
import '../providers/customer_provider.dart';
import '../providers/auth_provider.dart';
import 'add_customer_screen.dart';
import 'customer_detail_screen.dart';
import 'customer_transaction_list_screen.dart';

class CustomerListScreen extends StatefulWidget {
  const CustomerListScreen({super.key});

  @override
  State<CustomerListScreen> createState() => _CustomerListScreenState();
}

class _CustomerListScreenState extends State<CustomerListScreen> {
  bool _loading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshSafely();
    });
  }

  Future<void> _refreshSafely() async {
    try {
      final customerProvider = Provider.of<CustomerProvider>(context, listen: false);
      if (customerProvider.customers.isEmpty) {
        await _refresh();
      } else {
        if (mounted) {
          setState(() => _loading = false);
        }
      }
    } catch (e) {
      print('Error refreshing customers: $e');
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _refresh() async {
    if (!mounted) return;
    setState(() => _loading = true);
    try {
      await Provider.of<CustomerProvider>(context, listen: false).fetchCustomers();
    } catch (e) {
      print('Error fetching customers: $e');
    }
    if (mounted) {
      setState(() => _loading = false);
    }
  }

  Widget _buildCustomerCard(Customer customer, int index) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: InkWell(
        onTap: () async {
          try {
            final result = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => CustomerTransactionListScreen(
                  customerId: customer.id,
                  customerName: customer.nama,
                ),
              ),
            );
            if (result == true && mounted) {
              await _refresh();
            }
          } catch (e) {
            print('Navigation error: $e');
          }
        },
        borderRadius: BorderRadius.circular(15),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Avatar dengan null safety
              Hero(
                tag: 'customer_${customer.id}',
                child: Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: Colors.red.shade100,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      (customer.nama.isNotEmpty ? customer.nama[0] : 'U').toUpperCase(),
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.red.shade700,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              
              // Info pelanggan dengan null safety
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      customer.nama.isNotEmpty ? customer.nama : 'Nama tidak tersedia',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.phone, size: 16, color: Colors.grey.shade600),
                        const SizedBox(width: 4),
                        Text(
                          customer.noHp.isNotEmpty ? customer.noHp : 'No HP tidak tersedia',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                    if (customer.alamat != null && customer.alamat!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.location_on, size: 16, color: Colors.grey.shade600),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              customer.alamat!,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey.shade600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              
              // Menu & Arrow
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  PopupMenuButton<String>(
                    onSelected: (value) => _handleMenuAction(value, customer),
                    icon: Icon(Icons.more_vert, color: Colors.grey.shade600),
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit, size: 20, color: Colors.blue),
                            SizedBox(width: 8),
                            Text('Edit'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete, size: 20, color: Colors.red),
                            SizedBox(width: 8),
                            Text('Hapus'),
                          ],
                        ),
                      ),
                    ],
                  ),
                  Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey.shade400),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Text(
        'Tidak ada pelanggan ditemukan.',
        style: TextStyle(color: Colors.grey[600], fontSize: 16),
      ),
    );
  }

  Future<void> _handleMenuAction(String action, Customer customer) async {
    if (action == 'edit') {
      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => AddCustomerScreen(editCustomer: customer),
        ),
      );
      // Hanya refresh jika ada perubahan
      if (result == true) {
        await _refresh();
      }
    } else if (action == 'delete') {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          title: const Text('Hapus Pelanggan?'),
          content: Text('Pelanggan "${customer.nama}" akan dihapus permanen.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Hapus'),
            ),
          ],
        ),
      );
      if (confirm == true) {
        await Provider.of<CustomerProvider>(context, listen: false)
            .deleteCustomer(customer.id);
        // Refresh otomatis karena data berubah
        await _refresh();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Daftar Pelanggan'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              Provider.of<AuthProvider>(context, listen: false).logout();
              Navigator.pushReplacementNamed(context, '/login');
            },
          )
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
              decoration: InputDecoration(
                labelText: 'Cari Pelanggan',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(),
                ),
              ),
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: Color(0xFFD32F2F))) // Merah
                : Consumer<CustomerProvider>(
                    builder: (context, customerProvider, child) {
                      final customers = customerProvider.customers;
                      final filteredCustomers = customers.where((customer) {
                        return customer.nama.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                               customer.noHp.contains(_searchQuery);
                      }).toList();

                      return RefreshIndicator(
                        onRefresh: _refresh,
                        color: Colors.teal,
                        child: filteredCustomers.isEmpty
                            ? _buildEmptyState()
                            : ListView.builder(
                                padding: const EdgeInsets.all(16),
                                itemCount: filteredCustomers.length,
                                itemBuilder: (context, index) {
                                  final customer = filteredCustomers[index];
                                  return _buildCustomerCard(customer, index);
                                },
                              ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddCustomerScreen()),
          );
        },
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.person_add),
        label: const Text('Tambah'),
        elevation: 8,
      ),
    );
  }
}

