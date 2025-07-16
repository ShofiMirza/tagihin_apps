import 'package:url_launcher/url_launcher.dart';
import '../models/transaction.dart';
import '../models/payment.dart';
import '../models/customer.dart';

class WhatsAppService {
  static String generateMessage({
    required Customer customer,
    required Transaction transaction,
    required List<Payment> payments,
  }) {
    final StringBuffer message = StringBuffer();
    
    message.writeln('🧾 *Pengingat Tagihan - ${customer.nama}*');
    message.writeln('');
    message.writeln('📝 *Nota:* ${transaction.deskripsi}');
    message.writeln('💰 *Total:* Rp ${_formatNumber(transaction.total)}');
    message.writeln('⏰ *Tanggal:* ${_formatDate(transaction.tanggal)}');
    message.writeln('');
    
    if (payments.isNotEmpty) {
      message.writeln('💳 *Pembayaran yang sudah diterima:*');
      for (var payment in payments) {
        message.writeln('• ${_formatDate(payment.tanggalPay)} - Rp ${_formatNumber(payment.nominal)} (${payment.metode})');
      }
      message.writeln('');
    }
    
    message.writeln('💸 *Sisa yang belum dibayar:* Rp ${_formatNumber(transaction.sisa)}');
    message.writeln('');
    message.writeln('Mohon untuk segera melakukan pelunasan. Terima kasih! 🙏');
    message.writeln('');
    message.writeln('_Pesan otomatis dari Tagihin App_');
    
    return message.toString();
  }

  static Future<bool> sendMessage({
    required String phoneNumber,
    required String message,
  }) async {
    // Bersihkan nomor HP (hapus +, -, spasi, dll)
    String cleanedPhone = phoneNumber.replaceAll(RegExp(r'[^\d]'), '');
    
    // Tambahkan kode negara Indonesia jika belum ada
    if (!cleanedPhone.startsWith('62')) {
      if (cleanedPhone.startsWith('0')) {
        cleanedPhone = '62${cleanedPhone.substring(1)}';
      } else {
        cleanedPhone = '62$cleanedPhone';
      }
    }

    // Encode message untuk URL
    final String encodedMessage = Uri.encodeComponent(message);
    
    // Buat WhatsApp URL
    final String whatsappUrl = 'https://wa.me/$cleanedPhone?text=$encodedMessage';
    
    try {
      final Uri uri = Uri.parse(whatsappUrl);
      if (await canLaunchUrl(uri)) {
        return await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
        );
      } else {
        throw 'Could not launch WhatsApp';
      }
    } catch (e) {
      print('Error launching WhatsApp: $e');
      return false;
    }
  }

  static String _formatNumber(int number) {
    return number.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]}.',
    );
  }

  static String _formatDate(DateTime date) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
      'Jul', 'Ags', 'Sep', 'Okt', 'Nov', 'Des'
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }
}