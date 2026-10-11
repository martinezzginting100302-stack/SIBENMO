import 'package:flutter/material.dart';
import '../../utils/helpers.dart';
import '../../services/sibenmo_repository.dart';
import '../../models/servis.dart';
import '../../models/kendaraan.dart';
import '../../models/pelanggan.dart';
import 'pemeriksaan.dart';
import 'catat_servis.dart';
import 'catat_sparepart.dart';

class DetailKendaraan extends StatefulWidget {
  final int idServis;
  final int idMekanik;

  const DetailKendaraan({
    Key? key,
    required this.idServis,
    required this.idMekanik,
  }) : super(key: key);

  @override
  State<DetailKendaraan> createState() => _DetailKendaraanState();
}

class _DetailKendaraanState extends State<DetailKendaraan> {
  final SibenmoRepository _db = SibenmoRepository.instance;
  late Future<Map<String, dynamic>?> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<Map<String, dynamic>?> _load() {
    return _db.getServisWithDetails(widget.idServis);
  }

  void _reload() {
    setState(() {
      _future = _load();
    });
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'Diterima':
        return Colors.blue;
      case 'Diperiksa':
        return Colors.orange;
      case 'Dikerjakan':
        return Colors.purple;
      case 'Selesai':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  Future<void> _setStatus(String status) async {
    final servis = await _db.getServisById(widget.idServis);
    if (servis == null) return;
    await _db.updateServis(servis.copyWith(status: status));
  }

  Future<void> _mulaiPemeriksaan() async {
    await _setStatus('Diperiksa');
    if (!mounted) return;
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => Pemeriksaan(idServis: widget.idServis)),
    );
    if (mounted) _reload();
  }

  Future<void> _kerjakanServis() async {
    await _setStatus('Dikerjakan');
    if (!mounted) return;
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => CatatServis(idServis: widget.idServis)),
    );
    if (mounted) _reload();
  }

  Future<void> _catatSparepart() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => CatatSparepart(idServis: widget.idServis)),
    );
    if (mounted) _reload();
  }

  Future<void> _tandaiSelesai() async {
    final konfirmasi = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Tandai Selesai'),
        content: const Text('Apakah Anda yakin servis ini sudah selesai dikerjakan?'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.success),
            child: const Text('Ya, Selesai'),
          ),
        ],
      ),
    );
    if (konfirmasi != true || !mounted) return;
    await _setStatus('Selesai');
    if (mounted) _reload();
  }

  Widget _infoRow({required String label, required String value}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusChip(String status) {
    final color = _statusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  Widget _actionButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
    Color color = AppColors.primary,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 20),
        label: Text(label),
        style: ElevatedButton.styleFrom(backgroundColor: color),
      ),
    );
  }

  Widget _buildActions(String status) {
    switch (status) {
      case 'Diterima':
        return _actionButton(
          icon: Icons.search,
          label: 'Mulai Pemeriksaan',
          onPressed: _mulaiPemeriksaan,
        );
      case 'Diperiksa':
        return _actionButton(
          icon: Icons.build,
          label: 'Kerjakan Servis',
          onPressed: _kerjakanServis,
        );
      case 'Dikerjakan':
        return Column(
          children: [
            _actionButton(
              icon: Icons.inventory_2,
              label: 'Catat Sparepart',
              onPressed: _catatSparepart,
            ),
            const SizedBox(height: 12),
            _actionButton(
              icon: Icons.check_circle,
              label: 'Tandai Selesai',
              onPressed: _tandaiSelesai,
              color: AppColors.success,
            ),
          ],
        );
      case 'Selesai':
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.success.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.verified, color: AppColors.success),
              SizedBox(width: 8),
              Text(
                'Servis Telah Selesai',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: AppColors.success,
                ),
              ),
            ],
          ),
        );
      default:
        return const SizedBox.shrink();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Detail Kendaraan')),
      body: FutureBuilder<Map<String, dynamic>?>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError || snapshot.data == null) {
            return const Center(
              child: Text(
                'Data servis tidak ditemukan',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 16),
              ),
            );
          }
          final data = snapshot.data!;
          int asInt(dynamic v) => v is int ? v : int.tryParse('$v') ?? 0;
          int? asIntOrNull(dynamic v) =>
              v == null ? null : (v is int ? v : int.tryParse('$v'));
          final kendaraan = Kendaraan(
            idKendaraan: asIntOrNull(data['id_kendaraan']),
            idPelanggan: asInt(data['id_pelanggan']),
            noPolisi: data['no_polisi']?.toString() ?? '-',
            merk: data['merk']?.toString() ?? '-',
            tipe: data['tipe']?.toString(),
            tahun: asIntOrNull(data['tahun']),
          );
          final pelanggan = Pelanggan(
            idPelanggan: asInt(data['id_pelanggan']),
            nama: data['nama_pelanggan']?.toString() ?? '-',
            noHp: data['no_hp']?.toString() ?? '-',
            alamat: data['alamat']?.toString(),
          );
          final servis = Servis.fromMap(data);
          final status = servis.status;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            'Servis #${servis.idServis}',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const Spacer(),
                          _statusChip(status),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        FormatHelper.formatDate(servis.tanggal),
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.person, size: 20, color: AppColors.primary),
                          SizedBox(width: 8),
                          Text(
                            'Data Pelanggan',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _infoRow(label: 'Nama', value: pelanggan.nama),
                      _infoRow(label: 'No. HP', value: pelanggan.noHp),
                      if (pelanggan.alamat != null &&
                          pelanggan.alamat!.trim().isNotEmpty)
                        _infoRow(label: 'Alamat', value: pelanggan.alamat!),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(
                            Icons.directions_car,
                            size: 20,
                            color: AppColors.primary,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Data Kendaraan',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _infoRow(label: 'No. Polisi', value: kendaraan.noPolisi),
                      _infoRow(label: 'Merk', value: kendaraan.merk),
                      _infoRow(label: 'Tipe', value: kendaraan.tipe ?? '-'),
                      _infoRow(
                        label: 'Tahun',
                        value: kendaraan.tahun?.toString() ?? '-',
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(
                            Icons.report_problem,
                            size: 20,
                            color: AppColors.warning,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Keluhan Pelanggan',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        servis.keluhan == null || servis.keluhan!.trim().isEmpty
                            ? '-'
                            : servis.keluhan!,
                        style: const TextStyle(
                          fontSize: 14,
                          height: 1.5,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              _buildActions(status),
              const SizedBox(height: 24),
            ],
          );
        },
      ),
    );
  }
}
