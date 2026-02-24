import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_pos/core/theme/app_theme.dart';
import 'package:flutter_pos/data/models/user.dart';
import 'package:flutter_pos/logic/cubits/auth/auth_cubit.dart';
import 'package:flutter_pos/logic/cubits/auth/auth_state.dart';
import 'package:flutter_pos/logic/cubits/user/user_cubit.dart';
import 'package:flutter_pos/logic/cubits/report/report_cubit.dart';
import 'package:flutter_pos/presentation/screens/dashboard/dashboard_screen.dart';
import 'package:flutter_pos/presentation/screens/reports/report_screen.dart';
import 'package:flutter_pos/presentation/screens/settings/settings_screen.dart';


class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthCubit, AuthState>(
      builder: (context, state) {
        if (state is! AuthAuthenticated) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final user = state.user;
        final isOwner = user.role == UserRole.owner;

        // Build navigation items based on role
        final navItems = <BottomNavigationBarItem>[
          const BottomNavigationBarItem(
            icon: Icon(Icons.dashboard_outlined),
            activeIcon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
        ];

        if (isOwner) {
          navItems.add(
            const BottomNavigationBarItem(
              icon: Icon(Icons.analytics_outlined),
              activeIcon: Icon(Icons.analytics),
              label: 'Laporan',
            ),
          );
        
          navItems.add(
            const BottomNavigationBarItem(
              icon: Icon(Icons.settings_outlined),
              activeIcon: Icon(Icons.settings),
              label: 'Settings',
            ),
          );
        }

        // Build screens list based on role
        final screens = <Widget>[
          DashboardScreen(
            onSwitchTab: (index) {
              setState(() => _currentIndex = index);
            },
          ),
        ];

        if (isOwner) {
          screens.add(
            BlocProvider(
              create: (_) => ReportCubit(),
              child: const ReportScreen(),
            ),
          );
          screens.add(
            BlocProvider(
              create: (_) => UserCubit(),
              child: const SettingsScreen(),
            ),
          );
        }

        // Ensure current index is valid
        if (_currentIndex >= screens.length) {
          _currentIndex = 0;
        }

        return Scaffold(
          body: IndexedStack(
            index: _currentIndex,
            children: screens,
          ),
          bottomNavigationBar: _buildCustomBottomNav(navItems),
        );
      },
    );
  }

  Widget _buildCustomBottomNav(List<BottomNavigationBarItem> navItems) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Container(
          height: 64,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(navItems.length, (index) {
              final item = navItems[index];
              final isSelected = _currentIndex == index;

              return Expanded(
                child: GestureDetector(
                  onTap: () {
                    setState(() => _currentIndex = index);
                  },
                  behavior: HitTestBehavior.opaque,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconTheme(
                        data: IconThemeData(
                          color: isSelected
                              ? AppThemeColors.primary
                              : AppThemeColors.textSecondary,
                          size: 24,
                        ),
                        child: isSelected ? item.activeIcon : item.icon,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item.label ?? '',
                        style: AppTypography.labelSmall.copyWith(
                          color: isSelected
                              ? AppThemeColors.primary
                              : AppThemeColors.textSecondary,
                          fontWeight:
                              isSelected ? FontWeight.w600 : FontWeight.normal,
                          fontSize: 11,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}
