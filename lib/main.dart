import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'app.dart';
import 'providers/config_provider.dart';
import 'providers/game_provider.dart';
import 'providers/animation_provider.dart';
import 'repositories/alarm_repository.dart';
import 'repositories/stats_repository.dart';
import 'services/alarm_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Lock to portrait orientation
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);

  // Initialize Hive for stats storage
  await Hive.initFlutter();

  // Initialize timezone database (required by flutter_local_notifications
  // for zonedSchedule — used by pause reminder).
  tz_data.initializeTimeZones();

  // Initialize StatsRepository (SharedPreferences-based persistence)
  final statsRepo = await StatsRepository.create();

  // Initialize providers
  final configProvider = ConfigProvider(statsRepo: statsRepo);
  await configProvider.load();

  final gameProvider = GameProvider(configProvider, statsRepo: statsRepo);
  await gameProvider.initialize();

  // Mark notification service timezone as ready after init
  gameProvider.notificationService.markTimezoneReady();

  // Request notification permissions on first launch
  // (safe to call — iOS shows system dialog, Android 13+ shows permission)
  await gameProvider.notificationService.requestPermission();

  // Initialize AlarmService (V2.0)
  final prefs = await SharedPreferences.getInstance();
  final alarmRepo = AlarmRepository(prefs);
  final alarmService = AlarmService(
    repo: alarmRepo,
    notifications: gameProvider.notificationService,
    haptics: gameProvider.hapticService,
  );
  alarmService.load();

  final animationProvider = AnimationProvider(gameProvider);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: configProvider),
        ChangeNotifierProvider.value(value: gameProvider),
        ChangeNotifierProvider.value(value: animationProvider),
        Provider.value(value: alarmService),
      ],
      child: const PocketJoyApp(),
    ),
  );
}
