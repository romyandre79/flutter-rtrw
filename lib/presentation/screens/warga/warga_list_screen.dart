import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_pos/core/theme/app_theme.dart';
import 'package:flutter_pos/data/models/warga.dart';
import 'package:flutter_pos/logic/cubits/warga/warga_cubit.dart';
import 'package:flutter_pos/logic/cubits/warga/warga_state.dart';
import 'package:flutter_pos/presentation/screens/warga/warga_form_screen.dart';

class WargaListScreen extends StatefulWidget {
  const WargaListScreen({super.key});

  @override
  State<WargaListScreen> createState() => _WargaListScreenState();
}

class _WargaListScreenState extends State<WargaListScreen> {
  final _searchController = TextEditingController();
  String? _statusFilter;

  @override
  void initState() {
    super.initState();
    context.read<WargaCubit>().loadAll();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _search() {
    context.read<WargaCubit>().loadAll(
      search: _searchController.text,
      status: _statusFilter,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppThemeColors.background,
      appBar: AppBar(
        title: const Text('Data Warga'),
        backgroundColor: AppThemeColors.primary,
        foregroundColor: Colors.white,
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.filter_list),
            onSelected: (value) {
              setState(() => _statusFilter = value == 'semua' ? null : value);
              _search();
            },
            itemBuilder: (_) => [
              const PopupMenuItem(value: 'semua', child: Text('Semua')),
              const PopupMenuItem(value: 'aktif', child: Text('Aktif')),
              const PopupMenuItem(value: 'pindah', child: Text('Pindah')),
              const PopupMenuItem(value: 'meninggal', child: Text('Meninggal')),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            color: Colors.white,
            child: TextField(
              controller: _searchController,
              onChanged: (_) => _search(),
              decoration: InputDecoration(
                hintText: 'Cari nama, NIK, atau no HP...',
                prefixIcon: const Icon(Icons.search, color: AppThemeColors.textSecondary),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _search();
                        },
                      )
                    : null,
                filled: true,
                fillColor: AppThemeColors.background,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
          ),
          // List
          Expanded(
            child: BlocBuilder<WargaCubit, WargaState>(
              builder: (context, state) {
                if (state is WargaLoading) {
                  return const Center(child: CircularProgressIndicator(color: AppThemeColors.primary));
                }
                if (state is WargaError) {
                  return Center(child: Text(state.message));
                }
                if (state is WargaLoaded) {
                  if (state.wargaList.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.people_outline, size: 64, color: AppThemeColors.textSecondary.withValues(alpha: 0.5)),
                          const SizedBox(height: 16),
                          Text('Belum ada data warga', style: AppTypography.bodyMedium.copyWith(color: AppThemeColors.textSecondary)),
                        ],
                      ),
                    );
                  }
                  return RefreshIndicator(
                    onRefresh: () async => _search(),
                    color: AppThemeColors.primary,
                    child: ListView.builder(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      itemCount: state.wargaList.length,
                      itemBuilder: (context, index) => _buildWargaCard(state.wargaList[index]),
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _navigateToForm(null),
        backgroundColor: AppThemeColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.person_add),
        label: const Text('Tambah Warga'),
      ),
    );
  }

  Widget _buildWargaCard(Warga warga) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _navigateToForm(warga),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              // Avatar
              CircleAvatar(
                radius: 24,
                backgroundColor: AppThemeColors.primarySurface,
                backgroundImage: warga.fotoProfil != null && File(warga.fotoProfil!).existsSync()
                    ? FileImage(File(warga.fotoProfil!))
                    : null,
                child: warga.fotoProfil == null || !File(warga.fotoProfil!).existsSync()
                    ? Icon(
                        warga.jenisKelamin == JenisKelamin.P ? Icons.woman : Icons.man,
                        color: AppThemeColors.primary,
                      )
                    : null,
              ),
              const SizedBox(width: AppSpacing.md),
              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      warga.nama,
                      style: AppTypography.titleSmall.copyWith(fontWeight: FontWeight.bold),
                    ),
                    if (warga.nik != null && warga.nik!.isNotEmpty)
                      Text(
                        'NIK: ${warga.nik}',
                        style: AppTypography.labelSmall.copyWith(color: AppThemeColors.textSecondary),
                      ),
                    if (warga.noHp != null && warga.noHp!.isNotEmpty)
                      Text(
                        warga.noHp!,
                        style: AppTypography.labelSmall.copyWith(color: AppThemeColors.textSecondary),
                      ),
                  ],
                ),
              ),
              // Status badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: warga.status == StatusWarga.aktif
                      ? AppThemeColors.success.withValues(alpha: 0.1)
                      : AppThemeColors.warning.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  warga.statusDisplay,
                  style: AppTypography.labelSmall.copyWith(
                    color: warga.status == StatusWarga.aktif
                        ? AppThemeColors.success
                        : AppThemeColors.warning,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _navigateToForm(Warga? warga) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BlocProvider.value(
          value: context.read<WargaCubit>(),
          child: WargaFormScreen(warga: warga),
        ),
      ),
    ).then((_) => _search());
  }
}
