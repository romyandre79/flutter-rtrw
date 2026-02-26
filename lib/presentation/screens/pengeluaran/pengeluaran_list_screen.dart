import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_pos/core/theme/app_theme.dart';
import 'package:flutter_pos/core/utils/currency_formatter.dart';
import 'package:flutter_pos/data/models/pengeluaran.dart';
import 'package:flutter_pos/logic/cubits/pengeluaran/pengeluaran_cubit.dart';
import 'package:flutter_pos/logic/cubits/pengeluaran/pengeluaran_state.dart';
import 'package:flutter_pos/presentation/screens/pengeluaran/pengeluaran_form_screen.dart';

class PengeluaranListScreen extends StatefulWidget {
  const PengeluaranListScreen({super.key});

  @override
  State<PengeluaranListScreen> createState() => _PengeluaranListScreenState();
}

class _PengeluaranListScreenState extends State<PengeluaranListScreen> {
  @override
  void initState() {
    super.initState();
    context.read<PengeluaranCubit>().loadAll();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppThemeColors.background,
      appBar: AppBar(
        title: const Text('Pengeluaran'),
        backgroundColor: AppThemeColors.primary,
        foregroundColor: Colors.white,
      ),
      body: BlocBuilder<PengeluaranCubit, PengeluaranState>(
        builder: (context, state) {
          if (state is PengeluaranLoading) {
            return const Center(child: CircularProgressIndicator(color: AppThemeColors.primary));
          }
          if (state is PengeluaranError) {
            return Center(child: Text(state.message));
          }
          if (state is PengeluaranLoaded) {
            return Column(
              children: [
                // Total
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    decoration: BoxDecoration(
                      gradient: AppThemeColors.primaryGradient,
                      borderRadius: AppRadius.lgRadius,
                    ),
                    child: Column(
                      children: [
                        Text('Total Pengeluaran',
                            style: AppTypography.bodySmall.copyWith(color: Colors.white70)),
                        const SizedBox(height: 4),
                        Text(
                          CurrencyFormatter.format(state.totalPengeluaran.toInt()),
                          style: AppTypography.headlineMedium.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // List
                Expanded(
                  child: state.pengeluaranList.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.money_off_outlined, size: 64,
                                  color: AppThemeColors.textSecondary.withValues(alpha: 0.5)),
                              const SizedBox(height: 16),
                              Text('Belum ada data pengeluaran',
                                  style: AppTypography.bodyMedium.copyWith(color: AppThemeColors.textSecondary)),
                            ],
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: () async => context.read<PengeluaranCubit>().loadAll(),
                          color: AppThemeColors.primary,
                          child: ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                            itemCount: state.pengeluaranList.length,
                            itemBuilder: (context, index) =>
                                _buildPengeluaranCard(state.pengeluaranList[index]),
                          ),
                        ),
                ),
              ],
            );
          }
          return const SizedBox.shrink();
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _navigateToForm(null),
        backgroundColor: AppThemeColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Tambah'),
      ),
    );
  }

  Widget _buildPengeluaranCard(Pengeluaran pengeluaran) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _navigateToForm(pengeluaran),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppThemeColors.error.withValues(alpha: 0.1),
                  borderRadius: AppRadius.mdRadius,
                ),
                child: const Icon(Icons.receipt_long, color: AppThemeColors.error),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      pengeluaran.kategori,
                      style: AppTypography.titleSmall.copyWith(fontWeight: FontWeight.bold),
                    ),
                    if (pengeluaran.keterangan != null && pengeluaran.keterangan!.isNotEmpty)
                      Text(
                        pengeluaran.keterangan!,
                        style: AppTypography.labelSmall.copyWith(color: AppThemeColors.textSecondary),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    Text(
                      pengeluaran.tanggal,
                      style: AppTypography.labelSmall.copyWith(color: AppThemeColors.textSecondary),
                    ),
                  ],
                ),
              ),
              Text(
                CurrencyFormatter.format(pengeluaran.jumlah.toInt()),
                style: AppTypography.titleSmall.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppThemeColors.error,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _navigateToForm(Pengeluaran? pengeluaran) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BlocProvider.value(
          value: context.read<PengeluaranCubit>(),
          child: PengeluaranFormScreen(pengeluaran: pengeluaran),
        ),
      ),
    ).then((_) => context.read<PengeluaranCubit>().loadAll());
  }
}
