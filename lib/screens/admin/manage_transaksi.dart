import 'package:flutter/material.dart';
import '../../utils/helpers.dart';
import '../../services/sibenmo_repository.dart';

class ManageTransaksi extends StatefulWidget {
  const ManageTransaksi({super.key});

  @override
  State<ManageTransaksi> createState() => _ManageTransaksiState();
}

class _ManageTransaksiState extends State<ManageTransaksi> {
  final SibenmoRepository _db = SibenmoRepository.instance;
  final TextEditingController _keluhanController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  int? _selectedIdKendaraan;
  int? _selectedIdMekanik;
  List<Map<String, dynamic>> _kendaraanList = [];
  List<Map<String, dynamic>> _mekanikList = [];

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Diterima':
        return Colors.blue;
      case 'Diperiksa':
        return Colors.orange;
      case 'Dikerjakan':
        return Colors.purple;
      case 'Selesai':
        return Colors.green;
      case 'Dibayar':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  Future<List<Map<String, dynamic>>> _loadServis() async {
    final servisList = await _db.getAllServis();
    final rows = <Map<String, dynamic>>[];
    for (final s in servisList) {
      final details = await _db.getServisWithDetails(s.idServis!);
      final noPolisi = details?['no_polisi'] ?? '';
      final merk = details?['merk'] ?? '';
      final tipe = details?['tipe'];
      final kendaraanInfo =
          '$noPolisi - $merk${tipe != null && tipe.toString().isNotEmpty ? ' $tipe' : ''}';
      rows.add({
        ...s.toMap(),
        'nama_pelanggan': details?['nama_pelanggan'],
        'kendaraan_info': kendaraanInfo,
        'no_polisi': details?['no_polisi'],
        'merk': details?['merk'],
        'nama_mekanik': details?['nama_mekanik'],
      });
    }
    rows.sort((a, b) =>
        (b['id_servis'] as int? ?? 0).compareTo(a['id_servis'] as int? ?? 0));
    return rows;
  }

  Future<double> _getTotalBiaya(int idServis) async {
    return await _db.getTotalBiayaServis(idServis);
  }

  Future<void> _refreshData() async {
    setState(() {});
  }

