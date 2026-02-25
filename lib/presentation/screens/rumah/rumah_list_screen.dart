import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_pos/core/theme/app_theme.dart';
import 'package:flutter_pos/data/models/rumah.dart';
import 'package:flutter_pos/logic/cubits/rumah/rumah_cubit.dart';
import 'package:flutter_pos/logic/cubits/rumah/rumah_state.dart';
import 'package:flutter_pos/presentation/screens/rumah/rumah_form_screen.dart';

class RumahListScreen extends StatefulWidget {
  const RumahListScreen({super.key});

  @override
  State<RumahListScreen> createState() => _RumahListScreenState();
}

class _RumahListScreenState extends State<RumahListScreen> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    context.read<RumahCubit>().loadAll();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _search() {
    context.read<RumahCubit>().loadAll(search: _searchController.text);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppThemeColors.background,
      appBar: AppBar(
        title: const Text('Data Rumah'),
        backgroundColor: AppThemeColors.primary,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            color: Colors.white,
            child: TextField(
              controller: _searchController,
              onChanged: (_) => _search(),
              decoration: InputDecoration(
                hintText: 'Cari nomor rumah, blok...',
                prefixIcon: const Icon(Icons.search, color: AppThemeColors.textSecondary),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () { _searchController.clear(); _search(); },
                      )
                    : null,
                filled: true,
                fillColor: AppThemeColors.background,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
          ),
          Expanded(
            child: BlocBuilder<RumahCubit, RumahState>(
              builder: (context, state) {
                if (state is RumahLoading) {
                  return const Center(child: CircularProgressIndicator(color: AppThemeColors.primary));
                }
                if (state is RumahError) {
                  return Center(child: Text(state.message));
                }
                if (state is RumahLoaded) {
                  if (state.rumahList.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.home_outlined, size: 64, color: AppThemeColors.textSecondary.withValues(alpha: 0.5)),
                          const SizedBox(height: 16),
                          Text('Belum ada data rumah', style: AppTypography.bodyMedium.copyWith(color: AppThemeColors.textSecondary)),
                        ],
                      ),
                    );
                  }
                  return RefreshIndicator(
                    onRefresh: () async => _search(),
                    color: AppThemeColors.primary,
                    child: ListView.builder(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      itemCount: state.rumahList.length,
                      itemBuilder: (context, index) => _buildRumahCard(state.rumahList[index]),
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
        icon: const Icon(Icons.add_home),
        label: const Text('Tambah Rumah'),
      ),
    );
  }

  Widget _buildRumahCard(Rumah rumah) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _navigateToForm(rumah),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              // House icon or photo
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: AppThemeColors.primarySurface,
                  borderRadius: BorderRadius.circular(12),
                  image: rumah.foto != null && File(rumah.foto!).existsSync()
                      ? DecorationImage(image: FileImage(File(rumah.foto!)), fit: BoxFit.cover)
                      : null,
                ),
                child: rumah.foto == null || !File(rumah.foto!).existsSync()
                    ? const Icon(Icons.home, color: AppThemeColors.primary, size: 28)
                    : null,
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      rumah.displayName,
                      style: AppTypography.titleSmall.copyWith(fontWeight: FontWeight.bold),
                    ),
                    if (rumah.rt != null || rumah.rw != null)
                      Text(
                        'RT ${rumah.rt ?? '-'} / RW ${rumah.rw ?? '-'}',
                        style: AppTypography.labelSmall.copyWith(color: AppThemeColors.textSecondary),
                      ),
                    Text(
                      rumah.statusKepemilikan,
                      style: AppTypography.labelSmall.copyWith(color: AppThemeColors.textSecondary),
                    ),
                  ],
                ),
              ),
              // Penghuni count
              Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppThemeColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.people, size: 14, color: AppThemeColors.primary),
                        const SizedBox(width: 4),
                        Text(
                          '${rumah.penghuniCount}',
                          style: AppTypography.labelSmall.copyWith(
                            color: AppThemeColors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _navigateToForm(Rumah? rumah) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BlocProvider.value(
          value: context.read<RumahCubit>(),
          child: RumahFormScreen(rumah: rumah),
        ),
      ),
    ).then((_) => _search());
  }
}
