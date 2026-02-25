import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_pos/core/theme/app_theme.dart';
import 'package:flutter_pos/data/models/pengurus.dart';
import 'package:flutter_pos/data/models/warga.dart';
import 'package:flutter_pos/data/repositories/warga_repository.dart';
import 'package:flutter_pos/logic/cubits/pengurus/pengurus_cubit.dart';
import 'package:flutter_pos/logic/cubits/pengurus/pengurus_state.dart';

class PengurusFormScreen extends StatefulWidget {
  final Pengurus? pengurus;
  const PengurusFormScreen({super.key, this.pengurus});

  @override
  State<PengurusFormScreen> createState() => _PengurusFormScreenState();
}

class _PengurusFormScreenState extends State<PengurusFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _periodeMulaiController = TextEditingController();
  final _periodeSelesaiController = TextEditingController();
  final _catatanController = TextEditingController();

  String _jabatan = 'Ketua RT';
  String _status = 'aktif';
  int? _selectedWargaId;
  String? _selectedWargaNama;

  final _wargaRepo = WargaRepository();

  bool get _isEditing => widget.pengurus != null;

  @override
  void initState() {
    super.initState();
    if (widget.pengurus != null) {
      final p = widget.pengurus!;
      _jabatan = p.jabatan;
      _periodeMulaiController.text = p.periodeMulai ?? '';
      _periodeSelesaiController.text = p.periodeSelesai ?? '';
      _catatanController.text = p.catatan ?? '';
      _status = p.status;
      _selectedWargaId = p.wargaId;
      _selectedWargaNama = p.wargaNama;
    }
  }

  @override
  void dispose() {
    _periodeMulaiController.dispose();
    _periodeSelesaiController.dispose();
    _catatanController.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;

    final pengurus = Pengurus(
      id: widget.pengurus?.id,
      wargaId: _selectedWargaId,
      jabatan: _jabatan,
      periodeMulai: _periodeMulaiController.text.isEmpty ? null : _periodeMulaiController.text,
      periodeSelesai: _periodeSelesaiController.text.isEmpty ? null : _periodeSelesaiController.text,
      status: _status,
      catatan: _catatanController.text.isEmpty ? null : _catatanController.text,
    );

    context.read<PengurusCubit>().save(pengurus);
  }

  Future<void> _pickWarga() async {
    final wargaList = await _wargaRepo.getAll(status: 'aktif');
    if (!mounted) return;

    final selected = await showDialog<Warga>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Pilih Warga'),
        content: SizedBox(
          width: double.maxFinite,
          height: 400,
          child: wargaList.isEmpty
              ? const Center(child: Text('Belum ada data warga'))
              : ListView.builder(
                  itemCount: wargaList.length,
                  itemBuilder: (context, index) {
                    final w = wargaList[index];
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: AppThemeColors.primarySurface,
                        child: Text(w.nama[0], style: const TextStyle(color: AppThemeColors.primary)),
                      ),
                      title: Text(w.nama),
                      subtitle: w.nik != null ? Text('NIK: ${w.nik}') : null,
                      selected: w.id == _selectedWargaId,
                      onTap: () => Navigator.pop(context, w),
                    );
                  },
                ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
        ],
      ),
    );

    if (selected != null) {
      setState(() {
        _selectedWargaId = selected.id;
        _selectedWargaNama = selected.nama;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<PengurusCubit, PengurusState>(
      listener: (context, state) {
        if (state is PengurusSaved) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message), backgroundColor: AppThemeColors.success),
          );
          Navigator.pop(context);
        } else if (state is PengurusError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message), backgroundColor: AppThemeColors.error),
          );
        }
      },
      child: Scaffold(
        backgroundColor: AppThemeColors.background,
        appBar: AppBar(
          title: Text(_isEditing ? 'Edit Pengurus' : 'Tambah Pengurus'),
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
              // Warga picker
              _sectionTitle('Data Warga'),
              const SizedBox(height: AppSpacing.md),
              InkWell(
                onTap: _pickWarga,
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
                        child: Icon(
                          _selectedWargaId != null ? Icons.person : Icons.person_add,
                          color: AppThemeColors.primary,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _selectedWargaNama ?? 'Pilih Warga',
                          style: AppTypography.bodyMedium.copyWith(
                            color: _selectedWargaId != null
                                ? AppThemeColors.textPrimary
                                : AppThemeColors.textSecondary,
                          ),
                        ),
                      ),
                      const Icon(Icons.chevron_right, color: AppThemeColors.textSecondary),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: AppSpacing.xl),
              _sectionTitle('Jabatan'),
              const SizedBox(height: AppSpacing.md),
              _buildJabatanDropdown(),
              Row(
                children: [
                  Expanded(child: _buildTextField(_periodeMulaiController, 'Periode Mulai (tahun)')),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(child: _buildTextField(_periodeSelesaiController, 'Periode Selesai (tahun)')),
                ],
              ),
              _buildStatusDropdown(),
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

  Widget _buildTextField(TextEditingController controller, String label, {int maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }

  Widget _buildJabatanDropdown() {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: DropdownButtonFormField<String>(
        value: _jabatan,
        decoration: InputDecoration(
          labelText: 'Jabatan',
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
        items: const ['Ketua RT', 'Wakil Ketua', 'Sekretaris', 'Bendahara', 'Anggota']
            .map((e) => DropdownMenuItem(value: e, child: Text(e)))
            .toList(),
        onChanged: (v) => setState(() => _jabatan = v!),
      ),
    );
  }

  Widget _buildStatusDropdown() {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: DropdownButtonFormField<String>(
        value: _status,
        decoration: InputDecoration(
          labelText: 'Status',
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
        items: const ['aktif', 'non-aktif']
            .map((e) => DropdownMenuItem(value: e, child: Text(e == 'aktif' ? 'Aktif' : 'Non-Aktif')))
            .toList(),
        onChanged: (v) => setState(() => _status = v!),
      ),
    );
  }

  void _confirmDelete() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Hapus Pengurus'),
        content: Text('Yakin ingin menghapus data ${widget.pengurus!.wargaNama ?? widget.pengurus!.jabatan}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<PengurusCubit>().delete(widget.pengurus!.id!);
              Navigator.pop(context);
            },
            child: const Text('Hapus', style: TextStyle(color: AppThemeColors.error)),
          ),
        ],
      ),
    );
  }
}
