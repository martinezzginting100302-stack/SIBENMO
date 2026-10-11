import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../utils/helpers.dart';
import '../../providers/auth_provider.dart';
import '../login_screen.dart';
import 'manage_pelanggan.dart';
import 'manage_kendaraan.dart';
import 'manage_mekanik.dart';
import 'manage_jasa.dart';
import 'manage_sparepart.dart';
import 'manage_transaksi.dart';
import 'manage_pembayaran.dart';
import 'riwayat_servis.dart';
import 'laporan.dart';

class AdminHome extends StatefulWidget {
  const AdminHome({super.key});

  @override
  State<AdminHome> createState() => _AdminHomeState();
}

class _AdminHomeState extends State<AdminHome> {
  final List<Map<String, dynamic>> _menuItems = [
    {'icon': Icons.people, 'label': 'Data Pelanggan', 'color': Colors.blue},
    {'icon': Icons.directions_car, 'label': 'Data Kendaraan', 'color': Colors.green},
    {'icon': Icons.engineering, 'label': 'Data Mekanik', 'color': Colors.orange},
    {'icon': Icons.build, 'label': 'Jasa Servis', 'color': Colors.purple},
    {'icon': Icons.inventory_2, 'label': 'Sparepart', 'color': Colors.teal},
    {'icon': Icons.receipt_long, 'label': 'Transaksi Servis', 'color': Colors.red},
    {'icon': Icons.payment, 'label': 'Pembayaran', 'color': Colors.indigo},
    {'icon': Icons.history, 'label': 'Riwayat Servis', 'color': Colors.brown},
    {'icon': Icons.assessment, 'label': 'Laporan', 'color': Colors.cyan},
  ];

  void _navigateToScreen(int index) {
    Widget screen;
    switch (index) {
      case 0:
        screen = const ManagePelanggan();
        break;
      case 1:
        screen = const ManageKendaraan();
        break;
      case 2:
        screen = const ManageMekanik();
        break;
      case 3:
        screen = const ManageJasa();
        break;
      case 4:
        screen = const ManageSparepart();
        break;
      case 5:
        screen = const ManageTransaksi();
        break;
      case 6:
        screen = const ManagePembayaran();
        break;
      case 7:
        screen = const RiwayatServis();
        break;
      case 8:
        screen = const LaporanScreen();
        break;
      default:
        return;
    }
    Navigator.push(context, MaterialPageRoute(builder: (context) => screen));
  }

  void _logout() {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Apakah anda yakin ingin logout?'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              try {
                await context.read<AuthProvider>().logout();
              } catch (e) {
                debugPrint('Logout error: $e');
              }
              if (!mounted) return;
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => const LoginScreen()),
                (route) => false,
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Admin SIBENMO'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
            tooltip: 'Logout',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: GridView.builder(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 1.0,
          ),
          itemCount: _menuItems.length,
          itemBuilder: (context, index) {
            final item = _menuItems[index];
            return Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: InkWell(
                onTap: () => _navigateToScreen(index),
                borderRadius: BorderRadius.circular(16),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: (item['color'] as Color).withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          item['icon'] as IconData,
                          size: 40,
                          color: item['color'] as Color,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        item['label'] as String,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
