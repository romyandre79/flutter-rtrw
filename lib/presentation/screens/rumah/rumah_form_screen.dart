import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:flutter_pos/core/theme/app_theme.dart';
import 'package:flutter_pos/data/models/rumah.dart';
import 'package:flutter_pos/logic/cubits/rumah/rumah_cubit.dart';
import 'package:flutter_pos/logic/cubits/rumah/rumah_state.dart';

class RumahFormScreen extends StatefulWidget {
  final Rumah? rumah;
  const RumahFormScreen({super.key, this.rumah});

  @override
  State<RumahFormScreen> createState() => _RumahFormScreenState();
}

class _RumahFormScreenState extends State<RumahFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nomorController = TextEditingController();
  final _blokController = TextEditingController();
  final _alamatController = TextEditingController();
  final _rtController = TextEditingController();
  final _rwController = TextEditingController();
  final _luasTanahController = TextEditingController();
  final _luasBangunanController = TextEditingController();
  final _catatanController = TextEditingController();

  String _statusKepemilikan = 'Milik Sendiri';
  String? _fotoPath;
  final _picker = ImagePicker();

  bool get _isEditing => widget.rumah != null;

  @override
  void initState() {
    super.initState();
    if (widget.rumah != null) {
      final r = widget.rumah!;
      _nomorController.text = r.nomorRumah;
      _blokController.text = r.blok ?? '';
      _alamatController.text = r.alamat ?? '';
      _rtController.text = r.rt ?? '';
      _rwController.text = r.rw ?? '';
      _luasTanahController.text = r.luasTanah?.toString() ?? '';
      _luasBangunanController.text = r.luasBangunan?.toString() ?? '';
      _catatanController.text = r.catatan ?? '';
      _statusKepemilikan = r.statusKepemilikan;
      _fotoPath = r.foto;
    }
  }

  @override
  void dispose() {
    _nomorController.dispose();
    _blokController.dispose();
    _alamatController.dispose();
    _rtController.dispose();
    _rwController.dispose();
    _luasTanahController.dispose();
    _luasBangunanController.dispose();
    _catatanController.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    final picked = await _picker.pickImage(source: ImageSource.gallery, maxWidth: 1200);
    if (picked == null) return;

    final appDir = await getApplicationDocumentsDirectory();
    final photosDir = Directory('${appDir.path}/photos/rumah');
    if (!await photosDir.exists()) await photosDir.create(recursive: true);

    final ext = p.extension(picked.path);
    final fileName = 'rumah_${DateTime.now().millisecondsSinceEpoch}$ext';
    final savedFile = await File(picked.path).copy('${photosDir.path}/$fileName');
    setState(() => _fotoPath = savedFile.path);
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;

    final rumah = Rumah(
      id: widget.rumah?.id,
      nomorRumah: _nomorController.text,
      blok: _blokController.text.isEmpty ? null : _blokController.text,
      alamat: _alamatController.text.isEmpty ? null : _alamatController.text,
      rt: _rtController.text.isEmpty ? null : _rtController.text,
      rw: _rwController.text.isEmpty ? null : _rwController.text,
      statusKepemilikan: _statusKepemilikan,
      luasTanah: double.tryParse(_luasTanahController.text),
      luasBangunan: double.tryParse(_luasBangunanController.text),
      foto: _fotoPath,
      catatan: _catatanController.text.isEmpty ? null : _catatanController.text,
    );

    context.read<RumahCubit>().save(rumah);
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<RumahCubit, RumahState>(
      listener: (context, state) {
        if (state is RumahSaved) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message), backgroundColor: AppThemeColors.success),
          );
          Navigator.pop(context);
        } else if (state is RumahError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message), backgroundColor: AppThemeColors.error),
          );
        }
      },
      child: Scaffold(
        backgroundColor: AppThemeColors.background,
        appBar: AppBar(
          title: Text(_isEditing ? 'Edit Rumah' : 'Tambah Rumah'),
          backgroundColor: AppThemeColors.primary,
          foregroundColor: Colors.white,
          actions: [
            if (_isEditing)
              IconButton(icon: const Icon(Icons.delete_outline), onPressed: _confirmDelete),
          ],
        ),
        body: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            children: [
              // Photo
              GestureDetector(
                onTap: _pickPhoto,
                child: Container(
                  height: 180,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppThemeColors.border, width: 2),
                    image: _fotoPath != null && File(_fotoPath!).existsSync()
                        ? DecorationImage(image: FileImage(File(_fotoPath!)), fit: BoxFit.cover)
                        : null,
                  ),
                  child: _fotoPath == null || !File(_fotoPath!).existsSync()
                      ? const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add_a_photo_outlined, size: 40, color: AppThemeColors.textSecondary),
                            SizedBox(height: 8),
                            Text('Tambah Foto Rumah', style: TextStyle(color: AppThemeColors.textSecondary)),
                          ],
                        )
                      : null,
                ),
              ),
              const SizedBox(height: AppSpacing.xl),

              _sectionTitle('Identitas Rumah'),
              const SizedBox(height: AppSpacing.md),
              _buildTextField(_nomorController, 'Nomor Rumah *',
                  validator: (v) => v == null || v.isEmpty ? 'Wajib diisi' : null),
              _buildTextField(_blokController, 'Blok / Cluster'),
              Row(
                children: [
                  Expanded(child: _buildTextField(_rtController, 'RT')),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(child: _buildTextField(_rwController, 'RW')),
                ],
              ),
              _buildTextField(_alamatController, 'Alamat Lengkap', maxLines: 2),

              const SizedBox(height: AppSpacing.xl),
              _sectionTitle('Detail'),
              const SizedBox(height: AppSpacing.md),
              _buildDropdown(),
              Row(
                children: [
                  Expanded(child: _buildTextField(_luasTanahController, 'Luas Tanah (m²)',
                      keyboardType: TextInputType.number)),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(child: _buildTextField(_luasBangunanController, 'Luas Bangunan (m²)',
                      keyboardType: TextInputType.number)),
                ],
              ),
              _buildTextField(_catatanController, 'Catatan', maxLines: 3),

              const SizedBox(height: AppSpacing.xxl),
              ElevatedButton(
                onPressed: _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppThemeColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Text(_isEditing ? 'Simpan Perubahan' : 'Simpan',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: AppSpacing.xl),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Text(title, style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.bold, color: AppThemeColors.primary));
  }

  Widget _buildTextField(TextEditingController controller, String label, {
    TextInputType? keyboardType, int maxLines = 1, String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        maxLines: maxLines,
        validator: validator,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }

  Widget _buildDropdown() {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: DropdownButtonFormField<String>(
        value: _statusKepemilikan,
        decoration: InputDecoration(
          labelText: 'Status Kepemilikan',
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
        items: const ['Milik Sendiri', 'Sewa', 'Kontrak', 'Lainnya']
            .map((e) => DropdownMenuItem(value: e, child: Text(e)))
            .toList(),
        onChanged: (v) => setState(() => _statusKepemilikan = v!),
      ),
    );
  }

  void _confirmDelete() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Hapus Rumah'),
        content: Text('Yakin ingin menghapus data ${widget.rumah!.displayName}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<RumahCubit>().delete(widget.rumah!.id!);
              Navigator.pop(context);
            },
            child: const Text('Hapus', style: TextStyle(color: AppThemeColors.error)),
          ),
        ],
      ),
    );
  }
}
