import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_pos/core/theme/app_theme.dart';
import 'package:flutter_pos/data/models/pengeluaran.dart';
import 'package:flutter_pos/logic/cubits/pengeluaran/pengeluaran_cubit.dart';
import 'package:flutter_pos/logic/cubits/pengeluaran/pengeluaran_state.dart';
import 'package:flutter_pos/core/utils/date_formatter.dart';

class PengeluaranFormScreen extends StatefulWidget {
  final Pengeluaran? pengeluaran;
  const PengeluaranFormScreen({super.key, this.pengeluaran});

  @override
  State<PengeluaranFormScreen> createState() => _PengeluaranFormScreenState();
}

class _PengeluaranFormScreenState extends State<PengeluaranFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _jumlahController = TextEditingController();
  final _keteranganController = TextEditingController();

  String _kategori = Pengeluaran.kategoriList.first;
  String _tanggal = '';

  bool get _isEditing => widget.pengeluaran != null;

  @override
  void initState() {
    super.initState();
    if (widget.pengeluaran != null) {
      final p = widget.pengeluaran!;
      _kategori = p.kategori;
      _jumlahController.text = p.jumlah.toStringAsFixed(0);
      _keteranganController.text = p.keterangan ?? '';
      _tanggal = p.tanggal;
    } else {
      final now = DateTime.now();
      _tanggal = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    }
  }

  @override
  void dispose() {
    _jumlahController.dispose();
    _keteranganController.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;

    final pengeluaran = Pengeluaran(
      id: widget.pengeluaran?.id,
      kategori: _kategori,
      keterangan: _keteranganController.text.isEmpty ? null : _keteranganController.text,
      jumlah: double.tryParse(_jumlahController.text) ?? 0,
      tanggal: _tanggal,
    );

    context.read<PengeluaranCubit>().save(pengeluaran);
  }

  Future<void> _pickTanggal() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.tryParse(_tanggal) ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        _tanggal = '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<PengeluaranCubit, PengeluaranState>(
      listener: (context, state) {
        if (state is PengeluaranSaved) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message), backgroundColor: AppThemeColors.success),
          );
          Navigator.pop(context);
        } else if (state is PengeluaranError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message), backgroundColor: AppThemeColors.error),
          );
        }
      },
      child: Scaffold(
        backgroundColor: AppThemeColors.background,
        appBar: AppBar(
          title: Text(_isEditing ? 'Edit Pengeluaran' : 'Tambah Pengeluaran'),
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
              _sectionTitle('Kategori'),
              const SizedBox(height: AppSpacing.md),
              _buildKategoriDropdown(),

              _sectionTitle('Detail'),
              const SizedBox(height: AppSpacing.md),
              _buildTextField(_jumlahController, 'Jumlah (Rp) *',
                  keyboardType: TextInputType.number,
                  validator: (v) => v == null || v.isEmpty ? 'Wajib diisi' : null),
              _buildTextField(_keteranganController, 'Keterangan', maxLines: 3),

              // Date picker
              InkWell(
                onTap: _pickTanggal,
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
                      Text('Tanggal: ${DateFormatter.formatDate(DateTime.tryParse(_tanggal) ?? DateTime.now())}', style: AppTypography.bodyMedium),
                    ],
                  ),
                ),
              ),

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

  Widget _buildKategoriDropdown() {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: DropdownButtonFormField<String>(
        value: _kategori,
        decoration: InputDecoration(
          labelText: 'Kategori',
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
        items: Pengeluaran.kategoriList
            .map((e) => DropdownMenuItem(value: e, child: Text(e)))
            .toList(),
        onChanged: (v) => setState(() => _kategori = v!),
      ),
    );
  }

  void _confirmDelete() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Hapus Pengeluaran'),
        content: const Text('Yakin ingin menghapus data pengeluaran ini?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<PengeluaranCubit>().delete(widget.pengeluaran!.id!);
              Navigator.pop(context);
            },
            child: const Text('Hapus', style: TextStyle(color: AppThemeColors.error)),
          ),
        ],
      ),
    );
  }
}
