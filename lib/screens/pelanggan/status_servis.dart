import 'package:flutter/material.dart';
import '../../utils/helpers.dart';
import '../../services/sibenmo_repository.dart';

class StatusServis extends StatefulWidget {
  final int idPelanggan;

  const StatusServis({super.key, required this.idPelanggan});

  @override
  State<StatusServis> createState() => _StatusServisState();
}

class _StatusServisState extends State<StatusServis> {
  Future<List<Map<String, dynamic>>> _loadServis() async {
    final repo = SibenmoRepository.instance;
    final servisList = await repo.getServisByPelanggan(widget.idPelanggan);
    servisList.sort(
        (a, b) => (b.idServis ?? 0).compareTo(a.idServis ?? 0));
    const rows = <Map<String, dynamic>>[];
    for (final s in servisList) {
      final item = Map<String, dynamic>.from(s.toMap());
      final details = await repo.getServisWithDetails(s.idServis!);
      if (details != null) {
        item['no_polisi'] = details['no_polisi'];
        item['merk'] = details['merk'];
        item['tipe'] = details['tipe'];
        item['nama_pelanggan'] = details['nama_pelanggan'];
      }
      rows.add(item);
    }
    return rows;
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
      appBar: AppBar(title: const Text('Status Servis')),
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
                  Icon(
                    Icons.info_outline,
                    size: 64,
                    color: AppColors.textSecondary,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Belum ada servis diajukan',
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
              itemCount: servisList.length,
              itemBuilder: (context, index) {
                final servis = servisList[index];
                final tanggal = servis['tanggal']?.toString();
                final kendaraan =
                    '${servis['no_polisi']} - ${servis['merk']} ${servis['tipe'] ?? ''}';
                final status = servis['status'] as String? ?? '';
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    onTap: () => showServisDetailSheet(context, servis),
                    leading: CircleAvatar(
                      backgroundColor:
                          _statusColor(status).withValues(alpha: 0.1),
                      child: Icon(
                        Icons.build,
                        color: _statusColor(status),
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
                        Text(
                          kendaraan,
                          style: const TextStyle(color: AppColors.textSecondary),
                        ),
                        if (tanggal != null)
                          Text(
                            FormatHelper.formatDate(DateTime.parse(tanggal)),
                            style: const TextStyle(color: AppColors.textSecondary),
                          ),
                      ],
                    ),
                    trailing: _statusChip(status),
                    isThreeLine: tanggal != null,
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

Widget _detailInfoRow(IconData icon, String text) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: AppColors.textSecondary),
        const SizedBox(width: 8),
        Expanded(
          child: Text(text, style: const TextStyle(color: AppColors.textPrimary)),
        ),
      ],
    ),
  );
}

Widget _buildStatusTimeline(String currentStatus) {
  const statusOrder = ['Diterima', 'Diperiksa', 'Dikerjakan', 'Selesai', 'Dibayar'];
  final currentIndex = statusOrder.indexOf(currentStatus);
  return Column(
    children: [
      for (int i = 0; i < statusOrder.length; i++)
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              children: [
                Icon(
                  i < currentIndex
                      ? Icons.check_circle
                      : i == currentIndex
                          ? Icons.radio_button_checked
                          : Icons.radio_button_unchecked,
                  color: i <= currentIndex ? AppColors.primary : Colors.grey,
                ),
                if (i < statusOrder.length - 1)
                  Container(
                    width: 2,
                    height: 24,
                    color: i < currentIndex
                        ? AppColors.primary
                        : Colors.grey.shade300,
                  ),
              ],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(
                  statusOrder[i],
                  style: TextStyle(
                    fontWeight:
                        i <= currentIndex ? FontWeight.w600 : FontWeight.w400,
                    color: i <= currentIndex
                        ? AppColors.textPrimary
                        : AppColors.textSecondary,
                  ),
                ),
              ),
            ),
          ],
        ),
    ],
  );
}

