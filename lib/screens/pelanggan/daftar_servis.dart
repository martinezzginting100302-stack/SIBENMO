import 'package:flutter/material.dart';
import '../../utils/helpers.dart';
import '../../services/sibenmo_repository.dart';
import '../../models/kendaraan.dart';
import '../../models/mekanik.dart';
import '../../models/servis.dart';
import '../../models/jasa_servis.dart';
import '../../models/sparepart.dart';
import '../../models/detail_servis.dart';
import '../../models/detail_sparepart.dart';

class DaftarServis extends StatefulWidget {
  final int idPelanggan;

  const DaftarServis({super.key, required this.idPelanggan});

  @override
  State<DaftarServis> createState() => _DaftarServisState();
}

class _DaftarServisState extends State<DaftarServis> {
  final TextEditingController _keluhanController = TextEditingController();
  bool _isLoading = true;

  List<Kendaraan> _kendaraanList = [];
  List<Mekanik> _mekanikList = [];
  List<JasaServis> _jasaList = [];
  List<Sparepart> _sparepartList = [];

  int? _selectedIdKendaraan;
  int? _selectedIdMekanik;
  final Set<int> _selectedJasaIds = {};
  final Map<int, int> _sparepartQuantities = {};

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final repo = SibenmoRepository.instance;
      final kendaraanList =
          await repo.getKendaraanByPelanggan(widget.idPelanggan);
      kendaraanList.sort(
          (a, b) => (b.idKendaraan ?? 0).compareTo(a.idKendaraan ?? 0));
      final mekanikList = await repo.getAllMekanik();
      mekanikList.sort((a, b) => a.nama.compareTo(b.nama));
      final jasaList = await repo.getAllJasaServis();
      jasaList.sort((a, b) => a.namaJasa.compareTo(b.namaJasa));
      final sparepartList = await repo.getAllSparepart();
      sparepartList
          .sort((a, b) => a.namaSparepart.compareTo(b.namaSparepart));
      if (mounted) {
        setState(() {
          _kendaraanList = kendaraanList;
          _mekanikList = mekanikList;
          _jasaList = jasaList;
          _sparepartList = sparepartList;
          _selectedIdKendaraan = _kendaraanList.isNotEmpty
              ? _kendaraanList.first.idKendaraan
              : null;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  double get _estimatedTotal {
    double total = 0;
    for (final jasa in _jasaList) {
      if (_selectedJasaIds.contains(jasa.idJasa)) {
        total += jasa.harga;
      }
    }
    for (final entry in _sparepartQuantities.entries) {
      final sparepart = _sparepartList.firstWhere(
        (s) => s.idSparepart == entry.key,
      );
      total += sparepart.harga * entry.value;
    }
    return total;
  }

  void _incrementSparepart(int id) {
    setState(() {
      _sparepartQuantities.update(id, (v) => v + 1, ifAbsent: () => 1);
    });
  }

  void _decrementSparepart(int id) {
    setState(() {
      if (_sparepartQuantities[id] == 1) {
        _sparepartQuantities.remove(id);
      } else {
        _sparepartQuantities.update(id, (v) => v - 1);
      }
    });
  }

  void _showSnack(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: color),
    );
  }

  Future<void> _submit() async {
    if (_selectedIdKendaraan == null) {
      _showSnack('Silakan pilih kendaraan terlebih dahulu', AppColors.warning);
      return;
    }
    if (_selectedIdMekanik == null) {
      _showSnack('Silakan pilih mekanik terlebih dahulu', AppColors.warning);
      return;
    }
    if (_selectedJasaIds.isEmpty) {
      _showSnack('Silakan pilih minimal satu jasa servis', AppColors.warning);
      return;
    }

    try {
      final repo = SibenmoRepository.instance;
      final servis = Servis(
        idKendaraan: _selectedIdKendaraan!,
        idMekanik: _selectedIdMekanik!,
        tanggal: DateTime.now(),
        keluhan: _keluhanController.text.trim().isEmpty
            ? null
            : _keluhanController.text.trim(),
        status: 'Diterima',
      );
      final idServis = await repo.insertServis(servis);

      for (final jasa in _jasaList) {
        if (_selectedJasaIds.contains(jasa.idJasa)) {
          await repo.insertDetailServis(
            DetailServis(
              idServis: idServis,
              idJasa: jasa.idJasa!,
              harga: jasa.harga,
            ),
          );
        }
      }

      for (final entry in _sparepartQuantities.entries) {
        final sparepart = _sparepartList.firstWhere(
          (s) => s.idSparepart == entry.key,
        );
        await repo.insertDetailSparepart(
          DetailSparepart(
            idServis: idServis,
            idSparepart: entry.key,
            jumlah: entry.value,
            harga: sparepart.harga,
          ),
        );
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Servis berhasil diajukan'),
          backgroundColor: AppColors.success,
        ),
      );
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      _showSnack('Gagal mengajukan servis: $e', AppColors.error);
    }
  }

