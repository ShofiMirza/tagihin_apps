import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/transaction.dart';
import '../models/customer.dart';
import '../services/whatsapp_service.dart';
import '../providers/subscription_provider.dart';
import '../providers/auth_provider.dart';
import 'premium_screen.dart';

class WaReminderScreen extends StatefulWidget {
  final List<Transaction> transactions;
  final Customer customer;

  const WaReminderScreen({
    super.key,
    required this.transactions,
    required this.customer,
  });

  @override
  State<WaReminderScreen> createState() => _WaReminderScreenState();
}

class _WaReminderScreenState extends State<WaReminderScreen> {
  final Map<String, bool> _selectedTransactions = {};
  final _messageController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Initialize selection untuk transaksi belum lunas
    for (var t in widget.transactions) {
      if (t.status.toLowerCase() != 'lunas') {
        _selectedTransactions[t.id] = false;
      }
    }
    _updateMessagePreview();
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  void _selectAll() {
    setState(() {
      for (var key in _selectedTransactions.keys) {
        _selectedTransactions[key] = true;
      }
      _updateMessagePreview();
    });
  }

  void _deselectAll() {
    setState(() {
      for (var key in _selectedTransactions.keys) {
        _selectedTransactions[key] = false;
      }
      _updateMessagePreview();
    });
  }

  void _updateMessagePreview() {
    final selectedNota = widget.transactions
        .where((t) => _selectedTransactions[t.id] == true)
        .toList();

    if (selectedNota.isEmpty) {
      _messageController.text = '';
      return;
    }

    // Generate pesan
    final buffer = StringBuffer();
    buffer.writeln('Halo ${widget.customer.nama},');
    buffer.writeln();
    buffer.writeln('Ini pengingat untuk pembayaran:');
    buffer.writeln();

    int totalSisa = 0;
    for (int i = 0; i < selectedNota.length; i++) {
      final t = selectedNota[i];
      buffer.writeln('${i + 1}. ${t.deskripsi}');
      buffer.writeln('   Tanggal: ${t.tanggal.day}/${t.tanggal.month}/${t.tanggal.year}');
      buffer.writeln('   Sisa: Rp ${_formatNumber(t.sisa)}');
      buffer.writeln();
      totalSisa += t.sisa;
    }

    buffer.writeln('Total yang perlu dibayar: Rp ${_formatNumber(totalSisa)}');
    buffer.writeln();
    buffer.writeln('Terima kasih! 🙏');

    _messageController.text = buffer.toString();
  }

  String _formatNumber(int number) {
    return number.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]}.',
    );
  }

  Future<void> _sendReminder() async {
    final selectedCount = _selectedTransactions.values.where((v) => v).length;
    if (selectedCount == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih minimal 1 nota untuk reminder')),
      );
      return;
    }

    // === CHECK WA REMINDER LIMIT ===
    final subProvider = Provider.of<SubscriptionProvider>(context, listen: false);
    if (!subProvider.canSendWAReminder()) {
      final limit = subProvider.getWAReminderLimit();
      final shouldUpgrade = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Batas Reminder Tercapai'),
          content: Text(
            'Anda sudah mencapai batas $limit reminder WhatsApp per bulan untuk akun Free.\n\n'
            'Upgrade ke Premium untuk kirim reminder unlimited!',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Nanti'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Upgrade Sekarang'),
            ),
          ],
        ),
      );
      
      if (shouldUpgrade == true && mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const PremiumScreen()),
        );
      }
      return;
    }

    try {
      await WhatsAppService.sendMessage(
        phoneNumber: widget.customer.noHp,
        message: _messageController.text,
      );

      // === INCREMENT WA COUNTER AFTER SUCCESSFUL SEND ===
      final userId = Provider.of<AuthProvider>(context, listen: false).userId;
      if (userId != null) {
        await subProvider.incrementWACount(userId);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('WhatsApp dibuka, silakan kirim pesan'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final unpaidTransactions = widget.transactions
        .where((t) => t.status.toLowerCase() != 'lunas')
        .toList();

    if (unpaidTransactions.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Pengingat WhatsApp')),
        body: const Center(
          child: Text('Semua transaksi sudah lunas'),
        ),
      );
    }

    final selectedCount = _selectedTransactions.values.where((v) => v).length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pengingat WhatsApp'),
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
          // Info Customer
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: Colors.green.shade50,
            child: Row(
              children: [
                Icon(Icons.person, color: Colors.green.shade700),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.customer.nama,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        widget.customer.noHp,
                        style: TextStyle(color: Colors.grey.shade700),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.green.shade700,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '$selectedCount nota',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Transaction List
          Expanded(
            child: Row(
              children: [
                // Left: Selection List
                Expanded(
                  flex: 1,
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border(
                        right: BorderSide(color: Colors.grey.shade300),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Text(
                            'Pilih Nota:',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.grey.shade700,
                            ),
                          ),
                        ),
                        Expanded(
                          child: ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            itemCount: unpaidTransactions.length,
                            itemBuilder: (context, index) {
                              final t = unpaidTransactions[index];
                              final isSelected = _selectedTransactions[t.id] ?? false;

                              return Container(
                                margin: const EdgeInsets.only(bottom: 8),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? Colors.green.shade50
                                      : Colors.white,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: isSelected
                                        ? Colors.green
                                        : Colors.grey.shade300,
                                    width: isSelected ? 2 : 1,
                                  ),
                                ),
                                child: CheckboxListTile(
                                  value: isSelected,
                                  onChanged: (value) {
                                    setState(() {
                                      _selectedTransactions[t.id] = value ?? false;
                                      _updateMessagePreview();
                                    });
                                  },
                                  title: Text(
                                    t.deskripsi,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14,
                                    ),
                                  ),
                                  subtitle: Text(
                                    'Sisa: Rp ${_formatNumber(t.sisa)}',
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Right: Message Preview
                Expanded(
                  flex: 1,
                  child: Container(
                    color: Colors.grey.shade50,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            border: Border(
                              bottom: BorderSide(color: Colors.grey.shade300),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.message, color: Colors.grey.shade700, size: 20),
                              const SizedBox(width: 8),
                              Text(
                                'Preview Pesan:',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey.shade700,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: selectedCount == 0
                              ? Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.chat_bubble_outline,
                                        size: 64,
                                        color: Colors.grey.shade400,
                                      ),
                                      const SizedBox(height: 16),
                                      Text(
                                        'Pilih nota untuk melihat preview',
                                        style: TextStyle(
                                          color: Colors.grey.shade600,
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                              : SingleChildScrollView(
                                  padding: const EdgeInsets.all(16),
                                  child: Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: Colors.grey.shade300,
                                      ),
                                    ),
                                    child: TextField(
                                      controller: _messageController,
                                      maxLines: null,
                                      decoration: const InputDecoration(
                                        border: InputBorder.none,
                                        hintText: 'Pesan akan muncul di sini...',
                                      ),
                                      style: const TextStyle(fontSize: 14),
                                    ),
                                  ),
                                ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
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
              child: ElevatedButton.icon(
                onPressed: selectedCount > 0 ? _sendReminder : null,
                icon: const Icon(Icons.send),
                label: const Text(
                  'Kirim via WhatsApp',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green.shade600,
                  disabledBackgroundColor: Colors.grey.shade300,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