Future<void> showServisDetailSheet(
  BuildContext context,
  Map<String, dynamic> servis,
) async {
  final repo = SibenmoRepository.instance;
  final idServis = servis['id_servis'] as int;

  final mekanikId = servis['id_mekanik'] as int?;
  final mekanik = mekanikId == null
      ? null
      : await repo.getMekanikById(mekanikId);
  final mekanikNama = mekanik?.nama ?? '-';

  final jasaRows = await repo.getDetailServisByServis(idServis);

  final sparepartRows = await repo.getDetailSparepartByServis(idServis);

  final pembayaran = await repo.getPembayaranByServis(idServis);
  final pembayaranRows =
      pembayaran == null ? <Map<String, dynamic>>[] : [pembayaran.toMap()];

  double totalJasa = 0;
  for (final row in jasaRows) {
    totalJasa += (row['harga'] as num).toDouble();
  }
  double totalSparepart = 0;
  for (final row in sparepartRows) {
    totalSparepart += (row['harga'] as num).toDouble() *
        (row['jumlah'] as num).toInt();
  }
  final total = totalJasa + totalSparepart;

  if (!context.mounted) return;

  final status = servis['status'] as String? ?? '';
  final tanggal = servis['tanggal']?.toString();
  final keluhan = servis['keluhan']?.toString();

  await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) {
      return DraggableScrollableSheet(
        initialChildSize: 0.95,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) {
          return Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: ListView(
              controller: scrollController,
              padding: const EdgeInsets.all(20),
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
                Text(
                  'Detail Servis #$idServis',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 16),
                Card(
                  elevation: 0,
                  color: Colors.grey.shade50,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _detailInfoRow(
                          Icons.directions_car,
                          '${servis['no_polisi'] ?? '-'} - ${servis['merk'] ?? '-'} ${servis['tipe'] ?? ''}'
                              .trim(),
                        ),
                        _detailInfoRow(Icons.engineering, 'Mekanik: $mekanikNama'),
                        if (tanggal != null)
                          _detailInfoRow(
                            Icons.calendar_today,
                            'Tanggal: ${FormatHelper.formatDate(DateTime.parse(tanggal))}',
                          ),
                        if (keluhan != null && keluhan.isNotEmpty)
                          _detailInfoRow(Icons.notes, 'Keluhan: $keluhan'),
                        const SizedBox(height: 4),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.blue.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.blue),
                            ),
                            child: Text(
                              status,
                              style: const TextStyle(
                                color: Colors.blue,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Status Servis',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                _buildStatusTimeline(status),
                const SizedBox(height: 20),
                const Text(
                  'Jasa Servis',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                if (jasaRows.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                      'Tidak ada jasa servis',
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                  )
                else
                  for (final row in jasaRows)
                    ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.build, size: 20, color: AppColors.primary),
                      title: Text(row['nama_jasa'] as String? ?? '-'),
                      trailing: Text(
                        FormatHelper.formatCurrency(
                          (row['harga'] as num).toDouble(),
                        ),
                        style: const TextStyle(
                          color: AppColors.success,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                const SizedBox(height: 8),
                const Text(
                  'Sparepart',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                if (sparepartRows.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                      'Tidak ada sparepart',
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                  )
                else
                  for (final row in sparepartRows)
                    ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(
                        Icons.inventory_2,
                        size: 20,
                        color: Colors.teal,
                      ),
                      title: Text(row['nama_sparepart'] as String? ?? '-'),
                      subtitle: Text(
                        '${row['jumlah']} x ${FormatHelper.formatCurrency((row['harga'] as num).toDouble())}',
                      ),
                      trailing: Text(
                        FormatHelper.formatCurrency(
                          (row['harga'] as num).toDouble() *
                              (row['jumlah'] as num).toInt(),
                        ),
                        style: const TextStyle(
                          color: AppColors.success,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                const Divider(height: 32),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Total Biaya',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      FormatHelper.formatCurrency(total),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
                if (pembayaranRows.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.success.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Pembayaran',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: AppColors.success,
                            ),
                          ),
                          const SizedBox(height: 8),
                          _detailInfoRow(
                            Icons.payment,
                            'Metode: ${pembayaranRows.first['metode_pembayaran'] ?? '-'}',
                          ),
                          if (pembayaranRows.first['tanggal'] != null)
                            _detailInfoRow(
                              Icons.calendar_today,
                              'Tanggal Bayar: ${FormatHelper.formatDate(DateTime.parse(pembayaranRows.first['tanggal'] as String))}',
                            ),
                          _detailInfoRow(
                            Icons.attach_money,
                            'Total Bayar: ${FormatHelper.formatCurrency((pembayaranRows.first['total_bayar'] as num).toDouble())}',
                          ),
                        ],
                      ),
                    ),
                  ),
                const SizedBox(height: 24),
              ],
            ),
          );
        },
      );
    },
  );
}
