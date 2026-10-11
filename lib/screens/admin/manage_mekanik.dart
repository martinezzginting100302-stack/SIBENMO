import 'package:flutter/material.dart';
import '../../utils/helpers.dart';
import '../../services/sibenmo_repository.dart';
import '../../models/mekanik.dart';

class ManageMekanik extends StatefulWidget {
  const ManageMekanik({super.key});

  @override
  State<ManageMekanik> createState() => _ManageMekanikState();
}

class _ManageMekanikState extends State<ManageMekanik> {
  final SibenmoRepository _db = SibenmoRepository.instance;
  final TextEditingController _namaController = TextEditingController();
  final TextEditingController _noHpController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  Future<List<Mekanik>> _loadMekanik() async {
    final maps = await _db.query('mekanik');
    return maps.map((m) => Mekanik.fromMap(m)).toList();
  }

  Future<void> _refreshData() async {
    setState(() {});
  }

  void _showForm({Mekanik? mekanik}) {
    _namaController.text = mekanik?.nama ?? '';
    _noHpController.text = mekanik?.noHp ?? '';
    final bool isEdit = mekanik != null;

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
                  isEdit ? 'Edit Mekanik' : 'Tambah Mekanik',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _namaController,
                  decoration: const InputDecoration(labelText: 'Nama Mekanik', prefixIcon: Icon(Icons.engineering)),
                  validator: (v) => Validators.validateRequired(v, 'Nama'),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _noHpController,
                  decoration: const InputDecoration(labelText: 'No. Handphone', prefixIcon: Icon(Icons.phone)),
                  keyboardType: TextInputType.phone,
                  validator: (v) => Validators.validatePhone(v),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () async {
                      if (_formKey.currentState!.validate()) {
                        final mekanikData = Mekanik(
                          idMekanik: mekanik?.idMekanik,
                          nama: _namaController.text.trim(),
                          noHp: _noHpController.text.trim(),
                        );
                        if (isEdit) {
                          await _db.update('mekanik', mekanikData.toMap(), 'id_mekanik', mekanik.idMekanik!);
                        } else {
                          await _db.insert('mekanik', mekanikData.toMap());
                        }
                        if (mounted) {
                          Navigator.pop(context);
                          _refreshData();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(isEdit ? 'Mekanik berhasil diupdate' : 'Mekanik berhasil ditambahkan'),
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

  void _confirmDelete(Mekanik mekanik) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Mekanik'),
        content: Text('Hapus data "${mekanik.nama}"?'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
          ElevatedButton(
            onPressed: () async {
              await _db.delete('mekanik', 'id_mekanik', mekanik.idMekanik!);
              if (mounted) {
                Navigator.pop(context);
                _refreshData();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Mekanik berhasil dihapus'), backgroundColor: AppColors.error),
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Data Mekanik')),
      body: FutureBuilder<List<Mekanik>>(
        future: _loadMekanik(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          final mekanikList = snapshot.data ?? [];
          if (mekanikList.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.engineering_outlined, size: 64, color: AppColors.textSecondary),
                  SizedBox(height: 16),
                  Text('Belum ada data mekanik', style: TextStyle(color: AppColors.textSecondary, fontSize: 16)),
                ],
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: mekanikList.length,
            itemBuilder: (context, index) {
              final mekanik = mekanikList[index];
              return Dismissible(
                key: Key('mekanik_${mekanik.idMekanik}'),
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
                  _confirmDelete(mekanik);
                  return false;
                },
                child: Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: AppColors.warning.withValues(alpha: 0.1),
                      child: const Icon(Icons.engineering, color: AppColors.warning),
                    ),
                    title: Text(mekanik.nama, style: const TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: Row(
                      children: [
                        const Icon(Icons.phone, size: 14, color: AppColors.textSecondary),
                        const SizedBox(width: 4),
                        Text(mekanik.noHp ?? '-', style: const TextStyle(color: AppColors.textSecondary)),
                      ],
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.edit, color: AppColors.primary),
                      onPressed: () => _showForm(mekanik: mekanik),
                    ),
                    onTap: () => _showForm(mekanik: mekanik),
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
