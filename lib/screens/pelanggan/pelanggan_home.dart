import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../utils/helpers.dart';
import '../../services/sibenmo_repository.dart';
import '../../providers/auth_provider.dart';
import '../login_screen.dart';
import 'kelola_kendaraan.dart';
import 'daftar_servis.dart';
import 'status_servis.dart';
import 'riwayat_servis_pelanggan.dart';
import 'rincian_biaya.dart';

class PelangganHome extends StatefulWidget {
  final int idPelanggan;

  const PelangganHome({super.key, required this.idPelanggan});

  @override
  State<PelangganHome> createState() => _PelangganHomeState();
}

class _PelangganHomeState extends State<PelangganHome> {
  String namaPelanggan = 'Pelanggan';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPelangganData();
  }

  Future<void> _loadPelangganData() async {
    try {
      final pelanggan =
          await SibenmoRepository.instance.getPelangganById(widget.idPelanggan);
      if (pelanggan != null) {
        setState(() => namaPelanggan = pelanggan.nama);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Gagal memuat data pelanggan'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _logout() async {
    await context.read<AuthProvider>().logout();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('SIBENMO'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
            tooltip: 'Logout',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Selamat Datang, $namaPelanggan!',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Silakan pilih menu yang tersedia:',
                    style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 24),
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 1.1,
                    children: [
                      _buildMenuCard(
                        icon: Icons.directions_car,
                        iconColor: AppColors.success,
                        label: 'Kendaraan Saya',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => KelolaKendaraan(
                                idPelanggan: widget.idPelanggan,
                              ),
                            ),
                          );
                        },
                      ),
                      _buildMenuCard(
                        icon: Icons.build,
                        iconColor: AppColors.primary,
                        label: 'Ajukan Servis',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => DaftarServis(
                                idPelanggan: widget.idPelanggan,
                              ),
                            ),
                          );
                        },
                      ),
                      _buildMenuCard(
                        icon: Icons.info_outline,
                        iconColor: AppColors.warning,
                        label: 'Status Servis',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => StatusServis(
                                idPelanggan: widget.idPelanggan,
                              ),
                            ),
                          );
                        },
                      ),
                      _buildMenuCard(
                        icon: Icons.history,
                        iconColor: Colors.purple,
                        label: 'Riwayat Servis',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => RiwayatServisPelanggan(
                                idPelanggan: widget.idPelanggan,
                              ),
                            ),
                          );
                        },
                      ),
                      _buildMenuCard(
                        icon: Icons.receipt_long,
                        iconColor: Colors.teal,
                        label: 'Rincian Biaya',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => RincianBiaya(
                                idPelanggan: widget.idPelanggan,
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildMenuCard({
    required IconData icon,
    required Color iconColor,
    required String label,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 36, color: iconColor),
              ),
              const SizedBox(height: 12),
              Text(
                label,
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
  }
}