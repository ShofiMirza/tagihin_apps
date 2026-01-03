import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/whatsapp_service.dart';
import '../models/transaction.dart';
import '../models/payment.dart';
import '../models/customer.dart';
import '../providers/subscription_provider.dart';
import '../providers/auth_provider.dart';

class WhatsAppPreviewDialog extends StatefulWidget {
  final Customer customer;
  final Transaction transaction;
  final List<Payment> payments;

  const WhatsAppPreviewDialog({
    super.key,
    required this.customer,
    required this.transaction,
    required this.payments,
  });

  @override
  State<WhatsAppPreviewDialog> createState() => _WhatsAppPreviewDialogState();
}

class _WhatsAppPreviewDialogState extends State<WhatsAppPreviewDialog> {
  late TextEditingController _messageController;
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    final generatedMessage = WhatsAppService.generateMessage(
      customer: widget.customer,
      transaction: widget.transaction,
      payments: widget.payments,
    );
    _messageController = TextEditingController(text: generatedMessage);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.8,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: Color(0xFF25D366), // WhatsApp green
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.message,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Preview Pesan WhatsApp',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Ke: ${widget.customer.nama} (${widget.customer.noHp})',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, color: Colors.white),
                  ),
                ],
              ),
            ),

            // Message Preview
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Preview & Edit Pesan:',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: TextField(
                          controller: _messageController,
                          maxLines: null,
                          expands: true,
                          style: const TextStyle(fontSize: 14),
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            hintText: 'Edit pesan yang akan dikirim...',
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Action Buttons
            Container(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.grey.shade700,
                        side: BorderSide(color: Colors.grey.shade300),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text('Batal'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton.icon(
                      onPressed: _sending ? null : _sendMessage,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF25D366),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      icon: _sending
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.send),
                      label: Text(_sending ? 'Mengirim...' : 'Kirim via WhatsApp'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pesan tidak boleh kosong'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _sending = true);

    final success = await WhatsAppService.sendMessage(
      phoneNumber: widget.customer.noHp,
      message: _messageController.text.trim(),
    );

    setState(() => _sending = false);

    if (success) {
      // === INCREMENT WA COUNTER AFTER SUCCESSFUL SEND ===
      final userId = Provider.of<AuthProvider>(context, listen: false).userId;
      if (userId != null) {
        await Provider.of<SubscriptionProvider>(context, listen: false)
            .incrementWACount(userId);
      }
      
      Navigator.pop(context, true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 8),
              Text('WhatsApp berhasil dibuka'),
            ],
          ),
          backgroundColor: Color(0xFF25D366),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              Icon(Icons.error, color: Colors.white),
              SizedBox(width: 8),
              Text('Gagal membuka WhatsApp'),
            ],
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }
}