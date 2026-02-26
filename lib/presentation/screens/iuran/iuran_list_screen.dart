import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_pos/core/theme/app_theme.dart';
import 'package:flutter_pos/core/utils/currency_formatter.dart';
import 'package:flutter_pos/data/models/iuran.dart';
import 'package:flutter_pos/logic/cubits/iuran/iuran_cubit.dart';
import 'package:flutter_pos/logic/cubits/iuran/iuran_state.dart';
import 'package:flutter_pos/presentation/screens/iuran/iuran_form_screen.dart';

class IuranListScreen extends StatefulWidget {
  const IuranListScreen({super.key});

  @override
  State<IuranListScreen> createState() => _IuranListScreenState();
}

class _IuranListScreenState extends State<IuranListScreen> {
  String? _filterStatus;

  @override
  void initState() {
    super.initState();
    context.read<IuranCubit>().loadAll();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppThemeColors.background,
      appBar: AppBar(
        title: const Text('Iuran Warga'),
        backgroundColor: AppThemeColors.primary,
        foregroundColor: Colors.white,
        actions: [
          PopupMenuButton<String?>(
            icon: const Icon(Icons.filter_list),
            onSelected: (value) {
              setState(() => _filterStatus = value);
              context.read<IuranCubit>().loadAll(statusBayar: value);
            },
            itemBuilder: (_) => [
              const PopupMenuItem(value: null, child: Text('Semua')),
              const PopupMenuItem(value: 'lunas', child: Text('Lunas')),
              const PopupMenuItem(value: 'belum_bayar', child: Text('Belum Bayar')),
            ],
          ),
        ],
      ),
      body: BlocBuilder<IuranCubit, IuranState>(
        builder: (context, state) {
          if (state is IuranLoading) {
            return const Center(child: CircularProgressIndicator(color: AppThemeColors.primary));
          }
          if (state is IuranError) {
            return Center(child: Text(state.message));
          }
          if (state is IuranLoaded) {
            return Column(
              children: [
                // Summary cards
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Row(
                    children: [
                      Expanded(
                        child: _buildSummaryCard(
                          'Terkumpul',
                          CurrencyFormatter.format(state.totalLunas.toInt()),
                          AppThemeColors.success,
                          Icons.check_circle,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: _buildSummaryCard(
                          'Belum Bayar',
                          CurrencyFormatter.format(state.totalBelumBayar.toInt()),
                          AppThemeColors.warning,
                          Icons.pending,
                        ),
                      ),
                    ],
                  ),
                ),
                // List
                Expanded(
                  child: state.iuranList.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.receipt_long_outlined, size: 64,
                                  color: AppThemeColors.textSecondary.withValues(alpha: 0.5)),
                              const SizedBox(height: 16),
                              Text('Belum ada data iuran',
                                  style: AppTypography.bodyMedium.copyWith(color: AppThemeColors.textSecondary)),
                            ],
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: () async =>
                              context.read<IuranCubit>().loadAll(statusBayar: _filterStatus),
                          color: AppThemeColors.primary,
                          child: ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                            itemCount: state.iuranList.length,
                            itemBuilder: (context, index) => _buildIuranCard(state.iuranList[index]),
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
        label: const Text('Tambah Iuran'),
      ),
    );
  }

  Widget _buildSummaryCard(String label, String value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: AppRadius.lgRadius,
        boxShadow: AppShadows.small,
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: AppRadius.mdRadius,
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: AppTypography.labelSmall),
                Text(value, style: AppTypography.titleSmall.copyWith(
                  fontWeight: FontWeight.bold, color: color,
                )),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIuranCard(Iuran iuran) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _navigateToForm(iuran),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: iuran.isLunas
                      ? AppThemeColors.success.withValues(alpha: 0.1)
                      : AppThemeColors.warning.withValues(alpha: 0.1),
                  borderRadius: AppRadius.mdRadius,
                ),
                child: Icon(
                  iuran.isLunas ? Icons.check_circle : Icons.pending,
                  color: iuran.isLunas ? AppThemeColors.success : AppThemeColors.warning,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      iuran.wargaNama ?? 'Warga #${iuran.wargaId ?? "-"}',
                      style: AppTypography.titleSmall.copyWith(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      '${iuran.jenisDisplay} • ${iuran.periode ?? "-"}',
                      style: AppTypography.labelSmall.copyWith(color: AppThemeColors.textSecondary),
                    ),
                    if (iuran.keterangan != null && iuran.keterangan!.isNotEmpty)
                      Text(
                        iuran.keterangan!,
                        style: AppTypography.labelSmall.copyWith(color: AppThemeColors.textSecondary),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    CurrencyFormatter.format(iuran.jumlah.toInt()),
                    style: AppTypography.titleSmall.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppThemeColors.primary,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: iuran.isLunas
                          ? AppThemeColors.success.withValues(alpha: 0.1)
                          : AppThemeColors.warning.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      iuran.statusDisplay,
                      style: AppTypography.labelSmall.copyWith(
                        color: iuran.isLunas ? AppThemeColors.success : AppThemeColors.warning,
                        fontWeight: FontWeight.w600,
                      ),
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

  void _navigateToForm(Iuran? iuran) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BlocProvider.value(
          value: context.read<IuranCubit>(),
          child: IuranFormScreen(iuran: iuran),
        ),
      ),
    ).then((_) => context.read<IuranCubit>().loadAll(statusBayar: _filterStatus));
  }
}
