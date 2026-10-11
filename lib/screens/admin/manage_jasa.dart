import 'package:flutter/material.dart';
import '../../utils/helpers.dart';
import '../../services/api_service.dart';
import '../../services/sibenmo_repository.dart';
import '../../models/jasa_servis.dart';

class ManageJasa extends StatefulWidget {
  const ManageJasa({super.key});

  @override
  State<ManageJasa> createState() => _ManageJasaState();
}

class _ManageJasaState extends State<ManageJasa> {
  final SibenmoRepository _db = SibenmoRepository.instance;
  final TextEditingController _namaJasaController = TextEditingController();
  final TextEditingController _hargaController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  Future<List<JasaServis>> _loadJasa() async {
    final maps = await _db.query('jasa_servis');
    return maps.map((m) => JasaServis.fromMap(m)).toList();
  }

  Future<void> _refreshData() async {
    setState(() {});
  }

  double _parseHarga(String value) {
    final cleaned = value.trim().replaceAll(RegExp(r'[^0-9,\.-]'), '');
    if (cleaned.isEmpty) return 0;
    return double.tryParse(cleaned.replaceAll(',', '.')) ?? 0;
  }

  void _showForm({JasaServis? jasa}) {
    _namaJasaController.text = jasa?.namaJasa ?? '';
    _hargaController.text = jasa?.harga.toString() ?? '';
    final bool isEdit = jasa != null;

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
                  isEdit ? 'Edit Jasa Servis' : 'Tambah Jasa Servis',
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _namaJasaController,
                  decoration: const InputDecoration(
                      labelText: 'Nama Jasa', prefixIcon: Icon(Icons.build)),
                  validator: (v) => Validators.validateRequired(v, 'Nama Jasa'),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _hargaController,
                  decoration: const InputDecoration(
                      labelText: 'Harga (Rp)',
                      prefixIcon: Icon(Icons.attach_money)),
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  validator: (v) =>
                      Validators.validateNumber(v, 'Harga', min: 1),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () async {
                      if (_formKey.currentState?.validate() ?? false) {
                        final navigator = Navigator.of(context);
                        final messenger = ScaffoldMessenger.of(context);
                        final jasaData = JasaServis(
                          idJasa: jasa?.idJasa,
                          namaJasa: _namaJasaController.text.trim(),
                          harga: _parseHarga(_hargaController.text),
                        );
                        try {
                          if (isEdit) {
                            await _db.update('jasa_servis', jasaData.toMap(),
                                'id_jasa', jasa.idJasa!);
                          } else {
                            await _db.insert('jasa_servis', jasaData.toMap());
                          }
                          if (!mounted) return;
                          navigator.pop();
                          _refreshData();
                          messenger.showSnackBar(
                            SnackBar(
                              content: Text(isEdit
                                  ? 'Jasa berhasil diupdate'
                                  : 'Jasa berhasil ditambahkan'),
                              backgroundColor: AppColors.success,
                            ),
                          );
                        } catch (e) {
                          if (!mounted) return;
                          messenger.showSnackBar(
                            SnackBar(
                              content: Text(
                                  'Gagal menyimpan jasa: ${ApiService.friendlyError(e)}'),
                              backgroundColor: AppColors.error,
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

  void _confirmDelete(JasaServis jasa) {
    final messenger = ScaffoldMessenger.of(context);
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Hapus Jasa'),
        content: Text('Hapus jasa "${jasa.namaJasa}"?'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Batal')),
          ElevatedButton(
            onPressed: () async {
              final navigator = Navigator.of(dialogContext);
              try {
                await _db.delete('jasa_servis', 'id_jasa', jasa.idJasa!);
                if (!mounted) return;
                navigator.pop();
                _refreshData();
                messenger.showSnackBar(
                  const SnackBar(
                      content: Text('Jasa berhasil dihapus'),
                      backgroundColor: AppColors.error),
                );
              } catch (e) {
                if (!mounted) return;
                messenger.showSnackBar(
                  SnackBar(
                    content: Text(
                        'Gagal menghapus jasa: ${ApiService.friendlyError(e)}'),
                    backgroundColor: AppColors.error,
                  ),
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
    _namaJasaController.dispose();
    _hargaController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Jasa Servis')),
      body: FutureBuilder<List<JasaServis>>(
        future: _loadJasa(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                    'Gagal memuat jasa: ${ApiService.friendlyError(snapshot.error!)}'),
              ),
            );
          }
          final jasaList = snapshot.data ?? [];
          if (jasaList.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.build_outlined,
                      size: 64, color: AppColors.textSecondary),
                  SizedBox(height: 16),
                  Text('Belum ada data jasa servis',
                      style: TextStyle(
                          color: AppColors.textSecondary, fontSize: 16)),
                ],
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: jasaList.length,
            itemBuilder: (context, index) {
              final jasa = jasaList[index];
              return Dismissible(
                key: Key('jasa_${jasa.idJasa}'),
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
                  _confirmDelete(jasa);
                  return false;
                },
                child: Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                      child: const Icon(Icons.build, color: AppColors.primary),
                    ),
                    title: Text(jasa.namaJasa,
                        style: const TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: Text(
                      FormatHelper.formatCurrency(jasa.harga),
                      style: const TextStyle(
                          color: AppColors.success,
                          fontWeight: FontWeight.w500),
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.edit, color: AppColors.primary),
                      onPressed: () => _showForm(jasa: jasa),
                    ),
                    onTap: () => _showForm(jasa: jasa),
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
