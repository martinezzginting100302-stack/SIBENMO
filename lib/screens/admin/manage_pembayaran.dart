import 'package:flutter/material.dart';
import '../../utils/helpers.dart';
import '../../services/sibenmo_repository.dart';

class ManagePembayaran extends StatefulWidget {
  const ManagePembayaran({super.key});

  @override
  State<ManagePembayaran> createState() => _ManagePembayaranState();
}

class _ManagePembayaranState extends State<ManagePembayaran> {
  final SibenmoRepository _db = SibenmoRepository.instance;

  Future<List<Map<String, dynamic>>> _loadServisBelumBayar() async {
    final servisList = await _db.getAllServis();
    final rows = <Map<String, dynamic>>[];
    for (final s in servisList) {
      if (s.status != 'Selesai') continue;
      final details = await _db.getServisWithDetails(s.idServis!);
      final noPolisi = details?['no_polisi'] ?? '';
      final merk = details?['merk'] ?? '';
      final tipe = details?['tipe'];
      rows.add({
        'id_servis': s.idServis,
        'tanggal': s.tanggal.toIso8601String(),
        'status': s.status,
        'nama_pelanggan': details?['nama_pelanggan'],
        'kendaraan_info': '$noPolisi - $merk${tipe != null && tipe.toString().isNotEmpty ? ' $tipe' : ''}',
      });
    }
    rows.sort((a, b) => (b['id_servis'] as int? ?? 0).compareTo(a['id_servis'] as int? ?? 0));
    return rows;
  }

  Future<double> _getTotalBiaya(int idServis) async {
    return await _db.getTotalBiayaServis(idServis);
  }

  Future<void> _refreshData() async {
    setState(() {});
  }

  void _showPaymentDialog(Map<String, dynamic> servis) async {
    final totalBiaya = await _getTotalBiaya(servis['id_servis']);
    String metodePembayaran = 'Tunai';

    if (!mounted) return;
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: const Text('Proses Pembayaran'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _detailRow('Servis', '#${servis['id_servis']}'),
                    _detailRow('Pelanggan', servis['nama_pelanggan'] ?? '-'),
                    _detailRow('Kendaraan', servis['kendaraan_info'] ?? '-'),
                    const Divider(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Total Bayar:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        Text(
                          FormatHelper.formatCurrency(totalBiaya),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Text('Metode Pembayaran:', style: TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: ['Tunai', 'Transfer', 'QRIS', 'Kartu'].map((metode) {
                        return ChoiceChip(
                          label: Text(metode),
                          selected: metodePembayaran == metode,
                          selectedColor: AppColors.primary.withValues(alpha: 0.1),
                          labelStyle: TextStyle(
                            color: metodePembayaran == metode ? AppColors.primary : AppColors.textPrimary,
                          ),
                          onSelected: (_) {
                            setDialogState(() => metodePembayaran = metode);
                          },
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Batal'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final pembayaranData = {
                      'id_servis': servis['id_servis'],
                      'tanggal_bayar': DateTime.now().toIso8601String(),
                      'total_bayar': totalBiaya,
                      'metode_pembayaran': metodePembayaran,
                    };
                    await _db.insert('pembayaran', pembayaranData);
                    await _db.update('servis', {'status': 'Dibayar'}, 'id_servis', servis['id_servis']);
                    if (mounted) {
                      Navigator.pop(context);
                      _refreshData();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Pembayaran berhasil diproses'),
                          backgroundColor: AppColors.success,
                        ),
                      );
                    }
                  },
                  child: const Text('Bayar'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(label, style: const TextStyle(color: AppColors.textSecondary)),
          ),
          const SizedBox(width: 8),
          Expanded(child: Text(value, style: const TextStyle(fontWeight: FontWeight.w500))),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Pembayaran')),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _loadServisBelumBayar(),
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
                  Icon(Icons.payment_outlined, size: 64, color: AppColors.textSecondary),
                  SizedBox(height: 16),
                  Text('Tidak ada servis yang perlu dibayar',
                      style: TextStyle(color: AppColors.textSecondary, fontSize: 16)),
                ],
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: servisList.length,
            itemBuilder: (context, index) {
              final servis = servisList[index];
              return FutureBuilder<double>(
                future: _getTotalBiaya(servis['id_servis']),
                builder: (context, totalSnapshot) {
                  final totalBiaya = totalSnapshot.data ?? 0;
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: AppColors.warning.withValues(alpha: 0.1),
                        child: const Icon(Icons.payment, color: AppColors.warning),
                      ),
                      title: Text(
                        'Servis #${servis['id_servis']}',
                        style: const TextStyle(fontWeight: FontWeight.w600),
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
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Icon(Icons.chevron_right, color: AppColors.textSecondary),
                        ],
                      ),
                      isThreeLine: true,
                      onTap: () => _showPaymentDialog(servis),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
