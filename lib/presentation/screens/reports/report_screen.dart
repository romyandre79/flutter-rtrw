import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_pos/core/theme/app_theme.dart';
import 'package:flutter_pos/logic/cubits/report/report_cubit.dart';
import 'package:flutter_pos/logic/cubits/report/report_state.dart';
import 'package:flutter_pos/presentation/screens/main_screen.dart';

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

  void _setLastMonth() {
    final now = DateTime.now();
    final lastMonth = DateTime(now.year, now.month - 1, 1);
    _startDate = lastMonth;
    _endDate = DateTime(now.year, now.month, 0);
    _selectedPeriod = 'Bulan Lalu';
  }

  void _setThisWeek() {
    final now = DateTime.now();
    _startDate = now.subtract(Duration(days: now.weekday - 1));
    _endDate = now;
    _selectedPeriod = 'Minggu Ini';
  }

  void _setToday() {
    final now = DateTime.now();
    _startDate = now;
    _endDate = now;
    _selectedPeriod = 'Hari Ini';
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
            colorScheme: const ColorScheme.light(
              primary: AppThemeColors.primary,
            ),
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
          Expanded(
            child: BlocConsumer<ReportCubit, ReportState>(
              listener: (context, state) {
                if (state is ReportExported) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(state.message),
                      backgroundColor: AppThemeColors.success,
                    ),
                  );
                } else if (state is ReportError) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(state.message),
                      backgroundColor: AppThemeColors.error,
                    ),
                  );
                }
              },
              builder: (context, state) {
                if (state is ReportLoading || state is ReportExporting) {
                  return const Center(
                    child: CircularProgressIndicator(
                      color: AppThemeColors.primary,
                    ),
                  );
                }

                if (state is ReportLoaded) {
                  return const Center(
                    child: Text('Laporan berhasil dimuat'),
                  );
                }

                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.analytics_outlined,
                        size: 64,
                        color: AppThemeColors.textSecondary.withValues(alpha: 0.5),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      Text(
                        'Memuat laporan...',
                        style: AppTypography.bodyMedium.copyWith(
                          color: AppThemeColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      decoration: const BoxDecoration(
        gradient: AppThemeColors.headerGradient,
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Row(
            children: [
              IconButton(
                onPressed: () => Navigator.of(context).canPop()
                    ? Navigator.of(context).pop()
                    : Navigator.of(context).pushReplacement(
                        MaterialPageRoute(builder: (_) => const MainScreen()),
                      ),
                icon: const Icon(Icons.arrow_back, color: Colors.white),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  'Laporan',
                  style: AppTypography.headlineMedium.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              BlocBuilder<ReportCubit, ReportState>(
                builder: (context, state) {
                  final isLoaded = state is ReportLoaded;
                  return PopupMenuButton<String>(
                    enabled: isLoaded,
                    icon: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: isLoaded ? 0.2 : 0.1),
                        borderRadius: AppRadius.smRadius,
                      ),
                      child: Icon(
                        Icons.file_download_outlined,
                        color: Colors.white.withValues(alpha: isLoaded ? 1.0 : 0.5),
                        size: 20,
                      ),
                    ),
                    onSelected: (value) {
                      if (!isLoaded) return;
                      if (value == 'summary') {
                        context.read<ReportCubit>().exportToExcel();
                      }
                    },
                    itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                      const PopupMenuItem<String>(
                        value: 'summary',
                        child: Row(
                          children: [
                            Icon(Icons.summarize_outlined, color: AppThemeColors.textPrimary),
                            SizedBox(width: AppSpacing.sm),
                            Text('Export Laporan'),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
