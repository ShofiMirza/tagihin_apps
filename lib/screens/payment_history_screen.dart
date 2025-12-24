import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/payment_provider.dart';
import '../providers/customer_provider.dart';
import '../providers/transaction_provider.dart';
import '../providers/auth_provider.dart';
import '../models/payment.dart';
import '../models/customer.dart';
import '../models/transaction.dart';

class PaymentHistoryScreen extends StatefulWidget {
  const PaymentHistoryScreen({super.key});

  @override
  State<PaymentHistoryScreen> createState() => _PaymentHistoryScreenState();
}

class _PaymentHistoryScreenState extends State<PaymentHistoryScreen> {
  bool _loading = false;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  DateTime? _startDate;
  DateTime? _endDate;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    if (!mounted) return;
    
    try {
      if (!mounted) return;
      setState(() => _loading = true);
      
      if (!mounted) return;
      final userId = Provider.of<AuthProvider>(context, listen: false).userId;
      
      if (userId != null && mounted) {
        await Provider.of<PaymentProvider>(context, listen: false).fetchAllPayments(userId);
        if (!mounted) return;
        await Provider.of<CustomerProvider>(context, listen: false).fetchCustomers(userId);
        if (!mounted) return;
        await Provider.of<TransactionProvider>(context, listen: false).fetchAllTransactions(userId);
      }
    } catch (e) {
      if (mounted) {
        print('Error refreshing data: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('Riwayat Pembayaran'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterDialog,
            tooltip: 'Filter',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refresh,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Column(
        children: [
          // Header dengan statistik
          Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              color: Color(0xFFD32F2F),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(30),
                bottomRight: Radius.circular(30),
              ),
            ),
            child: Column(
              children: [
                // Search Bar
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(25),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: TextField(
                    controller: _searchController,
                    decoration: const InputDecoration(
                      hintText: 'Cari pembayaran...',
                      prefixIcon: Icon(Icons.search, color: Colors.grey),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(vertical: 15),
                    ),
                    onChanged: (value) {
                      setState(() => _searchQuery = value);
                    },
                  ),
                ),
                const SizedBox(height: 20),
                
                // Statistik Cards
                Consumer<PaymentProvider>(
                  builder: (context, paymentProvider, child) {
                    final payments = paymentProvider.allPayments;
                    final todayPayments = payments.where((p) {
                      final today = DateTime.now();
                      return p.tanggalPay.year == today.year &&
                             p.tanggalPay.month == today.month &&
                             p.tanggalPay.day == today.day;
                    }).toList();
                    
                    final thisMonthPayments = payments.where((p) {
                      final now = DateTime.now();
                      return p.tanggalPay.year == now.year &&
                             p.tanggalPay.month == now.month;
                    }).toList();

                    final totalToday = todayPayments.fold<int>(0, (sum, p) => sum + p.nominal);
                    final totalThisMonth = thisMonthPayments.fold<int>(0, (sum, p) => sum + p.nominal);

                    return Row(
                      children: [
                        Expanded(
                          child: _buildStatCard(
                            'Hari Ini',
                            'Rp ${_formatNumber(totalToday)}',
                            '${todayPayments.length} pembayaran',
                            Icons.today,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildStatCard(
                            'Bulan Ini',
                            'Rp ${_formatNumber(totalThisMonth)}',
                            '${thisMonthPayments.length} pembayaran',
                            Icons.calendar_month,
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),

          // List Pembayaran
          Expanded(
            child: _loading
                ? const Center(
                    child: CircularProgressIndicator(color: Color(0xFFD32F2F)),
                  )
                : RefreshIndicator(
                    onRefresh: _refresh,
                    color: const Color(0xFFD32F2F),
                    child: Consumer3<PaymentProvider, CustomerProvider, TransactionProvider>(
                      builder: (context, paymentProvider, customerProvider, transactionProvider, child) {
                        List<Payment> payments = paymentProvider.allPayments;
                        
                        // Filter berdasarkan search
                        if (_searchQuery.isNotEmpty) {
                          payments = payments.where((payment) {
                            final customer = customerProvider.customers.firstWhere(
                              (c) {
                                final transaction = transactionProvider.allTransactions.firstWhere(
                                  (t) => t.id == payment.transactionId,
                                  orElse: () => Transaction(
                                    id: '', userId: '', customerId: '', tanggal: DateTime.now(),
                                    deskripsi: '', total: 0, dp: 0, sisa: 0, status: '',
                                  ),
                                );
                                return c.id == transaction.customerId;
                              },
                              orElse: () => Customer(id: '', userId: '', nama: '', noHp: '', alamat: '', catatan: ''),
                            );
                            return customer.nama.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                                   payment.nominal.toString().contains(_searchQuery);
                          }).toList();
                        }

                        // Filter berdasarkan tanggal
                        if (_startDate != null && _endDate != null) {
                          payments = payments.where((payment) {
                            return payment.tanggalPay.isAfter(_startDate!) &&
                                   payment.tanggalPay.isBefore(_endDate!.add(const Duration(days: 1)));
                          }).toList();
                        }

                        // Sort by date (newest first)
                        payments.sort((a, b) => b.tanggalPay.compareTo(a.tanggalPay));

                        if (payments.isEmpty) {
                          return _buildEmptyState();
                        }

                        return ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: payments.length,
                          itemBuilder: (context, index) {
                            final payment = payments[index];
                            return _buildPaymentCard(payment, customerProvider, transactionProvider);
                          },
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String amount, String subtitle, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: Colors.white, size: 24),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            amount,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            subtitle,
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentCard(Payment payment, CustomerProvider customerProvider, TransactionProvider transactionProvider) {
    // Find transaction
    final transaction = transactionProvider.allTransactions.firstWhere(
      (t) => t.id == payment.transactionId,
      orElse: () => Transaction(
        id: '', userId: '', customerId: '', tanggal: DateTime.now(),
        deskripsi: 'Transaksi tidak ditemukan', total: 0, dp: 0, sisa: 0, status: '',
      ),
    );

    // Find customer
    final customer = customerProvider.customers.firstWhere(
      (c) => c.id == transaction.customerId,
      orElse: () => Customer(id: '', userId: '', nama: 'Customer tidak ditemukan', noHp: '', alamat: '', catatan: ''),
    );

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Avatar
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.red.shade100,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      customer.nama.isNotEmpty ? customer.nama[0].toUpperCase() : 'C',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.red.shade700,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                
                // Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        customer.nama,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        transaction.deskripsi,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                
                // Amount & Date
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Rp ${_formatNumber(payment.nominal)}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFD32F2F),
                      ),
                    ),
                    Text(
                      _formatDate(payment.tanggalPay),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            // Payment method
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                payment.metode,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.payment_outlined,
              size: 64,
              color: Colors.grey.shade400,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Riwayat Pembayaran',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Fitur ini sedang dalam pengembangan',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade500,
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              // Implementasi nanti
            },
            child: const Text('Segera Hadir'),
          ),
        ],
      ),
    );
  }

  Future<void> _showFilterDialog() async {
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Filter Pembayaran'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.date_range),
              title: const Text('Tanggal Mulai'),
              subtitle: Text(_startDate?.toString().split(' ')[0] ?? 'Tidak dipilih'),
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: _startDate ?? DateTime.now(),
                  firstDate: DateTime(2020),
                  lastDate: DateTime.now(),
                );
                if (date != null) {
                  setState(() => _startDate = date);
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.date_range),
              title: const Text('Tanggal Akhir'),
              subtitle: Text(_endDate?.toString().split(' ')[0] ?? 'Tidak dipilih'),
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: _endDate ?? DateTime.now(),
                  firstDate: _startDate ?? DateTime(2020),
                  lastDate: DateTime.now(),
                );
                if (date != null) {
                  setState(() => _endDate = date);
                }
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                _startDate = null;
                _endDate = null;
              });
              Navigator.pop(context);
            },
            child: const Text('Reset'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Terapkan'),
          ),
        ],
      ),
    );
  }

  String _formatNumber(int number) {
    return number.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]}.',
    );
  }

  String _formatDate(DateTime date) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
      'Jul', 'Ags', 'Sep', 'Okt', 'Nov', 'Des'
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }
}