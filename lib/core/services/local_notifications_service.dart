// KANAWA - Serviço de Notificações Locais (Motorista)
// v1.0 — Som + vibração quando chega uma notificação
// Design: MBSoft · Benvindo Mersh

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class LocalNotificationsService {
  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static bool _initialized = false;

  /// Canal de notificações (Android)
  static const _channelId = 'kanawa_driver_channel';
  static const _channelName = 'KANAWA Motorista';
  static const _channelDescription =
      'Notificações de novas viagens e atualizações';

  // ═══════════════════════════════════════════════════════════
  // INICIALIZAR
  // ═══════════════════════════════════════════════════════════
  static Future<void> initialize() async {
    if (_initialized) return;

    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _plugin.initialize(settings);

    // Criar canal Android
    final androidPlugin =
        _plugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    if (androidPlugin != null) {
      await androidPlugin.createNotificationChannel(
        const AndroidNotificationChannel(
          _channelId,
          _channelName,
          description: _channelDescription,
          importance: Importance.max,
          playSound: true,
          enableVibration: true,
        ),
      );

      // Pedir permissão (Android 13+)
      await androidPlugin.requestNotificationsPermission();
    }

    _initialized = true;
    debugPrint('✅ LocalNotificationsService inicializado');
  }

  // ═══════════════════════════════════════════════════════════
  // MOSTRAR NOTIFICAÇÃO
  // ═══════════════════════════════════════════════════════════
  static Future<void> show({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    if (!_initialized) await initialize();

    const androidDetails = AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDescription,
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
      icon: '@mipmap/ic_launcher',
      styleInformation: BigTextStyleInformation(''),
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _plugin.show(id, title, body, details, payload: payload);
    debugPrint('🔔 Notificação mostrada: $title');
  }

  // ═══════════════════════════════════════════════════════════
  // CANCELAR
  // ═══════════════════════════════════════════════════════════
  static Future<void> cancelAll() async {
    await _plugin.cancelAll();
  }
}