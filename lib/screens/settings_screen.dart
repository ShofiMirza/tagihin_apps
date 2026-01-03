import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/auth_provider.dart';
import '../providers/customer_provider.dart';
import '../providers/transaction_provider.dart';
import '../providers/payment_provider.dart';
import '../providers/subscription_provider.dart';
import 'premium_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('Pengaturan'),
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Profile Section
          Consumer<AuthProvider>(
            builder: (context, auth, _) => Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: Colors.red.shade100,
                      child: Icon(
                        Icons.person,
                        size: 30,
                        color: Colors.red.shade700,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            auth.userName,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            auth.userEmail,
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          
          const SizedBox(height: 16),

          // Premium Section
          _buildPremiumCard(context),

          const SizedBox(height: 16),

          // Settings Options
          Card(
            child: Column(
              children: [
                _buildSettingsTile(
                  icon: Icons.backup,
                  title: 'Backup Data',
                  subtitle: 'Cadangkan data ke cloud',
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Fitur akan segera hadir')),
                    );
                  },
                ),
                const Divider(height: 1),
                _buildSettingsTile(
                  icon: Icons.download,
                  title: 'Export Data',
                  subtitle: 'Download data sebagai Excel/PDF',
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Fitur akan segera hadir')),
                    );
                  },
                ),
                const Divider(height: 1),
                _buildSettingsTile(
                  icon: Icons.info,
                  title: 'Tentang Aplikasi',
                  subtitle: 'Versi 1.0.0',
                  onTap: () {
                    showAboutDialog(
                      context: context,
                      applicationName: 'Tagihin',
                      applicationVersion: '1.0.0',
                      applicationLegalese: '© 2026 SobaToko\nSolusi Digital untuk Toko Anda',
                      applicationIcon: const Icon(
                        Icons.account_balance_wallet,
                        size: 48,
                        color: Color(0xFFD32F2F),
                      ),
                      children: const [
                        Text('Aplikasi manajemen tagihan sederhana dan efektif.'),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Logout Button
          Card(
            child: ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.logout,
                  color: Colors.red,
                ),
              ),
              title: const Text(
                'Keluar',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Colors.red,
                ),
              ),
              subtitle: const Text('Keluar dari akun'),
              onTap: () => _showLogoutDialog(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPremiumCard(BuildContext context) {
    final subscription = context.watch<SubscriptionProvider>();
    final customerProvider = context.watch<CustomerProvider>();
    final isPremium = subscription.isPremium;
    
    // Get current usage stats
    final customerCount = customerProvider.customerCount;
    final customerLimit = subscription.getCustomerLimit();
    final waCount = subscription.profile?.waReminderCount ?? 0;
    final waLimit = subscription.getWAReminderLimit();

    return Card(
      color: isPremium ? const Color(0xFFFFF3E0) : Colors.white,
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isPremium ? Colors.orange.shade100 : Colors.amber.shade100,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            isPremium ? Icons.workspace_premium : Icons.star_outline,
            color: isPremium ? Colors.orange : Colors.amber.shade700,
            size: 28,
          ),
        ),
        title: Text(
          isPremium ? 'Premium Aktif' : 'Upgrade ke Premium',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: isPremium ? Colors.orange.shade900 : Colors.black87,
          ),
        ),
        subtitle: isPremium
            ? Text(
                'Berlaku hingga ${_formatDate(subscription.profile?.premiumUntil)}',
                style: TextStyle(color: Colors.orange.shade700),
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 4),
                  Text(
                    'Pelanggan: $customerCount/$customerLimit',
                    style: TextStyle(
                      fontSize: 12,
                      color: customerCount >= customerLimit ? Colors.red : Colors.grey.shade700,
                      fontWeight: customerCount >= customerLimit ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  Text(
                    'WA Reminder: $waCount/$waLimit bulan ini',
                    style: TextStyle(
                      fontSize: 12,
                      color: waCount >= waLimit ? Colors.red : Colors.grey.shade700,
                      fontWeight: waCount >= waLimit ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Premium: unlimited semua',
                    style: TextStyle(fontSize: 11, color: Colors.green),
                  ),
                ],
              ),
        trailing: isPremium
            ? Chip(
                label: const Text(
                  'PREMIUM',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                backgroundColor: Colors.orange,
                padding: const EdgeInsets.symmetric(horizontal: 8),
              )
            : const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: isPremium
            ? null
            : () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const PremiumScreen(),
                  ),
                );
              },
      ),
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '-';
    return DateFormat('dd MMM yyyy').format(date);
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: Colors.grey.shade600),
      ),
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: onTap,
    );
  }

  Future<void> _showLogoutDialog(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: const Text('Keluar'),
        content: const Text('Apakah Anda yakin ingin keluar dari aplikasi?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Keluar'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      // Clear all provider data
      if (context.mounted) {
        Provider.of<CustomerProvider>(context, listen: false).clear();
        Provider.of<TransactionProvider>(context, listen: false).clear();
        Provider.of<PaymentProvider>(context, listen: false).clear();
      }
      
      // Logout
      await Provider.of<AuthProvider>(context, listen: false).logout();
      
      if (context.mounted) {
        Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
      }
    }
  }
}