import 'package:flutter/material.dart';
import '../../utils/helpers.dart';
import '../../services/sibenmo_repository.dart';
import '../../models/servis.dart';

class Pemeriksaan extends StatefulWidget {
  final int idServis;

  const Pemeriksaan({Key? key, required this.idServis}) : super(key: key);

  @override
  State<Pemeriksaan> createState() => _PemeriksaanState();
}

class _PemeriksaanState extends State<Pemeriksaan> {
  static const List<String> _kondisiList = [
    'Baik',
    'Perlu Perawatan',
    'Perlu Penggantian',
  ];

  final SibenmoRepository _db = SibenmoRepository.instance;
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _catatanController = TextEditingController();
  final TextEditingController _temuanController = TextEditingController();
  final TextEditingController _rekomendasiController = TextEditingController();
  String _kondisi = _kondisiList.first;
  Map<String, dynamic>? _servisInfo;
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final info = await _db.getServisWithDetails(widget.idServis);
      if (!mounted) return;
      setState(() {
        _servisInfo = info;
        _isLoading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _catatanController.dispose();
    _temuanController.dispose();
    _rekomendasiController.dispose();
    super.dispose();
  }

  Future<void> _simpanPemeriksaan() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);
    try {
      final Servis? servis = await _db.getServisById(widget.idServis);
      if (servis == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Data servis tidak ditemukan'),
              backgroundColor: AppColors.error,
            ),
          );
        }
        return;
      }

      final String tanggal = FormatHelper.formatDate(DateTime.now());
      final List<String> bagianPemeriksaan = [];
      bagianPemeriksaan.add('Catatan: ${_catatanController.text.trim()}');
      if (_temuanController.text.trim().isNotEmpty) {
        bagianPemeriksaan.add('Temuan: ${_temuanController.text.trim()}');
      }
      bagianPemeriksaan.add('Kondisi: $_kondisi');
      if (_rekomendasiController.text.trim().isNotEmpty) {
        bagianPemeriksaan.add(
          'Rekomendasi: ${_rekomendasiController.text.trim()}',
        );
      }
      final String catatan =
          '=== HASIL PEMERIKSAAN ($tanggal) ===\n${bagianPemeriksaan.join('\n')}';

      final String keluhanLama = (servis.keluhan ?? '').trim();
      final String keluhanBaru = keluhanLama.isEmpty
          ? catatan
          : '$keluhanLama\n\n$catatan';

      await _db.updateServis(
        servis.copyWith(status: 'Diperiksa', keluhan: keluhanBaru),
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Hasil pemeriksaan berhasil disimpan'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Terjadi kesalahan: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Pemeriksaan Kendaraan')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _buildInfoServis(),
                  const SizedBox(height: 16),
                  _buildFormSection(),
                  const SizedBox(height: 24),
                  _isSaving
                      ? const Center(child: CircularProgressIndicator())
                      : SizedBox(
                          height: 48,
                          child: ElevatedButton.icon(
                            onPressed: _simpanPemeriksaan,
                            icon: const Icon(Icons.save),
                            label: const Text('Simpan Hasil Pemeriksaan'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                            ),
                          ),
                        ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
    );
  }

  Widget _buildInfoServis() {
    final info = _servisInfo;
    if (info == null) return const SizedBox.shrink();
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${info['merk']} - ${info['no_polisi']}',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Pelanggan: ${info['nama_pelanggan']}',
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
            if (info['keluhan'] != null && (info['keluhan'] as String).trim().isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                'Keluhan: ${info['keluhan']}',
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildFormSection() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Hasil Pemeriksaan',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _catatanController,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'Catatan Pemeriksaan *',
                hintText: 'Tuliskan hasil pemeriksaan kendaraan',
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
              validator: (value) => Validators.validateRequired(
                value,
                'Catatan Pemeriksaan',
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _temuanController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Temuan',
                hintText: 'Masalah/kondisi yang ditemukan',
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
                        initialValue: _kondisi,
              decoration: const InputDecoration(
                labelText: 'Kondisi Kendaraan',
                border: OutlineInputBorder(),
              ),
              items: _kondisiList
                  .map(
                    (kondisi) => DropdownMenuItem(
                                  value: kondisi,
                      child: Text(kondisi),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                if (value != null) setState(() => _kondisi = value);
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _rekomendasiController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Rekomendasi',
                hintText: 'Rekomendasi perbaikan/penanganan',
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
