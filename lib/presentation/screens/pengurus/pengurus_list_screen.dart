import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_pos/core/theme/app_theme.dart';
import 'package:flutter_pos/data/models/pengurus.dart';
import 'package:flutter_pos/logic/cubits/pengurus/pengurus_cubit.dart';
import 'package:flutter_pos/logic/cubits/pengurus/pengurus_state.dart';
import 'package:flutter_pos/presentation/screens/pengurus/pengurus_form_screen.dart';

class PengurusListScreen extends StatefulWidget {
  const PengurusListScreen({super.key});

  @override
  State<PengurusListScreen> createState() => _PengurusListScreenState();
}

class _PengurusListScreenState extends State<PengurusListScreen> {
  @override
  void initState() {
    super.initState();
    context.read<PengurusCubit>().loadAll();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppThemeColors.background,
      appBar: AppBar(
        title: const Text('Data Pengurus'),
        backgroundColor: AppThemeColors.primary,
        foregroundColor: Colors.white,
      ),
      body: BlocBuilder<PengurusCubit, PengurusState>(
        builder: (context, state) {
          if (state is PengurusLoading) {
            return const Center(child: CircularProgressIndicator(color: AppThemeColors.primary));
          }
          if (state is PengurusError) {
            return Center(child: Text(state.message));
          }
          if (state is PengurusLoaded) {
            if (state.pengurusList.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.admin_panel_settings_outlined, size: 64,
                        color: AppThemeColors.textSecondary.withValues(alpha: 0.5)),
                    const SizedBox(height: 16),
                    Text('Belum ada data pengurus',
                        style: AppTypography.bodyMedium.copyWith(color: AppThemeColors.textSecondary)),
                  ],
                ),
              );
            }
            return RefreshIndicator(
              onRefresh: () async => context.read<PengurusCubit>().loadAll(),
              color: AppThemeColors.primary,
              child: ListView.builder(
                padding: const EdgeInsets.all(AppSpacing.md),
                itemCount: state.pengurusList.length,
                itemBuilder: (context, index) => _buildPengurusCard(state.pengurusList[index]),
              ),
            );
          }
          return const SizedBox.shrink();
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _navigateToForm(null),
        backgroundColor: AppThemeColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.person_add_alt_1),
        label: const Text('Tambah Pengurus'),
      ),
    );
  }

  Widget _buildPengurusCard(Pengurus pengurus) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _navigateToForm(pengurus),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              // Avatar
              CircleAvatar(
                radius: 24,
                backgroundColor: AppThemeColors.primarySurface,
                backgroundImage: pengurus.wargaFotoProfil != null &&
                        File(pengurus.wargaFotoProfil!).existsSync()
                    ? FileImage(File(pengurus.wargaFotoProfil!))
                    : null,
                child: pengurus.wargaFotoProfil == null ||
                        !File(pengurus.wargaFotoProfil!).existsSync()
                    ? const Icon(Icons.admin_panel_settings, color: AppThemeColors.primary)
                    : null,
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      pengurus.wargaNama ?? '(Belum ditautkan)',
                      style: AppTypography.titleSmall.copyWith(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      pengurus.jabatan,
                      style: AppTypography.labelMedium.copyWith(color: AppThemeColors.primary),
                    ),
                    Text(
                      pengurus.periodeDisplay,
                      style: AppTypography.labelSmall.copyWith(color: AppThemeColors.textSecondary),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: pengurus.status == 'aktif'
                      ? AppThemeColors.success.withValues(alpha: 0.1)
                      : AppThemeColors.textSecondary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  pengurus.statusDisplay,
                  style: AppTypography.labelSmall.copyWith(
                    color: pengurus.status == 'aktif' ? AppThemeColors.success : AppThemeColors.textSecondary,
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

  void _navigateToForm(Pengurus? pengurus) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BlocProvider.value(
          value: context.read<PengurusCubit>(),
          child: PengurusFormScreen(pengurus: pengurus),
        ),
      ),
    ).then((_) => context.read<PengurusCubit>().loadAll());
  }
}
