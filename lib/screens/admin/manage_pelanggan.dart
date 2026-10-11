import 'package:flutter/material.dart';
import '../../utils/helpers.dart';
import '../../services/sibenmo_repository.dart';
import '../../models/pelanggan.dart';

class ManagePelanggan extends StatefulWidget {
  const ManagePelanggan({super.key});

  @override
  State<ManagePelanggan> createState() => _ManagePelangganState();
}

class _ManagePelangganState extends State<ManagePelanggan> {
  final SibenmoRepository _db = SibenmoRepository.instance;
  final TextEditingController _namaController = TextEditingController();
  final TextEditingController _noHpController = TextEditingController();
  final TextEditingController _alamatController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  Future<List<Pelanggan>> _loadPelanggan() async {
    final maps = await _db.query('pelanggan');
    return maps.map((m) => Pelanggan.fromMap(m)).toList();
  }

  Future<void> _refreshData() async {
    setState(() {});
  }

  void _showForm({Pelanggan? pelanggan}) {
    _namaController.text = pelanggan?.nama ?? '';
    _noHpController.text = pelanggan?.noHp ?? '';
    _alamatController.text = pelanggan?.alamat ?? '';
    final bool isEdit = pelanggan != null;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          ),
          child: Form(
            key: _formKey,
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
                  isEdit ? 'Edit Pelanggan' : 'Tambah Pelanggan',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _namaController,
                  decoration: const InputDecoration(labelText: 'Nama Lengkap', prefixIcon: Icon(Icons.person)),
                  validator: (v) => Validators.validateRequired(v, 'Nama'),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _noHpController,
                  decoration: const InputDecoration(labelText: 'No. Handphone', prefixIcon: Icon(Icons.phone)),
                  keyboardType: TextInputType.phone,
                  validator: (v) => Validators.validatePhone(v),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _alamatController,
                  decoration: const InputDecoration(labelText: 'Alamat', prefixIcon: Icon(Icons.location_on)),
                  maxLines: 2,
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () async {
                      if (_formKey.currentState!.validate()) {
                        final pelangganData = Pelanggan(
                          idPelanggan: pelanggan?.idPelanggan,
                          nama: _namaController.text.trim(),
                          noHp: _noHpController.text.trim(),
                          alamat: _alamatController.text.trim().isEmpty ? null : _alamatController.text.trim(),
                        );
                        if (isEdit) {
                          await _db.update('pelanggan', pelangganData.toMap(), 'id_pelanggan', pelanggan.idPelanggan!);
                        } else {
                          await _db.insert('pelanggan', pelangganData.toMap());
                        }
                        if (mounted) {
                          Navigator.pop(context);
                          _refreshData();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(isEdit ? 'Pelanggan berhasil diupdate' : 'Pelanggan berhasil ditambahkan'),
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
        );
      },
    );
  }

  void _confirmDelete(Pelanggan pelanggan) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Pelanggan'),
        content: Text('Hapus data "${pelanggan.nama}"?'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
          ElevatedButton(
            onPressed: () async {
              await _db.delete('pelanggan', 'id_pelanggan', pelanggan.idPelanggan!);
              if (mounted) {
                Navigator.pop(context);
                _refreshData();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Pelanggan berhasil dihapus'), backgroundColor: AppColors.error),
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
    _namaController.dispose();
    _noHpController.dispose();
    _alamatController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Data Pelanggan')),
      body: FutureBuilder<List<Pelanggan>>(
        future: _loadPelanggan(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          final pelangganList = snapshot.data ?? [];
          if (pelangganList.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.people_outline, size: 64, color: AppColors.textSecondary),
                  SizedBox(height: 16),
                  Text('Belum ada data pelanggan', style: TextStyle(color: AppColors.textSecondary, fontSize: 16)),
                ],
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: pelangganList.length,
            itemBuilder: (context, index) {
              final pelanggan = pelangganList[index];
              return Dismissible(
                key: Key('pelanggan_${pelanggan.idPelanggan}'),
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
                  _confirmDelete(pelanggan);
                  return false;
                },
                child: Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                      child: Text(
                        pelanggan.nama.substring(0, 1).toUpperCase(),
                        style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
                      ),
                    ),
                    title: Text(pelanggan.nama, style: const TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        Row(children: [
                          const Icon(Icons.phone, size: 14, color: AppColors.textSecondary),
                          const SizedBox(width: 4),
                          Text(pelanggan.noHp, style: const TextStyle(color: AppColors.textSecondary)),
                        ]),
                        if (pelanggan.alamat != null && pelanggan.alamat!.isNotEmpty)
                          Row(children: [
                            const Icon(Icons.location_on, size: 14, color: AppColors.textSecondary),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                pelanggan.alamat!,
                                style: const TextStyle(color: AppColors.textSecondary),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ]),
                      ],
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.edit, color: AppColors.primary),
                      onPressed: () => _showForm(pelanggan: pelanggan),
                    ),
                    isThreeLine: pelanggan.alamat != null && pelanggan.alamat!.isNotEmpty,
                    onTap: () => _showForm(pelanggan: pelanggan),
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
