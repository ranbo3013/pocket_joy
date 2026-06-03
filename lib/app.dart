import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'config/routes.dart';
import 'config/theme.dart';
import 'providers/config_provider.dart';
import 'ui/pages/salary_setup_page.dart';
import 'ui/pages/home_page.dart';
import 'ui/pages/settings_page.dart';

class PocketJoyApp extends StatelessWidget {
  const PocketJoyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PocketJoy',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      initialRoute: _determineInitialRoute(context),
      onGenerateRoute: _onGenerateRoute,
    );
  }

  String _determineInitialRoute(BuildContext context) {
    final config = context.read<ConfigProvider>();
    if (!config.isSalarySet) {
      return AppRoutes.setup;
    }
    return AppRoutes.home;
  }

  Route<dynamic>? _onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case AppRoutes.home:
        return _fadeRoute(const HomePage(), settings);
      case AppRoutes.setup:
        return _fadeRoute(const SalarySetupPage(), settings);
      case AppRoutes.settings:
        return _slideRoute(const SettingsPage(), settings);
      default:
        return _fadeRoute(const HomePage(), settings);
    }
  }

  PageRouteBuilder _fadeRoute(Widget page, RouteSettings settings) {
    return PageRouteBuilder(
      settings: settings,
      pageBuilder: (_, __, ___) => page,
      transitionsBuilder: (_, animation, __, child) {
        return FadeTransition(opacity: animation, child: child);
      },
      transitionDuration: const Duration(milliseconds: 300),
    );
  }

  PageRouteBuilder _slideRoute(Widget page, RouteSettings settings) {
    return PageRouteBuilder(
      settings: settings,
      pageBuilder: (_, __, ___) => page,
      transitionsBuilder: (_, animation, __, child) {
        const begin = Offset(1.0, 0.0);
        const end = Offset.zero;
        final tween = Tween(begin: begin, end: end);
        final offsetAnimation = animation.drive(tween);
        return SlideTransition(position: offsetAnimation, child: child);
      },
      transitionDuration: const Duration(milliseconds: 300),
    );
  }
}
