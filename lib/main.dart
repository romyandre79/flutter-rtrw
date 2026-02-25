import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:flutter_pos/core/theme/app_theme.dart';
import 'package:flutter_pos/core/utils/date_formatter.dart';
import 'package:flutter_pos/data/database/database_helper.dart';
import 'package:flutter_pos/logic/cubits/auth/auth_cubit.dart';
import 'package:flutter_pos/logic/cubits/auth/auth_state.dart';
import 'package:flutter_pos/presentation/screens/auth/login_screen.dart';
import 'package:flutter_pos/presentation/screens/main_screen.dart';
import 'package:flutter_pos/presentation/screens/onboarding/onboarding_screen.dart';
import 'package:flutter_pos/data/repositories/auth_repository.dart';
import 'package:flutter_pos/data/repositories/report_repository.dart';
import 'package:flutter_pos/data/repositories/user_repository.dart';
import 'package:flutter_pos/data/repositories/unit_repository.dart';
import 'package:flutter_pos/data/repositories/warga_repository.dart';
import 'package:flutter_pos/data/repositories/rumah_repository.dart';
import 'package:flutter_pos/data/repositories/pengurus_repository.dart';
import 'package:flutter_pos/core/api/api_service.dart';
import 'package:flutter_pos/core/services/notification_service.dart';
import 'package:flutter_pos/core/services/sync_service.dart';
import 'package:flutter_pos/logic/sync/sync_cubit.dart';
import 'package:flutter_pos/logic/cubits/unit/unit_cubit.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize FFI for Windows
  if (Platform.isWindows) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  // Set status bar style
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );

  // Initialize all at once
  final prefs = await SharedPreferences.getInstance();
  await DateFormatter.initialize();
  await DatabaseHelper.instance.database;
  await NotificationService().init();

  final showOnboarding = !(prefs.getBool('onboarding_complete') ?? false);

  runApp(MyApp(showOnboarding: showOnboarding));
}

class MyApp extends StatelessWidget {
  final bool showOnboarding;

  const MyApp({super.key, required this.showOnboarding});

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider(create: (_) => AuthRepository()),
        RepositoryProvider(create: (_) => ReportRepository()),
        RepositoryProvider(create: (_) => UserRepository()),
        RepositoryProvider(create: (_) => UnitRepository()),
        RepositoryProvider(create: (_) => WargaRepository()),
        RepositoryProvider(create: (_) => RumahRepository()),
        RepositoryProvider(create: (_) => PengurusRepository()),
        RepositoryProvider(create: (_) => ApiService()),
        RepositoryProvider(
          create: (context) => SyncService(
            apiService: context.read<ApiService>(),
            dbHelper: DatabaseHelper.instance,
          ),
        ),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider(
            create: (context) => AuthCubit(
              authRepository: context.read<AuthRepository>(),
            )..checkAuthStatus(),
          ),
          BlocProvider(
            create: (context) => SyncCubit(
              context.read<SyncService>(),
            ),
          ),
          BlocProvider(
            create: (context) => UnitCubit(
              context.read<UnitRepository>(),
            ),
          ),
        ],
        child: MaterialApp(
          title: 'Sistem Informasi RT/RW',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          home: AuthWrapper(showOnboarding: showOnboarding),
        ),
      ),
    );
  }
}

/// Wrapper widget that handles auth state changes
class AuthWrapper extends StatefulWidget {
  final bool showOnboarding;

  const AuthWrapper({super.key, required this.showOnboarding});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  late bool _showOnboarding;

  @override
  void initState() {
    super.initState();
    _showOnboarding = widget.showOnboarding;
  }

  void _onOnboardingComplete() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_complete', true);
    setState(() {
      _showOnboarding = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_showOnboarding) {
      return OnboardingScreen(onComplete: _onOnboardingComplete);
    }

    return BlocBuilder<AuthCubit, AuthState>(
      builder: (context, state) {
        if (state is AuthInitial || state is AuthLoading) {
          return Scaffold(
            backgroundColor: AppThemeColors.background,
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 120,
                    height: 120,
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: AppRadius.xlRadius,
                      boxShadow: AppShadows.medium,
                    ),
                    child: Image.asset(
                      'assets/icons/logopos.png',
                      fit: BoxFit.contain,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  const CircularProgressIndicator(
                    color: AppThemeColors.primary,
                  ),
                ],
              ),
            ),
          );
        }

        if (state is AuthAuthenticated) {
          return MainScreen();
        }

        return const LoginScreen();
      },
    );
  }
}
