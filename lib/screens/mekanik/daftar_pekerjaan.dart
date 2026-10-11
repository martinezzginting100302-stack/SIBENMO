import 'package:flutter/material.dart';
import '../../utils/helpers.dart';
import '../../services/sibenmo_repository.dart';
import '../../models/servis.dart';
import 'detail_kendaraan.dart';

class DaftarPekerjaan extends StatefulWidget {
  final int idMekanik;

  const DaftarPekerjaan({Key? key, required this.idMekanik}) : super(key: key);

  @override
  State<DaftarPekerjaan> createState() => _DaftarPekerjaanState();
}

class _DaftarPekerjaanState extends State<DaftarPekerjaan> {
  static const List<String> _filters = [
    'Semua',
    'Diterima',
    'Diperiksa',
    'Dikerjakan',
    'Selesai',
  ];

  final SibenmoRepository _db = SibenmoRepository.instance;
  List<Map<String, dynamic>> _allServis = [];
  String _selectedFilter = 'Semua';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final servisList = await _db.getServisByMekanik(widget.idMekanik);
      final aktif = servisList.where((s) => s.status != 'Dibayar').toList();
      final List<Map<String, dynamic>> results = [];
      for (final servis in aktif) {
        if (servis.idServis == null) continue;
        final details = await _db.getServisWithDetails(servis.idServis!);
        if (details != null) results.add(details);
      }
      if (!mounted) return;
      setState(() {
        _allServis = results;
        _isLoading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List<Map<String, dynamic>> get _servisTerfilter {
    if (_selectedFilter == 'Semua') return _allServis;
    return _allServis
        .where((s) => s['status'] == _selectedFilter)
        .toList();
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

  Widget _statusChip(String status) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: _statusColor(status).withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: _statusColor(status),
        ),
      ),
    );
  }

  Widget _buildFilterChips() {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _filters.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final filter = _filters[index];
          return Center(
            child: ChoiceChip(
              label: Text(filter),
              selected: _selectedFilter == filter,
              selectedColor: AppColors.primary.withValues(alpha: 0.15),
              labelStyle: TextStyle(
                color: _selectedFilter == filter
                    ? AppColors.primary
                    : AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
              onSelected: (selected) {
                setState(() => _selectedFilter = filter);
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildServisCard(Map<String, dynamic> data) {
    final servis = Servis.fromMap(data);
    final rawId = data['id_servis'];
    final int idServis = rawId is int ? rawId : int.tryParse('$rawId') ?? 0;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => DetailKendaraan(
                idServis: idServis,
                idMekanik: widget.idMekanik,
              ),
            ),
          );
        },
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
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const Spacer(),
                  _statusChip(servis.status),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(
                    Icons.calendar_today,
                    size: 14,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    FormatHelper.formatDate(servis.tanggal),
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                '${data['merk']} - ${data['no_polisi']}',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Pelanggan: ${data['nama_pelanggan']}',
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
              if (servis.keluhan != null && servis.keluhan!.trim().isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  'Keluhan: ${servis.keluhan}',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Daftar Pekerjaan')),
      body: Column(
        children: [
          _buildFilterChips(),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _servisTerfilter.isEmpty
                    ? const Center(
                        child: Text(
                          'Tidak ada pekerjaan pada filter ini',
                          style: TextStyle(color: AppColors.textSecondary, fontSize: 16),
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadData,
                        child: ListView.builder(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
                          itemCount: _servisTerfilter.length,
                          itemBuilder: (context, index) {
                            return _buildServisCard(_servisTerfilter[index]);
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}
