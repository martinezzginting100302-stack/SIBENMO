import 'package:flutter/material.dart';
import '../../utils/helpers.dart';
import '../../services/sibenmo_repository.dart';

class LaporanScreen extends StatefulWidget {
  const LaporanScreen({super.key});

  @override
  State<LaporanScreen> createState() => _LaporanScreenState();
}

class _LaporanScreenState extends State<LaporanScreen> {
  final SibenmoRepository _db = SibenmoRepository.instance;
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _endDate = DateTime.now();
  bool _isGenerated = false;

  Future<void> _pickDate({required bool isStart}) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: isStart ? _startDate : _endDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startDate = picked;
        } else {
          _endDate = picked;
        }
      });
    }
  }

  Future<void> _generateLaporan() async {
    if (_startDate.isAfter(_endDate)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tanggal mulai tidak boleh lebih besar dari tanggal akhir'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => _isGenerated = true);
  }

  Future<Map<String, dynamic>> _loadLaporan() async {
    final rows = await _db.getLaporanServis(_startDate, _endDate);
    final servisList = rows.map((m) {
      final map = Map<String, dynamic>.from(m as Map);
      final noPolisi = map['no_polisi'] ?? '';
      final merk = map['merk'] ?? '';
      map['kendaraan_info'] = '$noPolisi - $merk'.trim();
      return map;
    }).toList();

    int totalServis = servisList.length;
    int servisSelesai = servisList.where((s) {
      final status = (s['status'] ?? '').toString();
      return status == 'Selesai' || status == 'Dibayar';
    }).length;
    double totalPendapatan = 0;

    for (final servis in servisList) {
      final status = (servis['status'] ?? '').toString();
      if (status == 'Selesai' || status == 'Dibayar') {
        totalPendapatan += ((servis['total_biaya'] as num?) ?? 0).toDouble();
      }
    }

    return {
      'servisList': servisList,
      'totalServis': totalServis,
      'servisSelesai': servisSelesai,
      'totalPendapatan': totalPendapatan,
    };
  }

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Laporan Servis'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Rentang Waktu', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => _pickDate(isStart: true),
                            icon: const Icon(Icons.calendar_today, size: 16),
                            label: Text(FormatHelper.formatDate(_startDate)),
                          ),
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 8),
                          child: Text('s/d', style: TextStyle(fontWeight: FontWeight.w600)),
                        ),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => _pickDate(isStart: false),
                            icon: const Icon(Icons.calendar_today, size: 16),
                            label: Text(FormatHelper.formatDate(_endDate)),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton.icon(
                        onPressed: _generateLaporan,
                        icon: const Icon(Icons.assessment),
                        label: const Text('Generate Laporan'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (_isGenerated) ...[
              const SizedBox(height: 16),
              Expanded(
                child: FutureBuilder<Map<String, dynamic>>(
                  future: _loadLaporan(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snapshot.hasError) {
                      return Center(child: Text('Error: ${snapshot.error}'));
                    }
                    final data = snapshot.data!;
                    final servisList = data['servisList'] as List<Map<String, dynamic>>;
                    final totalServis = data['totalServis'] as int;
                    final servisSelesai = data['servisSelesai'] as int;
                    final totalPendapatan = data['totalPendapatan'] as double;

                    return Column(
                      children: [
                        Row(
                          children: [
                            _summaryCard('Total Servis', totalServis.toString(), Icons.receipt, Colors.blue),
                            const SizedBox(width: 12),
                            _summaryCard('Selesai', servisSelesai.toString(), Icons.check_circle, Colors.green),
                          ],
                        ),
                        const SizedBox(height: 12),
                        _summaryCard(
                          'Pendapatan',
                          FormatHelper.formatCurrency(totalPendapatan),
                          Icons.attach_money,
                          AppColors.primary,
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Detail Servis', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                            Text('${servisList.length} data', style: const TextStyle(color: AppColors.textSecondary)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Expanded(
                          child: servisList.isEmpty
                              ? const Center(
                                  child: Text('Tidak ada data servis dalam rentang ini',
                                      style: TextStyle(color: AppColors.textSecondary)),
                                )
                              : ListView.builder(
                                  itemCount: servisList.length,
                                  itemBuilder: (context, index) {
                                    final servis = servisList[index];
                                    final status = servis['status'] ?? '';
                                    return Card(
                                      margin: const EdgeInsets.only(bottom: 8),
                                      child: ListTile(
                                        dense: true,
                                        leading: CircleAvatar(
                                          radius: 16,
                                          backgroundColor: _getStatusColor(status).withValues(alpha: 0.1),
                                          child: Text(
                                            '#${servis['id_servis']}',
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: _getStatusColor(status),
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                        title: Text(servis['nama_pelanggan'] ?? '-',
                                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                                        subtitle: Text(servis['kendaraan_info'] ?? '-',
                                            style: const TextStyle(fontSize: 12)),
                                        trailing: Container(
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
                                      ),
                                    );
                                  },
                                ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _summaryCard(String title, String value, IconData icon, Color color) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Icon(icon, size: 28, color: color),
              const SizedBox(height: 8),
              Text(
                value,
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color),
              ),
              const SizedBox(height: 4),
              Text(
                title,
                style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
