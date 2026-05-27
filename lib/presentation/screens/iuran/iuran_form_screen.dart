import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_pos/core/theme/app_theme.dart';
import 'package:flutter_pos/data/models/iuran.dart';
import 'package:flutter_pos/data/models/warga.dart';
import 'package:flutter_pos/data/repositories/warga_repository.dart';
import 'package:flutter_pos/data/repositories/settings_repository.dart';
import 'package:flutter_pos/core/constants/app_constants.dart';
import 'package:flutter_pos/core/utils/date_formatter.dart';
import 'package:flutter_pos/logic/cubits/iuran/iuran_cubit.dart';
import 'package:flutter_pos/logic/cubits/iuran/iuran_state.dart';
import 'package:flutter_pos/presentation/widgets/searchable_warga_picker.dart';

class IuranFormScreen extends StatefulWidget {
  final Iuran? iuran;
  const IuranFormScreen({super.key, this.iuran});

  @override
  State<IuranFormScreen> createState() => _IuranFormScreenState();
}

class _IuranFormScreenState extends State<IuranFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _jumlahController = TextEditingController();
  final _keteranganController = TextEditingController();
  final _periodeController = TextEditingController();

  String _jenis = 'bulanan';
  int? _selectedWargaId;
  String? _selectedWargaNama;
  String? _tanggalBayar;
  double _defaultIuranBulanan = 0;

  final _wargaRepo = WargaRepository();
  final _settingsRepo = SettingsRepository();

  bool get _isEditing => widget.iuran != null;

  @override
  void initState() {
    super.initState();
    _loadSettings();

    if (widget.iuran != null) {
      final i = widget.iuran!;
      _jenis = i.jenis;
      _jumlahController.text = i.jumlah.toStringAsFixed(0);
      _keteranganController.text = i.keterangan ?? '';
      _periodeController.text = i.periode ?? '';
      _selectedWargaId = i.wargaId;
      _selectedWargaNama = i.wargaNama;
      _tanggalBayar = i.tanggalBayar;
    } else {
      // Default period: current month
      final now = DateTime.now();
      const months = ['Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni', 'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'];
      _periodeController.text = '${months[now.month - 1]} ${now.year}';
      _tanggalBayar = now.toIso8601String();
    }
  }

  Future<void> _loadSettings() async {
    final val = await _settingsRepo.getSetting(AppConstants.keyIuranBulanan);
    if (val != null) {
      _defaultIuranBulanan = double.tryParse(val) ?? 0;
      if (!mounted) return;
      if (!_isEditing && _jenis == 'bulanan' && _jumlahController.text.isEmpty) {
        setState(() {
          _jumlahController.text = _defaultIuranBulanan.toStringAsFixed(0);
        });
      }
    }
  }

  @override
  void dispose() {
    _jumlahController.dispose();
    _keteranganController.dispose();
    _periodeController.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;

    final iuran = Iuran(
      id: widget.iuran?.id,
      wargaId: _selectedWargaId,
      jenis: _jenis,
      keterangan: _keteranganController.text.isEmpty ? null : _keteranganController.text,
      jumlah: double.tryParse(_jumlahController.text) ?? 0,
      periode: _periodeController.text.isEmpty ? null : _periodeController.text,
      tanggalBayar: _tanggalBayar,
      statusBayar: _tanggalBayar != null ? 'lunas' : 'belum_bayar',
    );

    context.read<IuranCubit>().save(iuran);
  }



  Future<void> _pickTanggalBayar() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _tanggalBayar != null ? DateTime.tryParse(_tanggalBayar!) ?? DateTime.now() : DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        _tanggalBayar = picked.toIso8601String();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<IuranCubit, IuranState>(
      listener: (context, state) {
        if (state is IuranSaved) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message), backgroundColor: AppThemeColors.success),
          );
          Navigator.pop(context);
        } else if (state is IuranError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message), backgroundColor: AppThemeColors.error),
          );
        }
      },
      child: Scaffold(
        backgroundColor: AppThemeColors.background,
        appBar: AppBar(
          title: Text(_isEditing ? 'Edit Iuran' : 'Tambah Iuran'),
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
              SearchableWargaPicker(
                selectedWarga: _selectedWargaId != null 
                    ? Warga(id: _selectedWargaId, nama: _selectedWargaNama ?? '') 
                    : null,
                onWargaSelected: (warga) {
                  setState(() {
                    _selectedWargaId = warga?.id;
                    _selectedWargaNama = warga?.nama;
                  });
                },
                label: 'Pilih Warga',
                hint: 'Cari nama warga...',
              ),

              const SizedBox(height: AppSpacing.xl),
              _sectionTitle('Detail Iuran'),
              const SizedBox(height: AppSpacing.md),
              _buildJenisDropdown(),
              _buildTextField(_jumlahController, 'Jumlah (Rp) *',
                  keyboardType: TextInputType.number,
                  validator: (v) => v == null || v.isEmpty ? 'Wajib diisi' : null),
              _buildTextField(_periodeController, 'Periode (contoh: Februari 2026)'),
              const SizedBox(height: AppSpacing.sm),
              InkWell(
                onTap: _pickTanggalBayar,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border.all(color: AppThemeColors.border),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today, color: AppThemeColors.primary),
                      const SizedBox(width: 12),
                      Text(
                        _tanggalBayar != null
                            ? 'Tgl Bayar: ${DateFormatter.formatDate(DateTime.tryParse(_tanggalBayar!) ?? DateTime.now())}'
                            : 'Pilih Tanggal Bayar',
                        style: AppTypography.bodyMedium,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              _buildTextField(_keteranganController, 'Keterangan', maxLines: 2),

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

  Widget _buildPicker({required IconData icon, required String label, required bool hasValue, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: AppThemeColors.border),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: AppThemeColors.primarySurface,
              child: Icon(icon, color: AppThemeColors.primary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: AppTypography.bodyMedium.copyWith(
                  color: hasValue ? AppThemeColors.textPrimary : AppThemeColors.textSecondary,
                ),
              ),
            ),
            const Icon(Icons.chevron_right, color: AppThemeColors.textSecondary),
          ],
        ),
      ),
    );
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

  Widget _buildJenisDropdown() {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: DropdownButtonFormField<String>(
        value: _jenis,
        decoration: InputDecoration(
          labelText: 'Jenis Iuran',
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
        items: const [
          DropdownMenuItem(value: 'bulanan', child: Text('Bulanan')),
          DropdownMenuItem(value: 'tahunan', child: Text('Tahunan')),
          DropdownMenuItem(value: 'insidentil', child: Text('Insidentil')),
        ],
        onChanged: (v) {
          setState(() {
            _jenis = v!;
            if (!_isEditing && _jenis == 'bulanan') {
              // Autofill nominal for bulanan
              _jumlahController.text = _defaultIuranBulanan.toStringAsFixed(0);
            }
          });
        },
      ),
    );
  }


  void _confirmDelete() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Hapus Iuran'),
        content: const Text('Yakin ingin menghapus data iuran ini?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<IuranCubit>().delete(widget.iuran!.id!);
              Navigator.pop(context);
            },
            child: const Text('Hapus', style: TextStyle(color: AppThemeColors.error)),
          ),
        ],
      ),
    );
  }
}
