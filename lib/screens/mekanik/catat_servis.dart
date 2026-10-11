import 'package:flutter/material.dart';
import '../../utils/helpers.dart';
import '../../services/sibenmo_repository.dart';
import '../../models/jasa_servis.dart';
import '../../models/detail_servis.dart';

class CatatServis extends StatefulWidget {
  final int idServis;

  const CatatServis({Key? key, required this.idServis}) : super(key: key);

  @override
  State<CatatServis> createState() => _CatatServisState();
}

class _CatatServisState extends State<CatatServis> {
  final SibenmoRepository _db = SibenmoRepository.instance;
  List<JasaServis> _jasaList = [];
  final Set<int> _selected = {};
  Map<String, dynamic>? _servisInfo;
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final info = await _db.getServisWithDetails(widget.idServis);
      final jasaList = await _db.getAllJasaServis();
      final existing = await _db.getDetailServisByServis(widget.idServis);
      final selectedIds = existing
          .map((e) {
            final v = e['id_jasa'];
            return v is int ? v : int.tryParse('$v');
          })
          .whereType<int>()
          .toSet();
      if (!mounted) return;
      setState(() {
        _servisInfo = info;
        _jasaList = jasaList;
        _selected.addAll(selectedIds);
        _isLoading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _tambahJasaCustom() async {
    final result = await showDialog<JasaServis>(
      context: context,
      builder: (dialogContext) => const _CustomJasaDialog(),
    );
    if (result == null || !mounted) return;
    setState(() {
      _jasaList.add(result);
      _jasaList.sort(
        (a, b) => a.namaJasa.toLowerCase().compareTo(b.namaJasa.toLowerCase()),
      );
      _selected.add(result.idJasa!);
    });
  }

  Future<void> _simpanPekerjaan() async {
    if (_selected.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pilih minimal satu jasa servis'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      final existing = await _db.getDetailServisByServis(widget.idServis);
      for (final item in existing) {
        final raw = item['id_detail_servis'];
        final id = raw is int ? raw : int.tryParse('$raw');
        if (id != null) await _db.deleteDetailServis(id);
      }
      for (final idJasa in _selected) {
        final jasa = _jasaList.firstWhere((j) => j.idJasa == idJasa);
        await _db.insertDetailServis(
          DetailServis(
            idServis: widget.idServis,
            idJasa: idJasa,
            harga: jasa.harga,
          ),
        );
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pekerjaan servis berhasil disimpan'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Terjadi kesalahan: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Catat Pekerjaan Servis')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      _buildInfoServis(),
                      const SizedBox(height: 16),
                      _buildJasaSection(),
                    ],
                  ),
                ),
                SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                    child: _isSaving
                        ? const Center(child: CircularProgressIndicator())
                        : SizedBox(
                            width: double.infinity,
                            height: 48,
                            child: ElevatedButton.icon(
                              onPressed: _simpanPekerjaan,
                              icon: const Icon(Icons.save),
                              label: const Text('Simpan Pekerjaan'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                              ),
                            ),
                          ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildInfoServis() {
    final info = _servisInfo;
    if (info == null) return const SizedBox.shrink();
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${info['merk']} - ${info['no_polisi']}',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Pelanggan: ${info['nama_pelanggan']}',
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
            if (info['keluhan'] != null && (info['keluhan'] as String).trim().isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                'Keluhan: ${info['keluhan']}',
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildJasaSection() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Jasa Servis yang Dilakukan',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  TextButton.icon(
                    onPressed: _tambahJasaCustom,
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Tambah Jasa Custom'),
                  ),
                ],
              ),
            ),
            if (_jasaList.isEmpty)
              const Padding(
                padding: EdgeInsets.all(16),
                child: Center(
                  child: Text(
                    'Belum ada jasa servis tersedia',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                ),
              )
            else
              ..._jasaList.map(
                (jasa) => CheckboxListTile(
                  value: _selected.contains(jasa.idJasa),
                  onChanged: (checked) {
                    setState(() {
                      if (checked == true) {
                        _selected.add(jasa.idJasa!);
                      } else {
                        _selected.remove(jasa.idJasa);
                      }
                    });
                  },
                  title: Text(
                    jasa.namaJasa,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  subtitle: Text(
                    FormatHelper.formatCurrency(jasa.harga),
                    style: const TextStyle(
                      color: AppColors.success,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  controlAffinity: ListTileControlAffinity.leading,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _CustomJasaDialog extends StatefulWidget {
  const _CustomJasaDialog();

  @override
  State<_CustomJasaDialog> createState() => _CustomJasaDialogState();
}

class _CustomJasaDialogState extends State<_CustomJasaDialog> {
  final SibenmoRepository _db = SibenmoRepository.instance;
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _namaController = TextEditingController();
  final TextEditingController _hargaController = TextEditingController();
  bool _isSaving = false;

  @override
  void dispose() {
    _namaController.dispose();
    _hargaController.dispose();
    super.dispose();
  }

  Future<void> _simpan() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);
    try {
      final int idJasa = await _db.insertJasaServis(
        JasaServis(
          namaJasa: _namaController.text.trim(),
          harga: double.tryParse(_hargaController.text.trim()) ?? 0,
        ),
      );
      if (!mounted) return;
      Navigator.pop(
        context,
        JasaServis(
          idJasa: idJasa,
          namaJasa: _namaController.text.trim(),
          harga: double.tryParse(_hargaController.text.trim()) ?? 0,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal menambah jasa: $e'),
          backgroundColor: AppColors.error,
        ),
      );
      setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Tambah Jasa Custom'),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _namaController,
              decoration: const InputDecoration(
                labelText: 'Nama Jasa *',
                prefixIcon: Icon(Icons.build),
              ),
              validator: (value) =>
                  Validators.validateRequired(value, 'Nama Jasa'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _hargaController,
              decoration: const InputDecoration(
                labelText: 'Harga (Rp) *',
                prefixIcon: Icon(Icons.attach_money),
              ),
              keyboardType: TextInputType.number,
              validator: (value) =>
                  Validators.validateRequired(value, 'Harga'),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Batal'),
        ),
        ElevatedButton(
          onPressed: _isSaving ? null : _simpan,
          child: _isSaving
              ? const SizedBox(
                  height: 18,
                  width: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Simpan'),
        ),
      ],
    );
  }
}
