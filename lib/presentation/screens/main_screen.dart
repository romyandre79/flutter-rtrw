import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_pos/core/theme/app_theme.dart';
import 'package:flutter_pos/data/models/user.dart';
import 'package:flutter_pos/logic/cubits/auth/auth_cubit.dart';
import 'package:flutter_pos/logic/cubits/auth/auth_state.dart';
import 'package:flutter_pos/logic/cubits/user/user_cubit.dart';
import 'package:flutter_pos/logic/cubits/warga/warga_cubit.dart';
import 'package:flutter_pos/logic/cubits/rumah/rumah_cubit.dart';
import 'package:flutter_pos/logic/cubits/pengurus/pengurus_cubit.dart';
import 'package:flutter_pos/logic/cubits/dashboard/dashboard_cubit.dart';
import 'package:flutter_pos/presentation/screens/dashboard/dashboard_screen.dart';
import 'package:flutter_pos/presentation/screens/warga/warga_list_screen.dart';
import 'package:flutter_pos/presentation/screens/rumah/rumah_list_screen.dart';
import 'package:flutter_pos/presentation/screens/pengurus/pengurus_list_screen.dart';
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

        // Build navigation items
        final navItems = <BottomNavigationBarItem>[
          const BottomNavigationBarItem(
            icon: Icon(Icons.dashboard_outlined),
            activeIcon: Icon(Icons.dashboard),
            label: 'Beranda',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.people_outlined),
            activeIcon: Icon(Icons.people),
            label: 'Warga',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Rumah',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.admin_panel_settings_outlined),
            activeIcon: Icon(Icons.admin_panel_settings),
            label: 'Pengurus',
          ),
        ];

        if (isOwner) {
          navItems.add(
            const BottomNavigationBarItem(
              icon: Icon(Icons.settings_outlined),
              activeIcon: Icon(Icons.settings),
              label: 'Settings',
            ),
          );
        }

        // Build screens
        final screens = <Widget>[
          BlocProvider(
            create: (_) => DashboardCubit(),
            child: DashboardScreen(
              onSwitchTab: (index) {
                setState(() => _currentIndex = index);
              },
            ),
          ),
          BlocProvider(
            create: (_) => WargaCubit(),
            child: const WargaListScreen(),
          ),
          BlocProvider(
            create: (_) => RumahCubit(),
            child: const RumahListScreen(),
          ),
          BlocProvider(
            create: (_) => PengurusCubit(),
            child: const PengurusListScreen(),
          ),
        ];

        if (isOwner) {
          screens.add(
            BlocProvider(
              create: (_) => UserCubit(),
              child: const SettingsScreen(),
            ),
          );
        }

        return Scaffold(
          body: IndexedStack(
            index: _currentIndex,
            children: screens,
          ),
          bottomNavigationBar: Container(
            decoration: BoxDecoration(
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 20,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: BottomNavigationBar(
              currentIndex: _currentIndex,
              onTap: (index) {
                if (index < navItems.length) {
                  setState(() => _currentIndex = index);
                }
              },
              type: BottomNavigationBarType.fixed,
              backgroundColor: Colors.white,
              selectedItemColor: AppThemeColors.primary,
              unselectedItemColor: AppThemeColors.textSecondary,
              selectedLabelStyle: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 11,
              ),
              unselectedLabelStyle: const TextStyle(fontSize: 11),
              items: navItems,
            ),
          ),
        );
      },
    );
  }
}
