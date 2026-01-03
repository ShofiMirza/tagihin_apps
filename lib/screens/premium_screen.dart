import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/auth_provider.dart';
import '../providers/subscription_provider.dart';
import '../services/midtrans_service.dart';

class PremiumScreen extends StatefulWidget {
  const PremiumScreen({super.key});

  @override
  State<PremiumScreen> createState() => _PremiumScreenState();
}

class _PremiumScreenState extends State<PremiumScreen> {
  bool _processing = false;
  String? _error;

  @override
  Widget build(BuildContext context) {
    final sub = context.watch<SubscriptionProvider>();
    return Scaffold(
      appBar: AppBar(title: const Text('Upgrade ke Premium')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text('Paket Premium', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    SizedBox(height: 8),
                    Text('• Pelanggan: Unlimited'),
                    Text('• WA Reminder/bulan: Unlimited'),
                    SizedBox(height: 12),
                    Text('Harga: Rp 49.000 / 30 hari', style: TextStyle(fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(_error!, style: const TextStyle(color: Colors.red)),
            ],
            const Spacer(),
            if (sub.isPremium)
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ElevatedButton.icon(
                    onPressed: null,
                    icon: const Icon(Icons.verified),
                    label: const Text('Anda sudah PREMIUM'),
                  ),
                ],
              )
            else
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ElevatedButton(
                    onPressed: _processing ? null : _startPayment,
                    child: _processing
                        ? const SizedBox(height: 22, width: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Text('Bayar Sekarang (Midtrans)'),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: _processing ? null : _refreshStatus,
                    child: const Text('Saya sudah bayar, cek status'),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _startPayment() async {
    final auth = context.read<AuthProvider>();
    final sub = context.read<SubscriptionProvider>();
    
    debugPrint('AuthProvider userId: ${auth.userId}');
    debugPrint('AuthProvider isLoggedIn: ${auth.isLoggedIn}');
    
    if (auth.userId == null || auth.userId!.isEmpty) {
      setState(() => _error = 'Anda belum login atau userId tidak valid');
      return;
    }

    setState(() {
      _processing = true;
      _error = null;
    });
    try {
      debugPrint('Starting payment for userId: ${auth.userId}');
      
      // Call backend to create Midtrans transaction
      final result = await MidtransService().createPremiumTransaction(
        userId: auth.userId!,
        email: 'user@tagihin.local', // Optional: pass real email if available
      );

      debugPrint('Payment created: ${result.orderId}');

      // Open redirect URL in external browser
      final uri = Uri.parse(result.redirectUrl);
      if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
        throw Exception('Tidak bisa membuka halaman pembayaran');
      }

      // After user returns, they can tap "cek status" to refresh
      // or you can implement polling here if desired.
    } catch (e) {
      debugPrint('Payment error: $e');
      setState(() => _error = 'Gagal memulai pembayaran: $e');
    } finally {
      setState(() => _processing = false);
      // Optionally refresh profile
      await sub.refreshProfile(context.read<AuthProvider>().userId ?? '');
    }
  }

  Future<void> _refreshStatus() async {
    setState(() {
      _processing = true;
      _error = null;
    });
    
    try {
      final auth = context.read<AuthProvider>();
      final sub = context.read<SubscriptionProvider>();
      
      debugPrint('Refreshing profile for userId: ${auth.userId}');
      await sub.refreshProfile(auth.userId ?? '');
      
      debugPrint('Profile refreshed. isPremium: ${sub.isPremium}');
      debugPrint('Profile plan: ${sub.profile?.plan}');
      debugPrint('Profile premiumUntil: ${sub.profile?.premiumUntil}');
      
      if (mounted) {
        if (sub.isPremium) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Premium aktif!'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Status masih Free. Tunggu beberapa saat lagi atau pastikan pembayaran sudah settlement.'),
              duration: Duration(seconds: 4),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Refresh status error: $e');
      if (mounted) {
        setState(() => _error = 'Gagal refresh status: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _processing = false);
      }
    }
  }
}