  @override
  void dispose() {
    _keluhanController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Ajukan Servis')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildSectionTitle('1. Pilih Kendaraan'),
                DropdownButtonFormField<int>(
                        initialValue: _selectedIdKendaraan,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Kendaraan',
                    prefixIcon: Icon(Icons.directions_car),
                    border: OutlineInputBorder(),
                  ),
                  items: _kendaraanList
                      .map((k) => DropdownMenuItem(
                                  value: k.idKendaraan,
                            child: Text(
                              '${k.noPolisi} - ${k.merk} ${k.tipe ?? ''}',
                              overflow: TextOverflow.ellipsis,
                            ),
                          ))
                      .toList(),
                  onChanged: (v) => setState(() => _selectedIdKendaraan = v),
                ),
                if (_kendaraanList.isEmpty)
                  const Padding(
                    padding: EdgeInsets.only(top: 8),
                    child: Text(
                      'Belum ada kendaraan. Silakan daftarkan kendaraan terlebih dahulu.',
                      style: TextStyle(color: AppColors.warning),
                    ),
                  ),
                const SizedBox(height: 24),

                _buildSectionTitle('2. Pilih Mekanik'),
                DropdownButtonFormField<int>(
                        initialValue: _selectedIdMekanik,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Mekanik',
                    prefixIcon: Icon(Icons.engineering),
                    border: OutlineInputBorder(),
                  ),
                  items: _mekanikList
                      .map((m) => DropdownMenuItem(
                                  value: m.idMekanik,
                            child: Text(m.nama, overflow: TextOverflow.ellipsis),
                          ))
                      .toList(),
                  onChanged: (v) => setState(() => _selectedIdMekanik = v),
                ),
                const SizedBox(height: 24),

                _buildSectionTitle('3. Keluhan'),
                TextFormField(
                  controller: _keluhanController,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    hintText: 'Deskripsikan keluhan kendaraan Anda',
                    alignLabelWithHint: true,
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 24),

                _buildSectionTitle('4. Pilih Jasa Servis'),
                if (_jasaList.isEmpty)
                  const Padding(
                    padding: EdgeInsets.only(bottom: 8),
                    child: Text(
                      'Belum ada jasa servis yang tersedia.',
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                  ),
                for (final jasa in _jasaList)
                  Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: CheckboxListTile(
                      value: _selectedJasaIds.contains(jasa.idJasa),
                      controlAffinity: ListTileControlAffinity.leading,
                      title: Text(
                        jasa.namaJasa,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      subtitle: Text(
                        FormatHelper.formatCurrency(jasa.harga),
                        style: const TextStyle(color: AppColors.success),
                      ),
                      secondary: const Icon(Icons.build, color: AppColors.primary),
                      onChanged: (val) {
                        setState(() {
                          if (val == true) {
                            _selectedJasaIds.add(jasa.idJasa!);
                          } else {
                            _selectedJasaIds.remove(jasa.idJasa);
                          }
                        });
                      },
                    ),
                  ),
                const SizedBox(height: 24),

                _buildSectionTitle('5. Sparepart (Opsional)'),
                if (_sparepartList.isEmpty)
                  const Padding(
                    padding: EdgeInsets.only(bottom: 8),
                    child: Text(
                      'Belum ada sparepart yang tersedia.',
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                  ),
                for (final sparepart in _sparepartList)
                  Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: const Icon(
                        Icons.inventory_2,
                        color: Colors.teal,
                      ),
                      title: Text(
                        sparepart.namaSparepart,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      subtitle: Text(
                        '${FormatHelper.formatCurrency(sparepart.harga)} / unit',
                        style: const TextStyle(color: AppColors.textSecondary),
                      ),
                      trailing: _sparepartQuantity(sparepart) == 0
                          ? IconButton(
                              icon: const Icon(
                                Icons.add_circle_outline,
                                color: AppColors.primary,
                              ),
                              onPressed: () =>
                                  _incrementSparepart(sparepart.idSparepart!),
                            )
                          : Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(
                                    Icons.remove_circle_outline,
                                    color: AppColors.error,
                                  ),
                                  onPressed: () => _decrementSparepart(
                                      sparepart.idSparepart!),
                                ),
                                Text(
                                  '${_sparepartQuantity(sparepart)}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(
                                    Icons.add_circle_outline,
                                    color: AppColors.primary,
                                  ),
                                  onPressed: () =>
                                      _incrementSparepart(sparepart.idSparepart!),
                                ),
                              ],
                            ),
                    ),
                  ),
                const SizedBox(height: 24),

                Card(
                  color: AppColors.primary.withValues(alpha: 0.05),
                  elevation: 2,
                  child: ListTile(
                    leading: const Icon(Icons.receipt, color: AppColors.primary),
                    title: const Text(
                      'Estimasi Total',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        FormatHelper.formatCurrency(_estimatedTotal),
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                SizedBox(
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _submit,
                    child: const Text(
                      'Submit Servis',
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  int _sparepartQuantity(Sparepart sparepart) {
    return _sparepartQuantities[sparepart.idSparepart] ?? 0;
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: AppColors.textPrimary,
        ),
      ),
    );
  }
}
