import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import 'app.dart';
import 'providers/config_provider.dart';
import 'providers/game_provider.dart';
import 'providers/animation_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Lock to portrait orientation
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);

  // Initialize Hive for stats storage
  await Hive.initFlutter();

  // Initialize providers
  final configProvider = ConfigProvider();
  await configProvider.load();

  final gameProvider = GameProvider(configProvider);
  await gameProvider.initialize();

  final animationProvider = AnimationProvider(gameProvider);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: configProvider),
        ChangeNotifierProvider.value(value: gameProvider),
        ChangeNotifierProvider.value(value: animationProvider),
      ],
      child: const PocketJoyApp(),
    ),
  );
}
