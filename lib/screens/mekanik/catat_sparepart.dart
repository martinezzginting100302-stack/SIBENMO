import 'package:flutter/material.dart';
import '../../utils/helpers.dart';
import '../../services/sibenmo_repository.dart';
import '../../models/sparepart.dart';
import '../../models/detail_sparepart.dart';

class CatatSparepart extends StatefulWidget {
  final int idServis;

  const CatatSparepart({Key? key, required this.idServis}) : super(key: key);

  @override
  State<CatatSparepart> createState() => _CatatSparepartState();
}

class _CatatSparepartState extends State<CatatSparepart> {
  final SibenmoRepository _db = SibenmoRepository.instance;
  List<Sparepart> _sparepartList = [];
  final Map<int, int> _qty = {};
  final Map<int, int> _existingQty = {};
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
      final sparepartList = await _db.getAllSparepart();
      final existing = await _db.getDetailSparepartByServis(widget.idServis);
      final Map<int, int> existingMap = {};
      for (final item in existing) {
        final k = item['id_sparepart'];
        final v = item['jumlah'];
        final idSp = k is int ? k : int.tryParse('$k');
        final qty = v is int ? v : int.tryParse('$v');
        if (idSp != null && qty != null) existingMap[idSp] = qty;
      }
      if (!mounted) return;
      setState(() {
        _servisInfo = info;
        _sparepartList = sparepartList;
        _existingQty.addAll(existingMap);
        _qty.addAll(existingMap);
        _isLoading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _ubahJumlah(Sparepart sparepart, int delta) {
    final int current = _qty[sparepart.idSparepart] ?? 0;
    final int next = current + delta;
    if (next < 0) return;
    if (next > sparepart.stok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Stok ${sparepart.namaSparepart} hanya tersedia ${sparepart.stok}',
          ),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }
    setState(() {
      _qty[sparepart.idSparepart!] = next;
    });
  }

  Future<void> _simpanSparepart() async {
    final bool adaPilihan = _sparepartList.any((sp) => (_qty[sp.idSparepart] ?? 0) > 0);
    if (!adaPilihan) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tidak ada sparepart yang dipilih'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      // Server mengurangi stok saat insertDetailSparepart, jadi tidak ada
      // penyesuaian stok manual di sini (menghindari pengurangan ganda).
      final existing = await _db.getDetailSparepartByServis(widget.idServis);
      for (final item in existing) {
        final raw = item['id_detail_sparepart'];
        final id = raw is int ? raw : int.tryParse('$raw');
        if (id != null) await _db.deleteDetailSparepart(id);
      }
      for (final sparepart in _sparepartList) {
        final int jumlah = _qty[sparepart.idSparepart] ?? 0;
        if (jumlah <= 0) continue;
        await _db.insertDetailSparepart(
          DetailSparepart(
            idServis: widget.idServis,
            idSparepart: sparepart.idSparepart!,
            jumlah: jumlah,
            harga: sparepart.harga * jumlah,
          ),
        );
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Sparepart berhasil disimpan'),
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

    try {
      final servis = await _db.getServisById(widget.idServis);
      if (servis == null) return;
      await _db.updateServis(servis.copyWith(status: 'Selesai'));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Servis telah ditandai selesai'),
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
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Catat Sparepart')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      _buildInfoServis(),
                      const SizedBox(height: 16),
                      _buildSparepartSection(),
                    ],
                  ),
                ),
                SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                    child: _isSaving
                        ? const Center(child: CircularProgressIndicator())
                        : Column(
                            children: [
                              SizedBox(
                                width: double.infinity,
                                height: 48,
                                child: ElevatedButton.icon(
                                  onPressed: _simpanSparepart,
                                  icon: const Icon(Icons.save),
                                  label: const Text('Simpan Sparepart'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.primary,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              SizedBox(
                                width: double.infinity,
                                height: 48,
                                child: OutlinedButton.icon(
                                  onPressed: _tandaiSelesai,
                                  icon: const Icon(Icons.check_circle),
                                  label: const Text('Tandai Selesai'),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: AppColors.success,
                                    side: const BorderSide(color: AppColors.success),
                                  ),
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
              ],
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

  Widget _buildSparepartSection() {
    if (_sparepartList.isEmpty) {
      return Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: const Padding(
          padding: EdgeInsets.all(24),
          child: Center(
            child: Text(
              'Belum ada sparepart tersedia',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
        ),
      );
    }
    return Column(
      children: _sparepartList
          .map((sparepart) => _buildSparepartCard(sparepart))
          .toList(),
    );
  }

  Widget _buildSparepartCard(Sparepart sparepart) {
    final int jumlah = _qty[sparepart.idSparepart] ?? 0;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        sparepart.namaSparepart,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        FormatHelper.formatCurrency(sparepart.harga),
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.success,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Stok: ${sparepart.stok}',
                        style: TextStyle(
                          fontSize: 12,
                          color: sparepart.stok > 0
                              ? AppColors.textSecondary
                              : AppColors.error,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.remove_circle_outline),
                        onPressed: sparepart.stok == 0
                            ? null
                            : () => _ubahJumlah(sparepart, -1),
                        visualDensity: VisualDensity.compact,
                      ),
                      Text(
                        '$jumlah',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.add_circle_outline),
                        onPressed: sparepart.stok == 0
                            ? null
                            : () => _ubahJumlah(sparepart, 1),
                        visualDensity: VisualDensity.compact,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (jumlah > 0) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(
                    Icons.info_outline,
                    size: 14,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Total: ${FormatHelper.formatCurrency(sparepart.harga * jumlah)}',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
