import 'package:flutter/material.dart';
import '../../utils/helpers.dart';
import '../../services/sibenmo_repository.dart';
import 'status_servis.dart';

class RiwayatServisPelanggan extends StatefulWidget {
  final int idPelanggan;

  const RiwayatServisPelanggan({super.key, required this.idPelanggan});

  @override
  State<RiwayatServisPelanggan> createState() => _RiwayatServisPelangganState();
}

class _RiwayatServisPelangganState extends State<RiwayatServisPelanggan> {
  Future<List<Map<String, dynamic>>> _loadRiwayat() async {
    final repo = SibenmoRepository.instance;
    final servisList = await repo.getServisByPelanggan(widget.idPelanggan);
    final filtered = servisList
        .where((s) => s.status == 'Selesai' || s.status == 'Dibayar')
        .toList()
      ..sort((a, b) => (b.idServis ?? 0).compareTo(a.idServis ?? 0));

    const items = <Map<String, dynamic>>[];
    for (final s in filtered) {
      final item = Map<String, dynamic>.from(s.toMap());
      final details = await repo.getServisWithDetails(s.idServis!);
      if (details != null) {
        item['no_polisi'] = details['no_polisi'];
        item['merk'] = details['merk'];
        item['tipe'] = details['tipe'];
        item['nama_pelanggan'] = details['nama_pelanggan'];
      }
      item['total_biaya'] = await repo.getTotalBiayaServis(s.idServis!);
      items.add(item);
    }
    return items;
  }

  void _refreshData() {
    setState(() {});
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
      case 'Dibayar':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  Widget _statusChip(String status) {
    final color = _statusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Riwayat Servis')),
      body: FutureBuilder<List<Map<String, dynamic>>>(
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
                  Icon(
                    Icons.history,
                    size: 64,
                    color: AppColors.textSecondary,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Belum ada riwayat servis',
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 16),
                  ),
                ],
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: () async => _refreshData(),
            child: ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              itemCount: riwayatList.length,
              itemBuilder: (context, index) {
                final item = riwayatList[index];
                final tanggal = item['tanggal']?.toString();
                final status = item['status'] as String? ?? '';
                final totalBiaya = (item['total_biaya'] as num?)?.toDouble() ?? 0;
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    onTap: () => showServisDetailSheet(context, item),
                    leading: CircleAvatar(
                      backgroundColor:
                          _statusColor(status).withValues(alpha: 0.1),
                      child: Icon(
                        Icons.history,
                        color: _statusColor(status),
                      ),
                    ),
                    title: Text(
                      'Servis #${item['id_servis']}',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        Text(
                          '${item['no_polisi']} - ${item['merk']} ${item['tipe'] ?? ''}',
                          style: const TextStyle(color: AppColors.textSecondary),
                        ),
                        if (tanggal != null)
                          Text(
                            FormatHelper.formatDate(DateTime.parse(tanggal)),
                            style: const TextStyle(color: AppColors.textSecondary),
                          ),
                        const SizedBox(height: 4),
                        Text(
                          FormatHelper.formatCurrency(totalBiaya),
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    trailing: _statusChip(status),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
