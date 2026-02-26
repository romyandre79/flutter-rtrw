import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:flutter_pos/core/theme/app_theme.dart';
import 'package:flutter_pos/data/models/warga.dart';
import 'package:flutter_pos/data/repositories/warga_repository.dart';
import 'package:flutter_pos/logic/cubits/warga/warga_cubit.dart';
import 'package:flutter_pos/logic/cubits/warga/warga_state.dart';

class WargaFormScreen extends StatefulWidget {
  final Warga? warga;
  final String? prefillNoKk;
  final String? prefillNamaWarga;
  const WargaFormScreen({super.key, this.warga, this.prefillNoKk, this.prefillNamaWarga});

  @override
  State<WargaFormScreen> createState() => _WargaFormScreenState();
}

class _WargaFormScreenState extends State<WargaFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nikController = TextEditingController();
  final _namaController = TextEditingController();
  final _tempatLahirController = TextEditingController();
  final _pekerjaanController = TextEditingController();
  final _pendidikanController = TextEditingController();
  final _noKkController = TextEditingController();
  final _noHpController = TextEditingController();
  final _alamatController = TextEditingController();
  final _rtController = TextEditingController();
  final _rwController = TextEditingController();
  final _catatanController = TextEditingController();

  DateTime? _tanggalLahir;
  JenisKelamin? _jenisKelamin;
  String? _agama;
  String? _statusPerkawinan;
  String? _statusKk;
  String? _kepemilikanRumah;
  StatusWarga _status = StatusWarga.aktif;

  String? _fotoKtpPath;
  String? _fotoKkPath;
  String? _fotoProfilPath;

  final _picker = ImagePicker();
  List<Warga> _keluarga = [];

  bool get _isEditing => widget.warga != null;
  bool get _isAddingFamily => widget.prefillNoKk != null && !_isEditing;

  @override
  void initState() {
    super.initState();
    if (widget.warga != null) {
      final w = widget.warga!;
      _nikController.text = w.nik ?? '';
      _namaController.text = w.nama;
      _tempatLahirController.text = w.tempatLahir ?? '';
      _pekerjaanController.text = w.pekerjaan ?? '';
      _pendidikanController.text = w.pendidikan ?? '';
      _noKkController.text = w.noKk ?? '';
      _noHpController.text = w.noHp ?? '';
      _alamatController.text = w.alamat ?? '';
      _rtController.text = w.rt ?? '';
      _rwController.text = w.rw ?? '';
      _catatanController.text = w.catatan ?? '';
      _tanggalLahir = w.tanggalLahir;
      _jenisKelamin = w.jenisKelamin;
      _agama = w.agama;
      _statusPerkawinan = w.statusPerkawinan;
      _statusKk = w.statusKk;
      _kepemilikanRumah = w.kepemilikanRumah;
      _status = w.status;
      _fotoKtpPath = w.fotoKtp;
      _fotoKkPath = w.fotoKk;
      _fotoProfilPath = w.fotoProfil;
    }
    // Pre-fill no_kk if provided (when adding family member)
    if (widget.prefillNoKk != null && _noKkController.text.isEmpty) {
      _noKkController.text = widget.prefillNoKk!;
    }
    _loadKeluarga();
  }

  Future<void> _loadKeluarga() async {
    final noKk = _noKkController.text;
    if (noKk.isEmpty) return;
    final repo = WargaRepository();
    final members = await repo.getKeluarga(noKk);
    // Exclude current warga from the list
    if (mounted) {
      setState(() {
        _keluarga = members.where((w) => w.id != widget.warga?.id).toList();
      });
    }
  }

  @override
  void dispose() {
    _nikController.dispose();
    _namaController.dispose();
    _tempatLahirController.dispose();
    _pekerjaanController.dispose();
    _pendidikanController.dispose();
    _noKkController.dispose();
    _noHpController.dispose();
    _alamatController.dispose();
    _rtController.dispose();
    _rwController.dispose();
    _catatanController.dispose();
    super.dispose();
  }

  Future<String?> _pickAndSaveImage(String prefix) async {
    final picked = await _picker.pickImage(source: ImageSource.gallery, maxWidth: 1200);
    if (picked == null) return null;

    final appDir = await getApplicationDocumentsDirectory();
    final photosDir = Directory('${appDir.path}/photos/warga');
    if (!await photosDir.exists()) await photosDir.create(recursive: true);

    final ext = p.extension(picked.path);
    final fileName = '${prefix}_${DateTime.now().millisecondsSinceEpoch}$ext';
    final savedFile = await File(picked.path).copy('${photosDir.path}/$fileName');
    return savedFile.path;
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;

    final warga = Warga(
      id: widget.warga?.id,
      nik: _nikController.text.isEmpty ? null : _nikController.text,
      nama: _namaController.text,
      tempatLahir: _tempatLahirController.text.isEmpty ? null : _tempatLahirController.text,
      tanggalLahir: _tanggalLahir,
      jenisKelamin: _jenisKelamin,
      agama: _agama,
      statusPerkawinan: _statusPerkawinan,
      pekerjaan: _pekerjaanController.text.isEmpty ? null : _pekerjaanController.text,
      pendidikan: _pendidikanController.text.isEmpty ? null : _pendidikanController.text,
      noKk: _noKkController.text.isEmpty ? null : _noKkController.text,
      statusKk: _statusKk,
      noHp: _noHpController.text.isEmpty ? null : _noHpController.text,
      alamat: _alamatController.text.isEmpty ? null : _alamatController.text,
      rt: _rtController.text.isEmpty ? null : _rtController.text,
      rw: _rwController.text.isEmpty ? null : _rwController.text,
      rumahId: widget.warga?.rumahId,
      kepemilikanRumah: _kepemilikanRumah,
      fotoKtp: _fotoKtpPath,
      fotoKk: _fotoKkPath,
      fotoProfil: _fotoProfilPath,
      status: _status,
      catatan: _catatanController.text.isEmpty ? null : _catatanController.text,
    );

    context.read<WargaCubit>().save(warga);
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<WargaCubit, WargaState>(
      listener: (context, state) {
        if (state is WargaSaved) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message), backgroundColor: AppThemeColors.success),
          );
          Navigator.pop(context);
        } else if (state is WargaError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message), backgroundColor: AppThemeColors.error),
          );
        }
      },
      child: Scaffold(
        backgroundColor: AppThemeColors.background,
        appBar: AppBar(
          title: Text(_isAddingFamily
              ? 'Anggota Keluarga ${widget.prefillNamaWarga ?? ""}'
              : _isEditing ? 'Edit Warga' : 'Tambah Warga'),
          backgroundColor: AppThemeColors.primary,
          foregroundColor: Colors.white,
          actions: [
            if (_isEditing)
              IconButton(
                icon: const Icon(Icons.delete_outline),
                onPressed: _confirmDelete,
              ),
          ],
        ),
        body: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            children: [
              // Photo section
              _buildPhotoSection(),
              const SizedBox(height: AppSpacing.xl),

              // Identity section
              _sectionTitle('Data Identitas'),
              const SizedBox(height: AppSpacing.md),
              _buildTextField(_nikController, 'NIK (16 digit)', keyboardType: TextInputType.number, maxLength: 16),
              _buildTextField(_namaController, 'Nama Lengkap *', validator: (v) => v == null || v.isEmpty ? 'Wajib diisi' : null),
              Row(
                children: [
                  Expanded(child: _buildTextField(_tempatLahirController, 'Tempat Lahir')),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(child: _buildDateField()),
                ],
              ),
              _buildDropdown<JenisKelamin>(
                'Jenis Kelamin',
                _jenisKelamin,
                JenisKelamin.values,
                (v) => v == JenisKelamin.L ? 'Laki-laki' : 'Perempuan',
                (v) => setState(() => _jenisKelamin = v),
              ),
              _buildDropdown<String>(
                'Agama',
                _agama,
                const ['Islam', 'Kristen', 'Katolik', 'Hindu', 'Budha', 'Konghucu'],
                (v) => v,
                (v) => setState(() => _agama = v),
              ),
              _buildDropdown<String>(
                'Status Perkawinan',
                _statusPerkawinan,
                const ['Belum Kawin', 'Kawin', 'Cerai Hidup', 'Cerai Mati'],
                (v) => v,
                (v) => setState(() => _statusPerkawinan = v),
              ),
              _buildTextField(_pekerjaanController, 'Pekerjaan'),
              _buildDropdown<String>(
                'Pendidikan Terakhir',
                _pendidikanController.text.isEmpty ? null : _pendidikanController.text,
                const ['Tidak/Belum Sekolah', 'SD/Sederajat', 'SMP/Sederajat', 'SMA/Sederajat', 'D1', 'D2', 'D3', 'S1', 'S2', 'S3'],
                (v) => v,
                (v) => setState(() => _pendidikanController.text = v ?? ''),
              ),

              const SizedBox(height: AppSpacing.xl),
              _sectionTitle('Data Keluarga'),
              const SizedBox(height: AppSpacing.md),
              _buildTextField(
                _noKkController,
                'No. Kartu Keluarga',
                keyboardType: TextInputType.number,
                maxLength: 16,
                readOnly: _isAddingFamily,
              ),
              _buildDropdown<String>(
                'Status dalam KK',
                _statusKk,
                const ['Kepala Keluarga', 'Istri', 'Anak', 'Lainnya'],
                (v) => v,
                (v) => setState(() => _statusKk = v),
              ),
              // Family members section
              if (_isEditing && _noKkController.text.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.md),
                _buildKeluargaSection(),
              ],

              const SizedBox(height: AppSpacing.xl),
              _sectionTitle('Kontak & Alamat'),
              const SizedBox(height: AppSpacing.md),
              _buildTextField(_noHpController, 'No. HP', keyboardType: TextInputType.phone),
              if (!_isAddingFamily) ...[
                _buildTextField(_alamatController, 'Alamat', maxLines: 2),
                Row(
                  children: [
                    Expanded(child: _buildTextField(_rtController, 'RT')),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(child: _buildTextField(_rwController, 'RW')),
                  ],
                ),
                _buildDropdown<String>(
                  'Kepemilikan Rumah',
                  _kepemilikanRumah,
                  const ['Milik Sendiri', 'Sewa/Kontrak', 'Numpang', 'Dinas', 'Lainnya'],
                  (v) => v,
                  (v) => setState(() => _kepemilikanRumah = v),
                ),
              ],

              const SizedBox(height: AppSpacing.xl),
              _sectionTitle('Status & Catatan'),
              const SizedBox(height: AppSpacing.md),
              _buildDropdown<StatusWarga>(
                'Status Warga',
                _status,
                StatusWarga.values,
                (v) {
                  switch (v) {
                    case StatusWarga.aktif: return 'Aktif';
                    case StatusWarga.pindah: return 'Pindah';
                    case StatusWarga.meninggal: return 'Meninggal';
                  }
                },
                (v) => setState(() => _status = v!),
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
                child: Text(_isEditing ? 'Simpan Perubahan' : 'Simpan', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: AppSpacing.xl),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPhotoSection() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildPhotoTile('Foto Profil', _fotoProfilPath, () async {
          final path = await _pickAndSaveImage('profil');
          if (path != null) setState(() => _fotoProfilPath = path);
        }),
        _buildPhotoTile('Foto KTP', _fotoKtpPath, () async {
          final path = await _pickAndSaveImage('ktp');
          if (path != null) setState(() => _fotoKtpPath = path);
        }),
        if (!_isAddingFamily)
          _buildPhotoTile('Foto KK', _fotoKkPath, () async {
            final path = await _pickAndSaveImage('kk');
            if (path != null) setState(() => _fotoKkPath = path);
          }),
      ],
    );
  }

  Widget _buildPhotoTile(String label, String? path, VoidCallback onTap) {
    final hasPhoto = path != null && File(path).existsSync();
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 90,
            height: 90,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppThemeColors.border, width: 2),
              image: hasPhoto
                  ? DecorationImage(image: FileImage(File(path!)), fit: BoxFit.cover)
                  : null,
            ),
            child: !hasPhoto
                ? const Icon(Icons.add_a_photo_outlined, size: 32, color: AppThemeColors.textSecondary)
                : null,
          ),
          const SizedBox(height: 6),
          Text(label, style: AppTypography.labelSmall.copyWith(color: AppThemeColors.textSecondary)),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Text(title, style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.bold, color: AppThemeColors.primary));
  }

  Widget _buildTextField(TextEditingController controller, String label, {
    TextInputType? keyboardType,
    int? maxLength,
    int maxLines = 1,
    bool readOnly = false,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        maxLength: maxLength,
        maxLines: maxLines,
        readOnly: readOnly,
        validator: validator,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          counterText: '',
        ),
      ),
    );
  }

  Widget _buildDropdown<T>(String label, T? value, List<T> items, String Function(T) display, ValueChanged<T?> onChanged) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: DropdownButtonFormField<T>(
        value: value,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
        items: items.map((e) => DropdownMenuItem(value: e, child: Text(display(e)))).toList(),
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildDateField() {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: GestureDetector(
        onTap: () async {
          final picked = await showDatePicker(
            context: context,
            initialDate: _tanggalLahir ?? DateTime(2000),
            firstDate: DateTime(1900),
            lastDate: DateTime.now(),
          );
          if (picked != null) setState(() => _tanggalLahir = picked);
        },
        child: AbsorbPointer(
          child: TextFormField(
            decoration: InputDecoration(
              labelText: 'Tanggal Lahir',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              suffixIcon: const Icon(Icons.calendar_today, size: 18),
            ),
            controller: TextEditingController(
              text: _tanggalLahir != null
                  ? '${_tanggalLahir!.day}/${_tanggalLahir!.month}/${_tanggalLahir!.year}'
                  : '',
            ),
          ),
        ),
      ),
    );
  }

  void _confirmDelete() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Hapus Warga'),
        content: Text('Yakin ingin menghapus data ${widget.warga!.nama}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<WargaCubit>().delete(widget.warga!.id!);
              Navigator.pop(context);
            },
            child: const Text('Hapus', style: TextStyle(color: AppThemeColors.error)),
          ),
        ],
      ),
    );
  }

  Widget _buildKeluargaSection() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppThemeColors.primarySurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppThemeColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Anggota Keluarga (${_keluarga.length})',
                style: AppTypography.labelLarge.copyWith(fontWeight: FontWeight.bold, color: AppThemeColors.primary),
              ),
              TextButton.icon(
                onPressed: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => BlocProvider(
                        create: (_) => WargaCubit(),
                        child: WargaFormScreen(
                          prefillNoKk: _noKkController.text,
                          prefillNamaWarga: widget.warga?.nama,
                        ),
                      ),
                    ),
                  );
                  _loadKeluarga();
                },
                icon: const Icon(Icons.person_add, size: 18),
                label: const Text('Tambah'),
                style: TextButton.styleFrom(foregroundColor: AppThemeColors.primary),
              ),
            ],
          ),
          if (_keluarga.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
              child: Text(
                'Belum ada anggota keluarga lain',
                style: AppTypography.bodySmall.copyWith(color: AppThemeColors.textSecondary),
              ),
            )
          else
            ..._keluarga.map((w) => ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              leading: CircleAvatar(
                radius: 16,
                backgroundColor: AppThemeColors.primary,
                child: Text(w.nama[0], style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
              ),
              title: Text(w.nama, style: AppTypography.bodyMedium),
              subtitle: Text(w.statusKk ?? '-', style: AppTypography.bodySmall.copyWith(color: AppThemeColors.textSecondary)),
              trailing: Text(w.jenisKelaminDisplay, style: AppTypography.labelSmall),
              onTap: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => BlocProvider(
                      create: (_) => WargaCubit(),
                      child: WargaFormScreen(warga: w),
                    ),
                  ),
                );
                _loadKeluarga();
              },
            )),
        ],
      ),
    );
  }
}
