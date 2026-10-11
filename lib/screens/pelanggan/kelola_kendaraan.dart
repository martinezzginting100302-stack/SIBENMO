import 'package:flutter/material.dart';
import '../../utils/helpers.dart';
import '../../services/sibenmo_repository.dart';
import '../../models/kendaraan.dart';

class KelolaKendaraan extends StatefulWidget {
  final int idPelanggan;

  const KelolaKendaraan({super.key, required this.idPelanggan});

  @override
  State<KelolaKendaraan> createState() => _KelolaKendaraanState();
}

class _KelolaKendaraanState extends State<KelolaKendaraan> {
  final TextEditingController _noPolisiController = TextEditingController();
  final TextEditingController _merkController = TextEditingController();
  final TextEditingController _tipeController = TextEditingController();
  final TextEditingController _tahunController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  Future<List<Kendaraan>> _loadKendaraan() async {
    final list = await SibenmoRepository.instance
        .getKendaraanByPelanggan(widget.idPelanggan);
    list.sort((a, b) => (b.idKendaraan ?? 0).compareTo(a.idKendaraan ?? 0));
    return list;
  }

  void _refreshData() {
    setState(() {});
  }

  void _showForm({Kendaraan? kendaraan}) {
    _noPolisiController.text = kendaraan?.noPolisi ?? '';
    _merkController.text = kendaraan?.merk ?? '';
    _tipeController.text = kendaraan?.tipe ?? '';
    _tahunController.text = kendaraan?.tahun?.toString() ?? '';
    final bool isEdit = kendaraan != null;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isEdit ? 'Edit Kendaraan' : 'Tambah Kendaraan'),
        content: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _noPolisiController,
                  decoration: const InputDecoration(
                    labelText: 'No. Polisi',
                    prefixIcon: Icon(Icons.directions_car),
                  ),
                  validator: (v) => Validators.validateRequired(v, 'No. Polisi'),
                  textCapitalization: TextCapitalization.characters,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _merkController,
                  decoration: const InputDecoration(
                    labelText: 'Merk',
                    prefixIcon: Icon(Icons.branding_watermark),
                  ),
                  validator: (v) => Validators.validateRequired(v, 'Merk'),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _tipeController,
                  decoration: const InputDecoration(
                    labelText: 'Tipe',
                    prefixIcon: Icon(Icons.category),
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _tahunController,
                  decoration: const InputDecoration(
                    labelText: 'Tahun',
                    prefixIcon: Icon(Icons.calendar_today),
                  ),
                  keyboardType: TextInputType.number,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (_formKey.currentState!.validate()) {
                final kendaraanData = Kendaraan(
                  idKendaraan: kendaraan?.idKendaraan,
                  idPelanggan: widget.idPelanggan,
                  noPolisi: _noPolisiController.text.trim(),
                  merk: _merkController.text.trim(),
                  tipe: _tipeController.text.trim().isEmpty
                      ? null
                      : _tipeController.text.trim(),
                  tahun: int.tryParse(_tahunController.text.trim()),
                );
                final repo = SibenmoRepository.instance;
                if (isEdit) {
                  await repo.updateKendaraan(kendaraanData);
                } else {
                  await repo.insertKendaraan(kendaraanData);
                }
                if (mounted) {
                  Navigator.pop(context);
                  _refreshData();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(isEdit
                          ? 'Kendaraan berhasil diupdate'
                          : 'Kendaraan berhasil ditambahkan'),
                      backgroundColor: AppColors.success,
                    ),
                  );
                }
              }
            },
            child: Text(isEdit ? 'Update' : 'Simpan'),
          ),
        ],
      ),
    );
  }

  Future<bool> _confirmDelete(Kendaraan kendaraan) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Kendaraan'),
        content: Text(
          'Hapus data kendaraan "${kendaraan.noPolisi}"?',
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (result != true) return false;

    await SibenmoRepository.instance.deleteKendaraan(kendaraan.idKendaraan!);
    if (mounted) {
      _refreshData();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Kendaraan berhasil dihapus'),
          backgroundColor: AppColors.error,
        ),
      );
    }
    return true;
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
      appBar: AppBar(title: const Text('Kendaraan Saya')),
      body: FutureBuilder<List<Kendaraan>>(
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
                  Icon(
                    Icons.directions_car_outlined,
                    size: 64,
                    color: AppColors.textSecondary,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Belum ada kendaraan terdaftar',
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 16),
                  ),
                ],
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: kendaraanList.length,
            itemBuilder: (context, index) {
              final kendaraan = kendaraanList[index];
              return Dismissible(
                key: Key('kendaraan_${kendaraan.idKendaraan}'),
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
                confirmDismiss: (_) => _confirmDelete(kendaraan),
                child: Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: AppColors.success.withValues(alpha: 0.1),
                      child: const Icon(
                        Icons.directions_car,
                        color: AppColors.success,
                      ),
                    ),
                    title: Text(
                      kendaraan.noPolisi,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        Text(
                          kendaraan.tipe == null
                              ? kendaraan.merk
                              : '${kendaraan.merk} ${kendaraan.tipe}',
                          style: const TextStyle(color: AppColors.textSecondary),
                        ),
                        if (kendaraan.tahun != null)
                          Row(
                            children: [
                              const Icon(
                                Icons.calendar_today,
                                size: 14,
                                color: AppColors.textSecondary,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Tahun: ${kendaraan.tahun}',
                                style: const TextStyle(color: AppColors.textSecondary),
                              ),
                            ],
                          ),
                      ],
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.edit, color: AppColors.primary),
                      onPressed: () => _showForm(kendaraan: kendaraan),
                    ),
                    onTap: () => _showForm(kendaraan: kendaraan),
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
