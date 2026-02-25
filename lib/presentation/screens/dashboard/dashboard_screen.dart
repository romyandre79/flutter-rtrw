import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_pos/core/theme/app_theme.dart';
import 'package:flutter_pos/data/models/user.dart';
import 'package:flutter_pos/logic/cubits/auth/auth_cubit.dart';
import 'package:flutter_pos/logic/cubits/auth/auth_state.dart';
import 'package:flutter_pos/logic/cubits/dashboard/dashboard_cubit.dart';
import 'package:flutter_pos/logic/cubits/dashboard/dashboard_state.dart';

class DashboardScreen extends StatefulWidget {
  final Function(int)? onSwitchTab;
  const DashboardScreen({super.key, this.onSwitchTab});

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
            onRefresh: () async => context.read<DashboardCubit>().loadDashboard(),
            color: AppThemeColors.primary,
            child: ListView(
              children: [
                _buildHeader(user),
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
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
              // App description
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

  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Menu Cepat',
          style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: AppSpacing.md),
        Row(
          children: [
            Expanded(
              child: _buildQuickActionItem(
                icon: Icons.person_add,
                label: 'Tambah Warga',
                color: AppThemeColors.primary,
                onTap: () => widget.onSwitchTab?.call(1),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: _buildQuickActionItem(
                icon: Icons.add_home,
                label: 'Tambah Rumah',
                color: AppThemeColors.success,
                onTap: () => widget.onSwitchTab?.call(2),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: _buildQuickActionItem(
                icon: Icons.admin_panel_settings,
                label: 'Pengurus',
                color: AppThemeColors.warning,
                onTap: () => widget.onSwitchTab?.call(3),
              ),
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
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: AppRadius.lgRadius,
          boxShadow: AppShadows.small,
        ),
        child: Column(
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
            const SizedBox(height: AppSpacing.sm),
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
                    icon: Icons.home,
                    label: 'Total Rumah',
                    value: totalRumah.toString(),
                    color: AppThemeColors.success,
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