  void _showAddForm() async {
    final allKendaraan = await _db.getAllKendaraan();
    final kendaraanMaps = <Map<String, dynamic>>[];
    for (final k in allKendaraan) {
      final pelanggan = await _db.getPelangganById(k.idPelanggan);
      final tipe = k.tipe;
      kendaraanMaps.add({
        'id_kendaraan': k.idKendaraan,
        'info':
            '${k.noPolisi} - ${k.merk}${tipe != null && tipe.isNotEmpty ? ' $tipe' : ''}',
        'nama_pelanggan': pelanggan?.nama,
      });
    }
    final mekanikMaps = await _db.query('mekanik');
    _kendaraanList = kendaraanMaps;
    _mekanikList = mekanikMaps;
    _selectedIdKendaraan = null;
    _selectedIdMekanik = null;
    _keluhanController.clear();

    if (!mounted) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              child: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade300,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text('Tambah Transaksi Servis',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<int>(
                        initialValue: _selectedIdKendaraan,
                        decoration: const InputDecoration(
                            labelText: 'Kendaraan',
                            prefixIcon: Icon(Icons.directions_car)),
                        items: _kendaraanList
                            .map((k) => DropdownMenuItem(
                                  value: k['id_kendaraan'] as int,
                                  child: Text(
                                      '${k['info']} (${k['nama_pelanggan'] ?? '-'})',
                                      overflow: TextOverflow.ellipsis),
                                ))
                            .toList(),
                        onChanged: (v) =>
                            setModalState(() => _selectedIdKendaraan = v),
                        validator: (v) => v == null ? 'Pilih kendaraan' : null,
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<int>(
                        initialValue: _selectedIdMekanik,
                        decoration: const InputDecoration(
                            labelText: 'Mekanik',
                            prefixIcon: Icon(Icons.engineering)),
                        items: _mekanikList
                            .map((m) => DropdownMenuItem(
                                  value: m['id_mekanik'] as int,
                                  child: Text(m['nama'] ?? ''),
                                ))
                            .toList(),
                        onChanged: (v) =>
                            setModalState(() => _selectedIdMekanik = v),
                        validator: (v) => v == null ? 'Pilih mekanik' : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _keluhanController,
                        decoration: const InputDecoration(
                            labelText: 'Keluhan',
                            prefixIcon: Icon(Icons.warning_amber)),
                        maxLines: 3,
                        validator: (v) =>
                            Validators.validateRequired(v, 'Keluhan'),
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton(
                          onPressed: () async {
                            if (_formKey.currentState!.validate()) {
                              final servisData = {
                                'id_kendaraan': _selectedIdKendaraan,
                                'id_mekanik': _selectedIdMekanik,
                                'tanggal': DateTime.now().toIso8601String(),
                                'keluhan': _keluhanController.text.trim(),
                                'status': 'Diterima',
                              };
                              await _db.insert('servis', servisData);
                              if (mounted) {
                                Navigator.pop(context);
                                _refreshData();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                        'Transaksi servis berhasil dibuat'),
                                    backgroundColor: AppColors.success,
                                  ),
                                );
                              }
                            }
                          },
                          child: const Text('Simpan'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _viewDetail(Map<String, dynamic> servis) async {
    final idServis = servis['id_servis'];
    final jasaList = await _db.getDetailServisByServis(idServis);
    final sparepartList = await _db.getDetailSparepartByServis(idServis);
    final totalBiaya = await _getTotalBiaya(idServis);

    if (!mounted) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.8,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          expand: false,
          builder: (context, scrollController) {
            return Padding(
              padding: const EdgeInsets.all(20),
              child: ListView(
                controller: scrollController,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text('Detail Transaksi',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  _detailRow('ID Servis', '#${servis['id_servis']}'),
                  _detailRow('Tanggal', servis['tanggal'] ?? '-'),
                  _detailRow('Pelanggan', servis['nama_pelanggan'] ?? '-'),
                  _detailRow('Kendaraan', servis['kendaraan_info'] ?? '-'),
                  _detailRow('Mekanik', servis['nama_mekanik'] ?? '-'),
                  _detailRow('Keluhan', servis['keluhan'] ?? '-'),
                  _detailRow('Status', servis['status'] ?? '-'),
                  const Divider(height: 30),
                  const Text('Jasa Servis',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  if (jasaList.isEmpty)
                    const Text('Belum ada jasa servis',
                        style: TextStyle(color: AppColors.textSecondary))
                  else
                    ...jasaList.map((j) => ListTile(
                          dense: true,
                          title: Text(j['nama_jasa'] ?? '-'),
                          trailing: Text(
                              FormatHelper.formatCurrency(
                                  (j['harga'] as num? ?? 0).toDouble()),
                              style:
                                  const TextStyle(fontWeight: FontWeight.w600)),
                        )),
                  const Divider(height: 30),
                  const Text('Sparepart',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  if (sparepartList.isEmpty)
                    const Text('Belum ada sparepart',
                        style: TextStyle(color: AppColors.textSecondary))
                  else
                    ...sparepartList.map((s) => ListTile(
                          dense: true,
                          title: Text(
                              '${s['nama_sparepart'] ?? '-'} x${s['jumlah'] ?? 1}'),
                          trailing: Text(
                            FormatHelper.formatCurrency(
                                (s['harga'] as num? ?? 0).toDouble() *
                                    (s['jumlah'] as num? ?? 1).toDouble()),
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        )),
                  const Divider(height: 30),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Total Biaya',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold)),
                      Text(
                        FormatHelper.formatCurrency(totalBiaya),
                        style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        const statuses = [
                          'Diterima',
                          'Diperiksa',
                          'Dikerjakan',
                          'Selesai'
                        ];
                        final currentIndex =
                            statuses.indexOf(servis['status'] ?? '');
                        if (currentIndex < statuses.length - 1) {
                          final nextStatus = statuses[currentIndex + 1];
                          await _db.update('servis', {'status': nextStatus},
                              'id_servis', idServis);
                          if (context.mounted) {
                            Navigator.pop(context);
                            _refreshData();
                          }
                        }
                      },
                      icon: const Icon(Icons.update),
                      label: const Text('Update Status',
                          style: TextStyle(color: Colors.white)),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(label,
                style: const TextStyle(color: AppColors.textSecondary)),
          ),
          const SizedBox(width: 8),
          Expanded(
              child: Text(value,
                  style: const TextStyle(fontWeight: FontWeight.w500))),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _keluhanController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Transaksi Servis')),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _loadServis(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          final servisList = snapshot.data ?? [];
          if (servisList.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.receipt_long_outlined,
                      size: 64, color: AppColors.textSecondary),
                  SizedBox(height: 16),
                  Text('Belum ada transaksi servis',
                      style: TextStyle(
                          color: AppColors.textSecondary, fontSize: 16)),
                ],
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: servisList.length,
            itemBuilder: (context, index) {
              final servis = servisList[index];
              final status = servis['status'] ?? '';
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor:
                        _getStatusColor(status).withValues(alpha: 0.1),
                    child: Icon(Icons.receipt, color: _getStatusColor(status)),
                  ),
                  title: Row(
                    children: [
                      Text('Servis #${servis['id_servis']}',
                          style: const TextStyle(fontWeight: FontWeight.w600)),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: _getStatusColor(status).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          status,
                          style: TextStyle(
                            color: _getStatusColor(status),
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Text(servis['nama_pelanggan'] ?? '-',
                          style:
                              const TextStyle(color: AppColors.textSecondary)),
                      Text(servis['kendaraan_info'] ?? '-',
                          style:
                              const TextStyle(color: AppColors.textSecondary)),
                      Text('Mekanik: ${servis['nama_mekanik'] ?? '-'}',
                          style:
                              const TextStyle(color: AppColors.textSecondary)),
                    ],
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _viewDetail(servis),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddForm,
        child: const Icon(Icons.add),
      ),
    );
  }
}
