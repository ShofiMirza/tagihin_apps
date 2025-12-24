import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../providers/transaction_provider.dart';
import '../providers/payment_provider.dart';
import '../providers/customer_provider.dart';
import '../providers/auth_provider.dart';
import '../models/transaction.dart';
import '../models/customer.dart';
import 'add_payment_screen.dart';
import '../widgets/whatsapp_preview_dialog.dart';
import '../widgets/full_screen_image_viewer.dart';

class TransactionDetailScreen extends StatefulWidget {
  final Transaction transaction;

  const TransactionDetailScreen({super.key, required this.transaction});

  @override
  State<TransactionDetailScreen> createState() => _TransactionDetailScreenState();
}

class _TransactionDetailScreenState extends State<TransactionDetailScreen> {
  bool _loading = false;

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
      await Provider.of<PaymentProvider>(context, listen: false)
          .fetchPayments(widget.transaction.id, userId);
      await Provider.of<TransactionProvider>(context, listen: false)
          .fetchTransactions(widget.transaction.customerId, userId);
    }
    if (mounted) {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final transaction = Provider.of<TransactionProvider>(context)
        .transactions
        .firstWhere(
          (trx) => trx.id == widget.transaction.id,
          orElse: () => widget.transaction,
        );
    final payments = Provider.of<PaymentProvider>(context).payments;

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('Detail Transaksi'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refresh,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  // Header Card
                  Container(
                    margin: const EdgeInsets.all(16),
                    child: Card(
                      child: Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              const Color(0xFFD32F2F),
                              const Color(0xFFB71C1C),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(
                                    Icons.receipt_long,
                                    color: Colors.white,
                                    size: 24,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        transaction.deskripsi,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Text(
                                        'Transaksi #${transaction.id.substring(0, 8)}',
                                        style: TextStyle(
                                          color: Colors.white.withOpacity(0.8),
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: transaction.status == 'lunas'
                                        ? Colors.green
                                        : Colors.orange,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    transaction.status == 'lunas' ? 'LUNAS' : 'BELUM LUNAS',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),
                            Row(
                              children: [
                                Expanded(
                                  child: _buildInfoCard(
                                    'Total',
                                    'Rp ${_formatNumber(transaction.total)}',
                                    Icons.account_balance_wallet,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _buildInfoCard(
                                    'Sisa',
                                    'Rp ${_formatNumber(transaction.sisa)}',
                                    Icons.pending_actions,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Tombol Lihat Foto
                  if (transaction.fotoNotaUrl != null && 
                      transaction.fotoNotaUrl!.isNotEmpty && 
                      transaction.fotoNotaUrl != 'null')
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16),
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => FullScreenImageViewer(
                                imageUrl: '${dotenv.env['APPWRITE_ENDPOINT']}/storage/buckets/${dotenv.env['APPWRITE_BUCKET_ID']}/files/${transaction.fotoNotaUrl}/view?project=${dotenv.env['APPWRITE_PROJECT_ID']}',
                                title: 'Foto Nota - ${transaction.deskripsi}',
                              ),
                            ),
                          );
                        },
                        icon: const Icon(Icons.image),
                        label: const Text('Lihat Foto Nota'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                          side: BorderSide(color: Colors.grey.shade400),
                        ),
                      ),
                    ),

                  // Progress Bar
                  Container(
                    margin: const EdgeInsets.all(16),
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.trending_up, color: Colors.grey.shade600),
                                const SizedBox(width: 8),
                                const Text(
                                  'Progress Pembayaran',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            LinearProgressIndicator(
                              value: transaction.total > 0 
                                  ? (transaction.total - transaction.sisa) / transaction.total 
                                  : 0,
                              backgroundColor: Colors.grey.shade200,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                transaction.status == 'lunas' ? Colors.green : const Color(0xFFD32F2F),
                              ),
                              minHeight: 8,
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Terbayar: Rp ${_formatNumber(transaction.total - transaction.sisa)}',
                                  style: TextStyle(
                                    color: Colors.grey.shade600,
                                    fontSize: 14,
                                  ),
                                ),
                                Text(
                                  '${transaction.total > 0 ? ((transaction.total - transaction.sisa) / transaction.total * 100).toInt() : 0}%',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF00796B),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Payment List
                  Container(
                    margin: const EdgeInsets.all(16),
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.payment, color: Colors.grey.shade600),
                                const SizedBox(width: 8),
                                const Text(
                                  'Riwayat Pembayaran',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const Spacer(),
                                Text(
                                  '${payments.length} pembayaran',
                                  style: TextStyle(
                                    color: Colors.grey.shade600,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            if (payments.isEmpty)
                              Container(
                                padding: const EdgeInsets.all(24),
                                child: Column(
                                  children: [
                                    Icon(
                                      Icons.payments_outlined,
                                      size: 48,
                                      color: Colors.grey.shade400,
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      'Belum ada pembayaran',
                                      style: TextStyle(
                                        color: Colors.grey.shade600,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            else
                              ListView.separated(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: payments.length,
                                separatorBuilder: (context, index) => Divider(
                                  color: Colors.grey.shade200,
                                  height: 1,
                                ),
                                itemBuilder: (context, index) {
                                  final payment = payments[index];
                                  return IntrinsicHeight(
                                    child: ListTile(
                                      contentPadding: const EdgeInsets.symmetric(vertical: 8),
                                      leading: Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFD32F2F).withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: const Icon(
                                          Icons.account_balance_wallet,
                                          color: Color(0xFFD32F2F),
                                          size: 20,
                                        ),
                                      ),
                                      title: Text(
                                        'Rp ${_formatNumber(payment.nominal)}',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 16,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      subtitle: Text(
                                        '${payment.tanggalPay.toLocal().toString().split(' ')[0]} - ${payment.metode}',
                                        style: TextStyle(
                                          color: Colors.grey.shade600,
                                          fontSize: 14,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      trailing: PopupMenuButton<String>(
                                        onSelected: (value) => _handlePaymentAction(value, payment),
                                        icon: Icon(Icons.more_vert, color: Colors.grey.shade600),
                                        itemBuilder: (context) => [
                                          const PopupMenuItem(
                                            value: 'edit',
                                            child: Row(
                                              children: [
                                                Icon(Icons.edit, size: 20, color: Colors.orange),
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
                                    ),
                                  );
                                },
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 100), // Space for FAB
                ],
              ),
            ),
      floatingActionButton: transaction.status != 'lunas'
          ? Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                // WhatsApp Button
                FloatingActionButton(
                  heroTag: "whatsapp",
                  onPressed: _showWhatsAppPreview,
                  backgroundColor: const Color(0xFF25D366),
                  tooltip: 'Ingatkan via WhatsApp',
                  child: const Icon(
                    Icons.message,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 16),
                
                // Add Payment Button
                FloatingActionButton.extended(
                  heroTag: "payment",
                  onPressed: () async {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AddPaymentScreen(
                          transaction: widget.transaction,
                        ),
                      ),
                    );
                    if (result == true) {
                      await _refresh();
                    }
                  },
                  backgroundColor: const Color(0xFFD32F2F),
                  icon: const Icon(Icons.add),
                  label: const Text('Tambah Pembayaran'),
                ),
              ],
            )
          : null,
    );
  }

  Widget _buildInfoCard(String title, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.white, size: 20),
          const SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: 12,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
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

  // Method untuk handle payment actions (edit/delete)
  Future<void> _handlePaymentAction(String action, payment) async {
    if (action == 'edit') {
      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => AddPaymentScreen(
            transaction: widget.transaction,
            editPayment: payment,
          ),
        ),
      );
      if (result == true) {
        await _refresh();
      }
    } else if (action == 'delete') {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Hapus Pembayaran?'),
          content: const Text('Pembayaran akan dihapus permanen.'),
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
        final userId = Provider.of<AuthProvider>(context, listen: false).userId;
        if (userId != null) {
          await Provider.of<PaymentProvider>(context, listen: false)
              .deletePayment(payment.id, widget.transaction.id, userId);
          
          // Update sisa dan status transaksi setelah delete payment
          await Provider.of<TransactionProvider>(context, listen: false)
              .updateSisaDanStatus(widget.transaction.id, userId);
          
          await _refresh();
        }
      }
    }
  }

  // Method untuk show WhatsApp preview (HANYA SATU)
  Future<void> _showWhatsAppPreview() async {
    final payments = Provider.of<PaymentProvider>(context, listen: false).payments;
    
    // Ambil data customer
    final customerProvider = Provider.of<CustomerProvider>(context, listen: false);
    final customer = customerProvider.customers.firstWhere(
      (c) => c.id == widget.transaction.customerId,
      orElse: () => Customer(
        id: '', 
        userId: '',
        nama: 'Customer tidak ditemukan', 
        noHp: '', 
        alamat: '', 
        catatan: '',
      ),
    );

    // Validasi nomor HP
    if (customer.noHp.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              Icon(Icons.warning, color: Colors.white),
              SizedBox(width: 8),
              Text('Nomor HP customer tidak tersedia'),
            ],
          ),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Show dialog
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => WhatsAppPreviewDialog(
        customer: customer,
        transaction: widget.transaction,
        payments: payments,
      ),
    );

    // Refresh jika perlu
    if (result == true) {
      // Bisa ditambahkan logic refresh jika diperlukan
    }
  }
}