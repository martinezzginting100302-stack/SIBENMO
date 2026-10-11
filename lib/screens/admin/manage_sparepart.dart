import 'package:flutter/material.dart';
import '../../utils/helpers.dart';
import '../../services/sibenmo_repository.dart';
import '../../models/sparepart.dart';

class ManageSparepart extends StatefulWidget {
  const ManageSparepart({super.key});

  @override
  State<ManageSparepart> createState() => _ManageSparepartState();
}

class _ManageSparepartState extends State<ManageSparepart> {
  final SibenmoRepository _db = SibenmoRepository.instance;
  final TextEditingController _namaSparepartController = TextEditingController();
  final TextEditingController _hargaController = TextEditingController();
  final TextEditingController _stokController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  Future<List<Sparepart>> _loadSparepart() async {
    final maps = await _db.query('sparepart');
    return maps.map((m) => Sparepart.fromMap(m)).toList();
  }

  Future<void> _refreshData() async {
    setState(() {});
  }

  void _showForm({Sparepart? sparepart}) {
    _namaSparepartController.text = sparepart?.namaSparepart ?? '';
    _hargaController.text = sparepart?.harga.toString() ?? '';
    _stokController.text = sparepart?.stok.toString() ?? '';
    final bool isEdit = sparepart != null;

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
                  isEdit ? 'Edit Sparepart' : 'Tambah Sparepart',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _namaSparepartController,
                  decoration: const InputDecoration(labelText: 'Nama Sparepart', prefixIcon: Icon(Icons.inventory_2)),
                  validator: (v) => Validators.validateRequired(v, 'Nama Sparepart'),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _hargaController,
                  decoration: const InputDecoration(labelText: 'Harga (Rp)', prefixIcon: Icon(Icons.attach_money)),
                  keyboardType: TextInputType.number,
                  validator: (v) => Validators.validateRequired(v, 'Harga'),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _stokController,
                  decoration: const InputDecoration(labelText: 'Stok', prefixIcon: Icon(Icons.inventory)),
                  keyboardType: TextInputType.number,
                  validator: (v) => Validators.validateRequired(v, 'Stok'),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () async {
                      if (_formKey.currentState!.validate()) {
                        final sparepartData = Sparepart(
                          idSparepart: sparepart?.idSparepart,
                          namaSparepart: _namaSparepartController.text.trim(),
                          harga: double.tryParse(_hargaController.text.trim()) ?? 0,
                          stok: int.tryParse(_stokController.text.trim()) ?? 0,
                        );
                        if (isEdit) {
                          await _db.update('sparepart', sparepartData.toMap(), 'id_sparepart', sparepart.idSparepart!);
                        } else {
                          await _db.insert('sparepart', sparepartData.toMap());
                        }
                        if (mounted) {
                          Navigator.pop(context);
                          _refreshData();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(isEdit ? 'Sparepart berhasil diupdate' : 'Sparepart berhasil ditambahkan'),
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

  void _confirmDelete(Sparepart sparepart) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Sparepart'),
        content: Text('Hapus "${sparepart.namaSparepart}"?'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
          ElevatedButton(
            onPressed: () async {
              await _db.delete('sparepart', 'id_sparepart', sparepart.idSparepart!);
              if (mounted) {
                Navigator.pop(context);
                _refreshData();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Sparepart berhasil dihapus'), backgroundColor: AppColors.error),
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
    _namaSparepartController.dispose();
    _hargaController.dispose();
    _stokController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Sparepart')),
      body: FutureBuilder<List<Sparepart>>(
        future: _loadSparepart(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          final sparepartList = snapshot.data ?? [];
          if (sparepartList.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.inventory_2_outlined, size: 64, color: AppColors.textSecondary),
                  SizedBox(height: 16),
                  Text('Belum ada data sparepart', style: TextStyle(color: AppColors.textSecondary, fontSize: 16)),
                ],
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: sparepartList.length,
            itemBuilder: (context, index) {
              final sparepart = sparepartList[index];
              return Dismissible(
                key: Key('sparepart_${sparepart.idSparepart}'),
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
                  _confirmDelete(sparepart);
                  return false;
                },
                child: Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: AppColors.accent.withValues(alpha: 0.1),
                      child: const Icon(Icons.inventory_2, color: AppColors.accent),
                    ),
                    title: Text(sparepart.namaSparepart, style: const TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        Text(
                          FormatHelper.formatCurrency(sparepart.harga),
                          style: const TextStyle(color: AppColors.success, fontWeight: FontWeight.w500),
                        ),
                        Text(
                          'Stok: ${sparepart.stok}',
                          style: const TextStyle(color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                    isThreeLine: true,
                    trailing: IconButton(
                      icon: const Icon(Icons.edit, color: AppColors.primary),
                      onPressed: () => _showForm(sparepart: sparepart),
                    ),
                    onTap: () => _showForm(sparepart: sparepart),
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
