import 'package:flutter/material.dart';
import '../../utils/helpers.dart';
import '../../services/sibenmo_repository.dart';

class RiwayatServis extends StatefulWidget {
  const RiwayatServis({super.key});

  @override
  State<RiwayatServis> createState() => _RiwayatServisState();
}

class _RiwayatServisState extends State<RiwayatServis> {
  final SibenmoRepository _db = SibenmoRepository.instance;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

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

  Future<List<Map<String, dynamic>>> _loadRiwayat() async {
    final servisList = await _db.getAllServis();
    const rows = <Map<String, dynamic>>[];
    for (final s in servisList) {
      if (s.status != 'Selesai' && s.status != 'Dibayar') continue;
      final details = await _db.getServisWithDetails(s.idServis!);
      final namaPelanggan = details?['nama_pelanggan']?.toString() ?? '';
      if (_searchQuery.isNotEmpty &&
          !namaPelanggan.toLowerCase().contains(_searchQuery.toLowerCase())) {
        continue;
      }
      final noPolisi = details?['no_polisi'] ?? '';
      final merk = details?['merk'] ?? '';
      final tipe = details?['tipe'];
      rows.add({
        ...s.toMap(),
        'nama_pelanggan': details?['nama_pelanggan'],
        'kendaraan_info': '$noPolisi - $merk${tipe != null && tipe.toString().isNotEmpty ? ' $tipe' : ''}',
        'no_polisi': details?['no_polisi'],
        'merk': details?['merk'],
        'nama_mekanik': details?['nama_mekanik'],
      });
    }
    rows.sort((a, b) => (b['id_servis'] as int? ?? 0).compareTo(a['id_servis'] as int? ?? 0));
    return rows;
  }

  Future<double> _getTotalBiaya(int idServis) async {
    return await _db.getTotalBiayaServis(idServis);
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
                  const Text('Detail Riwayat Servis', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  _detailRow('ID Servis', '#$idServis'),
                  _detailRow('Tanggal', servis['tanggal'] ?? '-'),
                  _detailRow('Pelanggan', servis['nama_pelanggan'] ?? '-'),
                  _detailRow('Kendaraan', servis['kendaraan_info'] ?? '-'),
                  _detailRow('Mekanik', servis['nama_mekanik'] ?? '-'),
                  _detailRow('Keluhan', servis['keluhan'] ?? '-'),
                  _detailRow('Status', servis['status'] ?? '-'),
                  const Divider(height: 30),
                  const Text('Jasa Servis', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  if (jasaList.isEmpty)
                    const Text('Tidak ada jasa servis', style: TextStyle(color: AppColors.textSecondary))
                  else
                    ...jasaList.map((j) => ListTile(
                          dense: true,
                          title: Text(j['nama_jasa'] ?? '-'),
                          trailing: Text(FormatHelper.formatCurrency((j['harga'] as num? ?? 0).toDouble()),
                              style: const TextStyle(fontWeight: FontWeight.w600)),
                        )),
                  const Divider(height: 30),
                  const Text('Sparepart', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  if (sparepartList.isEmpty)
                    const Text('Tidak ada sparepart', style: TextStyle(color: AppColors.textSecondary))
                  else
                    ...sparepartList.map((s) => ListTile(
                          dense: true,
                          title: Text('${s['nama_sparepart'] ?? '-'} x${s['jumlah'] ?? 1}'),
                          trailing: Text(
                            FormatHelper.formatCurrency(
                                (s['harga'] as num? ?? 0).toDouble() * (s['jumlah'] as num? ?? 1).toDouble()),
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        )),
                  const Divider(height: 30),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Total Biaya', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      Text(
                        FormatHelper.formatCurrency(totalBiaya),
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.primary),
                      ),
                    ],
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
            child: Text(label, style: const TextStyle(color: AppColors.textSecondary)),
          ),
          const SizedBox(width: 8),
          Expanded(child: Text(value, style: const TextStyle(fontWeight: FontWeight.w500))),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Riwayat Servis')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Cari nama pelanggan...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onChanged: (v) {
                setState(() => _searchQuery = v);
              },
            ),
          ),
          Expanded(
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: _loadRiwayat(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                final riwayatList = snapshot.data ?? [];
                if (riwayatList.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.history_outlined, size: 64, color: AppColors.textSecondary),
                        SizedBox(height: 16),
                        Text('Belum ada riwayat servis',
                            style: TextStyle(color: AppColors.textSecondary, fontSize: 16)),
                      ],
                    ),
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: riwayatList.length,
                  itemBuilder: (context, index) {
                    final servis = riwayatList[index];
                    final status = servis['status'] ?? '';
                    return FutureBuilder<double>(
                      future: _getTotalBiaya(servis['id_servis']),
                      builder: (context, totalSnapshot) {
                        final totalBiaya = totalSnapshot.data ?? 0;
                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: _getStatusColor(status).withValues(alpha: 0.1),
                              child: Icon(Icons.receipt, color: _getStatusColor(status)),
                            ),
                            title: Row(
                              children: [
                                Text('#${servis['id_servis']}', style: const TextStyle(fontWeight: FontWeight.w600)),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
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
                                    style: const TextStyle(color: AppColors.textSecondary)),
                                Text(servis['kendaraan_info'] ?? '-',
                                    style: const TextStyle(color: AppColors.textSecondary)),
                              ],
                            ),
                            trailing: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  FormatHelper.formatCurrency(totalBiaya),
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                                ),
                                const SizedBox(height: 4),
                                const Icon(Icons.chevron_right, size: 20),
                              ],
                            ),
                            isThreeLine: true,
                            onTap: () => _viewDetail(servis),
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
