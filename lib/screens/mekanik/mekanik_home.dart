import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../utils/helpers.dart';
import '../../services/sibenmo_repository.dart';
import '../../providers/auth_provider.dart';
import '../../models/mekanik.dart';
import '../../models/servis.dart';
import '../login_screen.dart';
import 'daftar_pekerjaan.dart';

class MekanikHome extends StatefulWidget {
  final int idMekanik;

  const MekanikHome({Key? key, required this.idMekanik}) : super(key: key);

  @override
  State<MekanikHome> createState() => _MekanikHomeState();
}

class _MekanikHomeState extends State<MekanikHome> {
  final SibenmoRepository _db = SibenmoRepository.instance;
  Mekanik? _mekanik;
  int _pekerjaanAktif = 0;
  int _selesaiHariIni = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final mekanik = await _db.getMekanikById(widget.idMekanik);
      final servisList = await _db.getServisByMekanik(widget.idMekanik);
      final String today = DateTime.now().toIso8601String().substring(0, 10);
      int pekerjaanAktif = 0;
      int selesaiHariIni = 0;
      for (final servis in servisList) {
        if (servis.status == 'Diterima' ||
            servis.status == 'Diperiksa' ||
            servis.status == 'Dikerjakan') {
          pekerjaanAktif++;
        }
        final String tanggalServis =
            servis.tanggal.toIso8601String().substring(0, 10);
        if (servis.status == 'Selesai' && tanggalServis == today) {
          selesaiHariIni++;
        }
      }
      if (!mounted) return;
      setState(() {
        _mekanik = mekanik;
        _pekerjaanAktif = pekerjaanAktif;
        _selesaiHariIni = selesaiHariIni;
        _isLoading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _refresh() async {
    setState(() => _isLoading = true);
    await _loadData();
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
        title: const Text('Mekanik SIBENMO'),
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
          : RefreshIndicator(
              onRefresh: _refresh,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Selamat Datang, ${_mekanik?.nama ?? 'Mekanik'}!',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Ringkasan pekerjaan Anda:',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _buildSummaryCard(
                            icon: Icons.build,
                            label: 'Pekerjaan Aktif',
                            value: _pekerjaanAktif,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildSummaryCard(
                            icon: Icons.task_alt,
                            label: 'Selesai Hari Ini',
                            value: _selesaiHariIni,
                            color: AppColors.success,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Menu',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    GridView.count(
                      crossAxisCount: 2,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      children: [
                        _buildMenuCard(
                          icon: Icons.work,
                          label: 'Daftar Pekerjaan',
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => DaftarPekerjaan(
                                  idMekanik: widget.idMekanik,
                                ),
                              ),
                            );
                          },
                        ),
                        _buildMenuCard(
                          icon: Icons.history,
                          label: 'Riwayat Pekerjaan',
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => _RiwayatPekerjaanPage(
                                  idMekanik: widget.idMekanik,
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
            ),
    );
  }

  Widget _buildSummaryCard({
    required IconData icon,
    required String label,
    required int value,
    required Color color,
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 28, color: color),
            const SizedBox(height: 8),
            Text(
              '$value',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuCard({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 48, color: Colors.blue),
              const SizedBox(height: 12),
              Text(
                label,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RiwayatPekerjaanPage extends StatefulWidget {
  final int idMekanik;

  const _RiwayatPekerjaanPage({required this.idMekanik});

  @override
  State<_RiwayatPekerjaanPage> createState() => _RiwayatPekerjaanPageState();
}

class _RiwayatPekerjaanPageState extends State<_RiwayatPekerjaanPage> {
  List<Map<String, dynamic>> _servis = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final servisList =
          await SibenmoRepository.instance.getServisByMekanik(widget.idMekanik);
      final selesai = servisList
          .where((s) => s.status == 'Selesai')
          .toList()
        ..sort((a, b) => b.tanggal.compareTo(a.tanggal));
      final List<Map<String, dynamic>> results = [];
      for (final servis in selesai) {
        if (servis.idServis == null) continue;
        final details = await SibenmoRepository.instance
            .getServisWithDetails(servis.idServis!);
        if (details == null) continue;
        // Normalisasi tanggal ke string YYYY-MM-DD agar DateTime.parse di UI
        // aman baik untuk respons JSON API maupun fallback SQLite.
        if (details['tanggal'] is! String) {
          details['tanggal'] = Servis.fromMap(details)
              .tanggal
              .toIso8601String()
              .substring(0, 10);
        }
        results.add(details);
      }
      if (!mounted) return;
      setState(() {
        _servis = results;
        _isLoading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Riwayat Pekerjaan')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _servis.isEmpty
              ? const Center(
                  child: Text(
                    'Belum ada pekerjaan yang selesai',
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 16),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadData,
                  child: ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(12),
                    itemCount: _servis.length,
                    itemBuilder: (context, index) {
                      final servis = _servis[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: AppColors.success.withValues(alpha: 0.1),
                            child: const Icon(
                              Icons.check_circle,
                              color: AppColors.success,
                            ),
                          ),
                          title: Text(
                            'Servis #${servis['id_servis']}',
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 4),
                              Text('${servis['merk']} - ${servis['no_polisi']}'),
                              Text(
                                '${FormatHelper.formatDate(DateTime.parse(servis['tanggal'] as String))} '
                                '• ${servis['nama_pelanggan']}',
                              ),
                              const SizedBox(height: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.success.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: const Text(
                                  'Selesai',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.success,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
