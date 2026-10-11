import 'package:flutter/material.dart';
import '../../utils/helpers.dart';
import '../../services/sibenmo_repository.dart';
import '../../models/kendaraan.dart';
import '../../models/pelanggan.dart';

class ManageKendaraan extends StatefulWidget {
  const ManageKendaraan({super.key});

  @override
  State<ManageKendaraan> createState() => _ManageKendaraanState();
}

class _ManageKendaraanState extends State<ManageKendaraan> {
  final SibenmoRepository _db = SibenmoRepository.instance;
  final TextEditingController _noPolisiController = TextEditingController();
  final TextEditingController _merkController = TextEditingController();
  final TextEditingController _tipeController = TextEditingController();
  final TextEditingController _tahunController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  int? _selectedIdPelanggan;
  List<Pelanggan> _pelangganList = [];

  Future<void> _loadPelanggan() async {
    final maps = await _db.query('pelanggan');
    _pelangganList = maps.map((m) => Pelanggan.fromMap(m)).toList();
  }

  Future<List<Map<String, dynamic>>> _loadKendaraan() async {
    final kendaraanList = await _db.getAllKendaraan();
    final rows = <Map<String, dynamic>>[];
    for (final k in kendaraanList) {
      final pelanggan = await _db.getPelangganById(k.idPelanggan);
      rows.add({
        'id_kendaraan': k.idKendaraan,
        'id_pelanggan': k.idPelanggan,
        'no_polisi': k.noPolisi,
        'merk': k.merk,
        'tipe': k.tipe,
        'tahun': k.tahun,
        'nama_pelanggan': pelanggan?.nama,
      });
    }
    rows.sort((a, b) => (b['id_kendaraan'] as int? ?? 0).compareTo(a['id_kendaraan'] as int? ?? 0));
    return rows;
  }

  Future<void> _refreshData() async {
    setState(() {});
  }

  void _showForm({Map<String, dynamic>? kendaraan}) async {
    await _loadPelanggan();
    _noPolisiController.text = kendaraan?['no_polisi'] ?? '';
    _merkController.text = kendaraan?['merk'] ?? '';
    _tipeController.text = kendaraan?['tipe'] ?? '';
    _tahunController.text = kendaraan?['tahun']?.toString() ?? '';
    _selectedIdPelanggan = kendaraan?['id_pelanggan'];
    final bool isEdit = kendaraan != null;

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
                      Text(
                        isEdit ? 'Edit Kendaraan' : 'Tambah Kendaraan',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<int>(
                        initialValue: _selectedIdPelanggan,
                        decoration: const InputDecoration(
                          labelText: 'Pelanggan',
                          prefixIcon: Icon(Icons.person),
                        ),
                        items: _pelangganList
                            .map((p) => DropdownMenuItem(
                                  value: p.idPelanggan,
                                  child: Text(p.nama),
                                ))
                            .toList(),
                        onChanged: (v) => setModalState(() => _selectedIdPelanggan = v),
                        validator: (v) => v == null ? 'Pilih pelanggan' : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _noPolisiController,
                        decoration: const InputDecoration(labelText: 'No. Polisi', prefixIcon: Icon(Icons.directions_car)),
                        validator: (v) => Validators.validateRequired(v, 'No. Polisi'),
                        textCapitalization: TextCapitalization.characters,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _merkController,
                        decoration: const InputDecoration(labelText: 'Merk', prefixIcon: Icon(Icons.branding_watermark)),
                        validator: (v) => Validators.validateRequired(v, 'Merk'),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _tipeController,
                        decoration: const InputDecoration(labelText: 'Tipe', prefixIcon: Icon(Icons.category)),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _tahunController,
                        decoration: const InputDecoration(labelText: 'Tahun', prefixIcon: Icon(Icons.calendar_today)),
                        keyboardType: TextInputType.number,
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton(
                          onPressed: () async {
                            if (_formKey.currentState!.validate()) {
                              final kendaraanData = Kendaraan(
                                idKendaraan: kendaraan?['id_kendaraan'] as int?,
                                idPelanggan: _selectedIdPelanggan!,
                                noPolisi: _noPolisiController.text.trim(),
                                merk: _merkController.text.trim(),
                                tipe: _tipeController.text.trim().isEmpty ? null : _tipeController.text.trim(),
                                tahun: int.tryParse(_tahunController.text.trim()),
                              );
                              if (isEdit) {
                                await _db.update('kendaraan', kendaraanData.toMap(), 'id_kendaraan', kendaraan['id_kendaraan']);
                              } else {
                                await _db.insert('kendaraan', kendaraanData.toMap());
                              }
                              if (mounted) {
                                Navigator.pop(context);
                                _refreshData();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(isEdit ? 'Kendaraan berhasil diupdate' : 'Kendaraan berhasil ditambahkan'),
                                    backgroundColor: AppColors.success,
                                  ),
                                );
                              }
                            }
                          },
                          child: Text(isEdit ? 'Update' : 'Simpan'),
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

  void _confirmDelete(int idKendaraan, String nama) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Kendaraan'),
        content: Text('Hapus data kendaraan "$nama"?'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
          ElevatedButton(
            onPressed: () async {
              await _db.delete('kendaraan', 'id_kendaraan', idKendaraan);
              if (mounted) {
                Navigator.pop(context);
                _refreshData();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Kendaraan berhasil dihapus'), backgroundColor: AppColors.error),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _noPolisiController.dispose();
    _merkController.dispose();
    _tipeController.dispose();
    _tahunController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Data Kendaraan')),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _loadKendaraan(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          final kendaraanList = snapshot.data ?? [];
          if (kendaraanList.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.directions_car_outlined, size: 64, color: AppColors.textSecondary),
                  SizedBox(height: 16),
                  Text('Belum ada data kendaraan', style: TextStyle(color: AppColors.textSecondary, fontSize: 16)),
                ],
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: kendaraanList.length,
            itemBuilder: (context, index) {
              final item = kendaraanList[index];
              final noPolisi = item['no_polisi'] ?? '';
              final merk = item['merk'] ?? '';
              final tipe = item['tipe'] ?? '';
              final tahun = item['tahun']?.toString() ?? '-';
              final namaPelanggan = item['nama_pelanggan'] ?? '-';
              return Dismissible(
                key: Key('kendaraan_${item['id_kendaraan']}'),
                direction: DismissDirection.endToStart,
                background: Container(
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 20),
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: AppColors.error,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(Icons.delete, color: Colors.white),
                ),
                confirmDismiss: (_) async {
                  _confirmDelete(item['id_kendaraan'], '$merk $tipe');
                  return false;
                },
                child: Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: AppColors.success.withValues(alpha: 0.1),
                      child: const Icon(Icons.directions_car, color: AppColors.success),
                    ),
                    title: Text(
                      '$noPolisi - $merk $tipe',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        Row(children: [
                          const Icon(Icons.calendar_today, size: 14, color: AppColors.textSecondary),
                          const SizedBox(width: 4),
                          Text('Tahun: $tahun', style: const TextStyle(color: AppColors.textSecondary)),
                        ]),
                        Row(children: [
                          const Icon(Icons.person, size: 14, color: AppColors.textSecondary),
                          const SizedBox(width: 4),
                          Text(namaPelanggan, style: const TextStyle(color: AppColors.textSecondary)),
                        ]),
                      ],
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.edit, color: AppColors.primary),
                      onPressed: () => _showForm(kendaraan: item),
                    ),
                    onTap: () => _showForm(kendaraan: item),
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showForm(),
        child: const Icon(Icons.add),
      ),
    );
  }
}
