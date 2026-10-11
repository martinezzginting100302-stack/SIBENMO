import 'package:flutter/material.dart';
import '../../utils/helpers.dart';
import '../../services/sibenmo_repository.dart';

class RincianBiaya extends StatefulWidget {
  final int idPelanggan;

  const RincianBiaya({super.key, required this.idPelanggan});

  @override
  State<RincianBiaya> createState() => _RincianBiayaState();
}

class _RincianBiayaState extends State<RincianBiaya> {
  bool _isLoading = true;
  bool _loadFailed = false;
  List<Map<String, dynamic>> _servisOptions = [];
  int? _selectedIdServis;

  @override
  void initState() {
    super.initState();
    _loadServisOptions();
  }

  Future<void> _loadServisOptions() async {
    setState(() => _isLoading = true);
    try {
      final repo = SibenmoRepository.instance;
      final servisList = await repo.getServisByPelanggan(widget.idPelanggan);
      final filtered = servisList
          .where((s) => s.status == 'Selesai' || s.status == 'Dibayar')
          .toList()
        ..sort((a, b) => (b.idServis ?? 0).compareTo(a.idServis ?? 0));
      const rows = <Map<String, dynamic>>[];
      for (final s in filtered) {
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
      if (!mounted) return;
      setState(() {
        _servisOptions =
            rows.map((r) => Map<String, dynamic>.from(r)).toList();
        _selectedIdServis = _servisOptions.isNotEmpty
            ? _servisOptions.first['id_servis'] as int
            : null;
        _isLoading = false;
        _loadFailed = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _loadFailed = true;
        });
      }
    }
  }

  Future<Map<String, dynamic>> _loadDetail(int idServis) async {
    final repo = SibenmoRepository.instance;

    final details = await repo.getServisWithDetails(idServis);
    final servisItem = Map<String, dynamic>.from(details ?? {'id_servis': idServis});

    final jasaRows = await repo.getDetailServisByServis(idServis);

    final sparepartRows = await repo.getDetailSparepartByServis(idServis);

    final pembayaran = await repo.getPembayaranByServis(idServis);
    final pembayaranRows =
        pembayaran == null ? <Map<String, dynamic>>[] : [pembayaran.toMap()];

    final total = await repo.getTotalBiayaServis(idServis);

    return {
      'servis': servisItem,
      'jasa': jasaRows,
      'sparepart': sparepartRows,
      'pembayaran': pembayaranRows,
      'total': total,
    };
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

  Widget _infoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: AppColors.textSecondary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(color: AppColors.textPrimary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailBody(Map<String, dynamic> detail) {
    final servis = detail['servis'] as Map<String, dynamic>;
    final jasaRows = detail['jasa'] as List<Map<String, dynamic>>;
    final sparepartRows = detail['sparepart'] as List<Map<String, dynamic>>;
    final pembayaranRows = detail['pembayaran'] as List<Map<String, dynamic>>;
    final total = (detail['total'] as num).toDouble();
    final status = servis['status']?.toString() ?? '';
    final tanggal = servis['tanggal']?.toString();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
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
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Servis #${servis['id_servis']}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    _statusChip(status),
                  ],
                ),
                const SizedBox(height: 8),
                if (tanggal != null)
                  _infoRow(
                    Icons.calendar_today,
                    'Tanggal: ${FormatHelper.formatDate(DateTime.parse(tanggal))}',
                  ),
                _infoRow(
                  Icons.directions_car,
                  'Kendaraan: ${servis['no_polisi'] ?? '-'} - ${servis['merk'] ?? '-'} ${servis['tipe'] ?? ''}',
                ),
                _infoRow(
                  Icons.engineering,
                  'Mekanik: ${servis['nama_mekanik'] ?? '-'}',
                ),
              ],
            ),
          ),
        ),
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
              leading:
                  const Icon(Icons.build, size: 20, color: AppColors.primary),
              title: Text(row['nama_jasa'] as String? ?? '-'),
              trailing: Text(
                FormatHelper.formatCurrency((row['harga'] as num).toDouble()),
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
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            Text(
              FormatHelper.formatCurrency(total),
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
        if (pembayaranRows.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 20),
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
                  _infoRow(
                    Icons.payment,
                    'Metode Pembayaran: ${pembayaranRows.first['metode_pembayaran'] ?? '-'}',
                  ),
                  if (pembayaranRows.first['tanggal'] != null)
                    _infoRow(
                      Icons.calendar_today,
                      'Tanggal Bayar: ${FormatHelper.formatDate(DateTime.parse(pembayaranRows.first['tanggal'] as String))}',
                    ),
                  _infoRow(
                    Icons.attach_money,
                    'Total Bayar: ${FormatHelper.formatCurrency((pembayaranRows.first['total_bayar'] as num).toDouble())}',
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Rincian Biaya')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _loadFailed
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        size: 64,
                        color: AppColors.error,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Gagal memuat data',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: _loadServisOptions,
                        child: const Text('Coba Lagi'),
                      ),
                    ],
                  ),
                )
              : _servisOptions.isEmpty
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.receipt_long,
                            size: 64,
                            color: AppColors.textSecondary,
                          ),
                          SizedBox(height: 16),
                          Text(
                            'Belum ada servis selesai untuk dirinci',
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    )
                  : Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                          child: DropdownButtonFormField<int>(
                        initialValue: _selectedIdServis,
                            isExpanded: true,
                            decoration: const InputDecoration(
                              labelText: 'Pilih Servis',
                              prefixIcon: Icon(Icons.receipt_long),
                              border: OutlineInputBorder(),
                            ),
                            items: _servisOptions
                                .map((s) => DropdownMenuItem(
                                  value: s['id_servis'] as int,
                                      child: Text(
                                        'Servis #${s['id_servis']} - ${s['no_polisi']}',
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ))
                                .toList(),
                            onChanged: (v) {
                              setState(() => _selectedIdServis = v);
                            },
                          ),
                        ),
                        Expanded(
                          child: _selectedIdServis == null
                              ? const Center(
                                  child: Text(
                                    'Pilih servis untuk melihat rincian biaya',
                                    style: TextStyle(
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                )
                              : FutureBuilder<Map<String, dynamic>>(
                                  future: _loadDetail(_selectedIdServis!),
                                  builder: (context, snapshot) {
                                    if (snapshot.connectionState ==
                                        ConnectionState.waiting) {
                                      return const Center(
                                        child: CircularProgressIndicator(),
                                      );
                                    }
                                    if (snapshot.hasError) {
                                      return Center(
                                        child: Text(
                                          'Error: ${snapshot.error}',
                                        ),
                                      );
                                    }
                                    final detail = snapshot.data;
                                    if (detail == null) {
                                      return const Center(
                                        child: Text('Data tidak ditemukan'),
                                      );
                                    }
                                    return _buildDetailBody(detail);
                                  },
                                ),
                        ),
                      ],
                    ),
    );
  }
}
