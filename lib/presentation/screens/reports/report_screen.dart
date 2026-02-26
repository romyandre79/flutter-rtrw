import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_pos/core/theme/app_theme.dart';
import 'package:flutter_pos/core/utils/currency_formatter.dart';
import 'package:flutter_pos/logic/cubits/report/report_cubit.dart';
import 'package:flutter_pos/logic/cubits/report/report_state.dart';

class ReportScreen extends StatefulWidget {
  const ReportScreen({super.key});

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _endDate = DateTime.now();
  String _selectedPeriod = 'Bulan Ini';

  @override
  void initState() {
    super.initState();
    _setThisMonth();
    _loadReport();
  }

  void _setThisMonth() {
    final now = DateTime.now();
    _startDate = DateTime(now.year, now.month, 1);
    _endDate = now;
    _selectedPeriod = 'Bulan Ini';
  }

  void _setThisYear() {
    final now = DateTime.now();
    _startDate = DateTime(now.year, 1, 1);
    _endDate = now;
    _selectedPeriod = 'Tahun Ini';
  }

  void _loadReport() {
    context.read<ReportCubit>().loadReport(_startDate, _endDate);
  }

  Future<void> _selectDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: DateTimeRange(start: _startDate, end: _endDate),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(primary: AppThemeColors.primary),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
        _selectedPeriod = 'Custom';
      });
      _loadReport();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppThemeColors.background,
      body: Column(
        children: [
          _buildHeader(),
          _buildPeriodSelector(),
          Expanded(
            child: BlocBuilder<ReportCubit, ReportState>(
              builder: (context, state) {
                if (state is ReportLoading) {
                  return const Center(child: CircularProgressIndicator(color: AppThemeColors.primary));
                }

                if (state is ReportLoaded) {
                  return _buildReportContent(state.data);
                }

                if (state is ReportError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline, size: 48, color: AppThemeColors.error),
                        const SizedBox(height: 16),
                        Text(state.message, style: AppTypography.bodyMedium),
                      ],
                    ),
                  );
                }

                return const Center(child: Text('Memuat laporan...'));
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      decoration: const BoxDecoration(gradient: AppThemeColors.headerGradient),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Row(
            children: [
              const Icon(Icons.bar_chart, color: Colors.white, size: 28),
              const SizedBox(width: AppSpacing.md),
              Text(
                'Laporan Keuangan',
                style: AppTypography.headlineMedium.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPeriodSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
      color: Colors.white,
      child: Row(
        children: [
          _buildPeriodChip('Bulan Ini', () {
            _setThisMonth();
            setState(() {});
            _loadReport();
          }),
          const SizedBox(width: AppSpacing.sm),
          _buildPeriodChip('Tahun Ini', () {
            _setThisYear();
            setState(() {});
            _loadReport();
          }),
          const SizedBox(width: AppSpacing.sm),
          _buildPeriodChip('Custom', _selectDateRange),
        ],
      ),
    );
  }

  Widget _buildPeriodChip(String label, VoidCallback onTap) {
    final isSelected = _selectedPeriod == label;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppThemeColors.primary : AppThemeColors.primarySurface,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: AppTypography.labelSmall.copyWith(
            color: isSelected ? Colors.white : AppThemeColors.primary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildReportContent(ReportData data) {
    return RefreshIndicator(
      onRefresh: () async => _loadReport(),
      color: AppThemeColors.primary,
      child: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          // Saldo card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.xl),
            decoration: BoxDecoration(
              gradient: AppThemeColors.primaryGradient,
              borderRadius: AppRadius.lgRadius,
              boxShadow: AppShadows.medium,
            ),
            child: Column(
              children: [
                Text('Saldo Periode', style: AppTypography.bodySmall.copyWith(color: Colors.white70)),
                const SizedBox(height: 4),
                Text(
                  CurrencyFormatter.format(data.saldo.toInt()),
                  style: AppTypography.displaySmall.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.arrow_downward, color: Colors.greenAccent, size: 16),
                              const SizedBox(width: 4),
                              Text('Total Iuran', style: AppTypography.labelSmall.copyWith(color: Colors.white70)),
                            ],
                          ),
                          Text(
                            CurrencyFormatter.format(data.totalIuran.toInt()),
                            style: AppTypography.titleSmall.copyWith(
                              color: Colors.greenAccent,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(width: 1, height: 40, color: Colors.white24),
                    Expanded(
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.arrow_upward, color: Colors.redAccent, size: 16),
                              const SizedBox(width: 4),
                              Text('Total Pengeluaran', style: AppTypography.labelSmall.copyWith(color: Colors.white70)),
                            ],
                          ),
                          Text(
                            CurrencyFormatter.format(data.totalPengeluaran.toInt()),
                            style: AppTypography.titleSmall.copyWith(
                              color: Colors.redAccent,
                              fontWeight: FontWeight.bold,
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

          const SizedBox(height: AppSpacing.xl),

          // Iuran statistics
          Text('Status Iuran', style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  icon: Icons.check_circle,
                  label: 'Lunas',
                  value: '${data.jumlahIuranLunas}',
                  color: AppThemeColors.success,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _buildStatCard(
                  icon: Icons.pending,
                  label: 'Belum Bayar',
                  value: '${data.jumlahIuranBelum}',
                  color: AppThemeColors.warning,
                ),
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.xl),

          // Pengeluaran by kategori
          if (data.pengeluaranByKategori.isNotEmpty) ...[
            Text('Pengeluaran per Kategori', style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: AppSpacing.md),
            ...data.pengeluaranByKategori.entries.map((entry) => _buildKategoriRow(entry.key, entry.value)),
          ],

          const SizedBox(height: AppSpacing.xl),

          // Monthly chart
          if (data.monthlyData.isNotEmpty) ...[
            Text('Tren Bulanan', style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: AppSpacing.md),
            ...data.monthlyData.map((m) => _buildMonthlyRow(m)),
          ],

          const SizedBox(height: AppSpacing.xxl),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: AppRadius.lgRadius,
        boxShadow: AppShadows.small,
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: AppSpacing.sm),
          Text(value, style: AppTypography.headlineMedium.copyWith(
            fontWeight: FontWeight.bold, color: color,
          )),
          Text(label, style: AppTypography.labelSmall),
        ],
      ),
    );
  }

  Widget _buildKategoriRow(String kategori, double jumlah) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: AppRadius.mdRadius,
          boxShadow: AppShadows.small,
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppThemeColors.error.withValues(alpha: 0.1),
                borderRadius: AppRadius.smRadius,
              ),
              child: const Icon(Icons.receipt, color: AppThemeColors.error, size: 18),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text(kategori, style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w500)),
            ),
            Text(
              CurrencyFormatter.format(jumlah.toInt()),
              style: AppTypography.titleSmall.copyWith(
                color: AppThemeColors.error,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMonthlyRow(MonthlyFinance m) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: AppRadius.mdRadius,
          boxShadow: AppShadows.small,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(m.month, style: AppTypography.titleSmall.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: AppSpacing.xs),
            Row(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      const Icon(Icons.arrow_downward, color: AppThemeColors.success, size: 14),
                      const SizedBox(width: 4),
                      Text(
                        CurrencyFormatter.format(m.iuran.toInt()),
                        style: AppTypography.labelSmall.copyWith(color: AppThemeColors.success, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Row(
                    children: [
                      const Icon(Icons.arrow_upward, color: AppThemeColors.error, size: 14),
                      const SizedBox(width: 4),
                      Text(
                        CurrencyFormatter.format(m.pengeluaran.toInt()),
                        style: AppTypography.labelSmall.copyWith(color: AppThemeColors.error, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
                Text(
                  CurrencyFormatter.format(m.saldo.toInt()),
                  style: AppTypography.labelMedium.copyWith(
                    color: m.saldo >= 0 ? AppThemeColors.success : AppThemeColors.error,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
