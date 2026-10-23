// KANAWA - App Motorista
// Plataforma de transporte por aplicativo
// Angola · Saurimo, Lunda Sul

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'core/services/local_notifications_service.dart';
import 'core/theme/kanawa_theme.dart';
import 'features/splash/splash_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // 🔔 Inicializar notificações locais (som + vibração)
  await LocalNotificationsService.initialize();

  runApp(const KanawaDriverApp());
}

class KanawaDriverApp extends StatelessWidget {
  const KanawaDriverApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'KANAWA Motorista',
      debugShowCheckedModeBanner: false,
      theme: KanawaTheme.light(),
      home: const SplashScreen(),
    );
  }
}