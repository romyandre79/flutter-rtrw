import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_pos/core/theme/app_theme.dart';
import 'package:flutter_pos/core/utils/currency_formatter.dart';
import 'package:flutter_pos/data/models/user.dart';
import 'package:flutter_pos/logic/cubits/auth/auth_cubit.dart';
import 'package:flutter_pos/logic/cubits/auth/auth_state.dart';
import 'package:flutter_pos/logic/cubits/dashboard/dashboard_cubit.dart';
import 'package:flutter_pos/logic/cubits/dashboard/dashboard_state.dart';
import 'package:flutter_pos/logic/cubits/pengurus/pengurus_cubit.dart';
import 'package:flutter_pos/logic/cubits/iuran/iuran_cubit.dart';
import 'package:flutter_pos/logic/cubits/pengeluaran/pengeluaran_cubit.dart';
import 'package:flutter_pos/presentation/screens/pengurus/pengurus_list_screen.dart';
import 'package:flutter_pos/presentation/screens/iuran/iuran_list_screen.dart';
import 'package:flutter_pos/presentation/screens/pengeluaran/pengeluaran_list_screen.dart';
import 'package:flutter_pos/presentation/screens/denah/denah_rt_screen.dart';
import 'package:flutter_pos/logic/cubits/warga/warga_cubit.dart';
import 'package:flutter_pos/presentation/screens/pengumuman/pengumuman_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    context.read<DashboardCubit>().loadDashboard();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppThemeColors.background,
      body: BlocBuilder<AuthCubit, AuthState>(
        builder: (context, authState) {
          final user = authState is AuthAuthenticated ? authState.user : null;

          return RefreshIndicator(
            onRefresh: () async {
              context.read<DashboardCubit>().loadDashboard();
            },
            color: AppThemeColors.primary,
            child: ListView(
              children: [
                _buildHeader(user),
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildFinancialSummary(),
                      const SizedBox(height: AppSpacing.xl),
                      _buildQuickActions(),
                      const SizedBox(height: AppSpacing.xl),
                      _buildSummarySection(),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader(User? user) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: AppThemeColors.headerGradient,
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: AppRadius.fullRadius,
                    ),
                    child: const Icon(Icons.person, color: AppThemeColors.primary, size: 24),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Selamat Datang,',
                          style: AppTypography.bodySmall.copyWith(color: Colors.white70),
                        ),
                        Text(
                          user?.name ?? 'User',
                          style: AppTypography.titleMedium.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xs),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: AppRadius.fullRadius,
                    ),
                    child: Text(
                      user != null ? _getRoleDisplayName(user.role) : '-',
                      style: AppTypography.labelSmall.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: AppRadius.mdRadius,
                ),
                child: Row(
                  children: [
                    const Icon(Icons.location_city, color: Colors.white, size: 24),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Text(
                        'Sistem Informasi RT/RW',
                        style: AppTypography.titleSmall.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getRoleDisplayName(UserRole role) {
    switch (role) {
      case UserRole.owner:
        return 'Admin';
      case UserRole.kasir:
        return 'Staff';
    }
  }

  Widget _buildFinancialSummary() {
    return BlocBuilder<DashboardCubit, DashboardState>(
      builder: (context, state) {
        double saldo = 0;
        double iuran = 0;
        double pengeluaran = 0;

        if (state is DashboardLoaded) {
          iuran = state.totalIuran;
          pengeluaran = state.totalPengeluaran;
          saldo = iuran - pengeluaran;
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Keuangan Bulan Ini',
              style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: AppSpacing.md),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                gradient: AppThemeColors.primaryGradient,
                borderRadius: AppRadius.lgRadius,
                boxShadow: AppShadows.medium,
              ),
              child: Column(
                children: [
                  Text('Saldo', style: AppTypography.bodySmall.copyWith(color: Colors.white70)),
                  Text(
                    CurrencyFormatter.format(saldo.toInt()),
                    style: AppTypography.headlineLarge.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.arrow_downward, color: Color(0xFF69F0AE), size: 16),
                            const SizedBox(width: 4),
                            Text('Pemasukan', style: AppTypography.bodyMedium.copyWith(color: Colors.white)),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          CurrencyFormatter.format(iuran.toInt()),
                          style: AppTypography.titleMedium.copyWith(
                            color: const Color(0xFF69F0AE),
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
                            const Icon(Icons.arrow_upward, color: Color(0xFFFF5252), size: 16),
                            const SizedBox(width: 4),
                            Text('Pengeluaran', style: AppTypography.bodyMedium.copyWith(color: Colors.white)),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          CurrencyFormatter.format(pengeluaran.toInt()),
                          style: AppTypography.titleMedium.copyWith(
                            color: const Color(0xFFFF5252),
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
      ],
    );
      },
    );
  }

  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Menu Cepat',
          style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: AppSpacing.md),
        GridView.count(
          crossAxisCount: 4,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: AppSpacing.sm,
          crossAxisSpacing: AppSpacing.sm,
          childAspectRatio: 0.85,
          children: [
            _buildQuickActionItem(
              icon: Icons.admin_panel_settings,
              label: 'Pengurus',
              color: AppThemeColors.warning,
              onTap: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => BlocProvider(
                      create: (_) => PengurusCubit(),
                      child: const PengurusListScreen(),
                    ),
                  ),
                );
                if (mounted) context.read<DashboardCubit>().loadDashboard();
              },
            ),
            _buildQuickActionItem(
              icon: Icons.receipt_long,
              label: 'Iuran',
              color: AppThemeColors.primary,
              onTap: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => BlocProvider(
                      create: (_) => IuranCubit(),
                      child: const IuranListScreen(),
                    ),
                  ),
                );
                if (mounted) context.read<DashboardCubit>().loadDashboard();
              },
            ),
            _buildQuickActionItem(
              icon: Icons.money_off,
              label: 'Pengeluaran',
              color: AppThemeColors.error,
              onTap: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => BlocProvider(
                      create: (_) => PengeluaranCubit(),
                      child: const PengeluaranListScreen(),
                    ),
                  ),
                );
                if (mounted) context.read<DashboardCubit>().loadDashboard();
              },
            ),
            _buildQuickActionItem(
              icon: Icons.map_outlined,
              label: 'Denah Lingkungan',
              color: AppThemeColors.success,
              onTap: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const DenahRtScreen(),
                  ),
                );
                if (mounted) context.read<DashboardCubit>().loadDashboard();
              },
            ),
            _buildQuickActionItem(
              icon: Icons.campaign,
              label: 'Pengumuman',
              color: Colors.blueAccent,
              onTap: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => BlocProvider(
                      create: (_) => WargaCubit(),
                      child: const PengumumanScreen(),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickActionItem({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: AppRadius.lgRadius,
          boxShadow: AppShadows.small,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: AppRadius.mdRadius,
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              label,
              style: AppTypography.labelSmall.copyWith(fontWeight: FontWeight.w600),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummarySection() {
    return BlocBuilder<DashboardCubit, DashboardState>(
      builder: (context, state) {
        int totalWarga = 0;
        int totalRumah = 0;
        int totalPengurus = 0;

        if (state is DashboardLoaded) {
          totalWarga = state.totalWarga;
          totalRumah = state.totalRumah;
          totalPengurus = state.totalPengurus;
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Ringkasan Data',
              style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: AppSpacing.md),
            if (state is DashboardLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: CircularProgressIndicator(color: AppThemeColors.primary),
                ),
              )
            else
              Column(
                children: [
                  _buildStatCard(
                    icon: Icons.people,
                    label: 'Total Warga Aktif',
                    value: totalWarga.toString(),
                    color: AppThemeColors.primary,
                  ),                  
                  const SizedBox(height: AppSpacing.sm),
                  _buildStatCard(
                    icon: Icons.admin_panel_settings,
                    label: 'Pengurus Aktif',
                    value: totalPengurus.toString(),
                    color: AppThemeColors.warning,
                  ),
                ],
              ),
          ],
        );
      },
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: AppRadius.lgRadius,
        boxShadow: AppShadows.small,
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: AppRadius.mdRadius,
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: AppSpacing.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: AppTypography.bodyMedium.copyWith(color: AppThemeColors.textSecondary)),
                Text(
                  value,
                  style: AppTypography.headlineMedium.copyWith(
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
