import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz;
import 'dart:io' show Platform;

/// FILE: notification_service.dart
/// DESCRIZIONE: Service Layer per la gestione delle notifiche locali.
/// Si occupa dell'inizializzazione del plugin, della configurazione dei fusi orari,
/// della gestione dei permessi e della schedulazione delle notifiche (promemoria giornalieri
/// e avvisi di superamento del budget).

class NotificationService {
  // --- CONFIGURAZIONE PLUGIN ---
  // Istanza principale del plugin e costanti per ID e Canali.
  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  static const int _dailyReminderId = 0;
  static const int _budgetLimitId = 1;

  static const String _dailyReminderChannel = 'daily_reminder';
  static const String _budgetAlertChannel = 'budget_alert';

  // --- INIZIALIZZAZIONE ---
  // Configura il sistema di notifiche all'avvio dell'app.
  // Inizializza il database dei fusi orari (essenziale per le notifiche schedulate),
  // imposta i settings specifici per Android (icone) e iOS (permessi),
  // e crea i canali di notifica necessari per Android.
  Future<void> initialize() async {
    tz.initializeTimeZones();
    
    try {
      final timezoneInfo = await FlutterTimezone.getLocalTimezone();
      final String timeZoneName = timezoneInfo.identifier;
      tz.setLocalLocation(tz.getLocation(timeZoneName));
      debugPrint('✅ Fuso orario rilevato e impostato: $timeZoneName');
    } catch (e) {
      debugPrint('⚠️ Errore rilevamento timezone: $e. Uso fallback.');
      _setLocationByOffset();
    }

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');

    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
      defaultPresentAlert: true,
      defaultPresentSound: true,
      defaultPresentBadge: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
      onDidReceiveBackgroundNotificationResponse: _onNotificationTappedBackground,
    );

    if (Platform.isIOS) {
      final iosImplementation = _notifications
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >();

      if (iosImplementation != null) {
        await iosImplementation.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
      }
    }

    await _createAndroidChannels();
  }

  // Metodo di fallback per impostare la location temporale.
  // Viene usato se il plugin FlutterTimezone fallisce, cercando una location
  // nel database che corrisponda all'offset corrente del dispositivo.
  void _setLocationByOffset() {
    final now = DateTime.now();
    final offset = now.timeZoneOffset;
    final locations = tz.timeZoneDatabase.locations;
    
    for (final location in locations.values) {
      final tzDateTime = tz.TZDateTime.now(location);
      if (tzDateTime.timeZoneOffset == offset) {
        tz.setLocalLocation(location);
        debugPrint('✅ Fuso orario impostato tramite offset: ${location.name}');
        return;
      }
    }
    tz.setLocalLocation(tz.getLocation('UTC'));
  }

  // --- CANALI ANDROID ---
  // Registra i canali di notifica richiesti da Android 8.0+.
  // Definisce un canale per i promemoria giornalieri e uno ad alta priorità
  // per gli avvisi relativi al budget.
  Future<void> _createAndroidChannels() async {
    const dailyChannel = AndroidNotificationChannel(
      _dailyReminderChannel,
      'Daily Reminder', // Tradotto
      description: 'Notifications to remind you to track expenses', // Tradotto
      importance: Importance.high,
      enableVibration: true,
      playSound: true,
    );

    const budgetChannel = AndroidNotificationChannel(
      _budgetAlertChannel,
      'Budget Alerts', // Tradotto
      description: 'Notifications when you exceed your monthly spending limit', // Tradotto
      importance: Importance.max,
      enableVibration: true,
      playSound: true,
    );

    final androidImplementation = _notifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();

    await androidImplementation?.createNotificationChannel(dailyChannel);
    await androidImplementation?.createNotificationChannel(budgetChannel);
  }

  // Gestisce la richiesta esplicita dei permessi di notifica
  // in base alla piattaforma (Android 13+ o iOS).
  Future<bool> requestPermissions() async {
    if (Platform.isIOS) {
      final iosImplementation = _notifications
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >();
      final granted = await iosImplementation?.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
      return granted ?? false;
    } else {
      final androidImplementation = _notifications
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      final granted = await androidImplementation?.requestNotificationsPermission();
      return granted ?? false;
    }
  }

  // --- SCHEDULAZIONE PROMEMORIA ---
  // Programma una notifica ricorrente giornaliera all'orario specificato.
  // Calcola la data corretta (oggi o domani se l'orario è passato), converte
  // nel fuso orario locale e utilizza il testo fornito per titolo e corpo.
  Future<void> scheduleDailyReminder({
    required TimeOfDay time,
    required String title,
    required String body,
  }) async {
    await cancelDailyReminder();

    final now = DateTime.now();
    var scheduledDate = DateTime(
      now.year,
      now.month,
      now.day,
      time.hour,
      time.minute,
    );

    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    final tzScheduledDate = tz.TZDateTime.from(scheduledDate, tz.local);

    const androidDetails = AndroidNotificationDetails(
      _dailyReminderChannel,
      'Daily Reminder', // Tradotto
      channelDescription: 'Notifications to remind you to track expenses', // Tradotto
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      sound: 'default',
      badgeNumber: 1,
    );

    const notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.zonedSchedule(
      _dailyReminderId,
      title, // Usa la stringa passata dal Provider
      body,  // Usa la stringa passata dal Provider
      tzScheduledDate,
      notificationDetails,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );

    debugPrint('✅ Notifica programmata per: $tzScheduledDate con testo: "$title"');
  }

  // --- TRIGGER IMMEDIATI (BUDGET) ---
  // Mostra immediatamente una notifica ad alta priorità.
  // Utilizzato quando l'utente supera la soglia di budget impostata.
  Future<void> showBudgetLimitNotification({
    required String title,
    required String body,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      _budgetAlertChannel,
      'Budget Alerts', // Tradotto
      channelDescription: 'Notifications when you exceed your monthly spending limit', // Tradotto
      importance: Importance.max,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
      styleInformation: BigTextStyleInformation(''),
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      badgeNumber: 1,
      interruptionLevel: InterruptionLevel.timeSensitive,
    );

    await _notifications.show(
      _budgetLimitId,
      title, // Usa parametro
      body,  // Usa parametro
      const NotificationDetails(android: androidDetails, iOS: iosDetails),
    );
  }

  // --- CANCELLAZIONE E PULIZIA ---
  // Metodi di utility per rimuovere notifiche specifiche o resettare i badge dell'app.
  Future<void> cancelDailyReminder() async {
    await _notifications.cancel(_dailyReminderId);
  }

  Future<void> cancelAllNotifications() async {
    await _notifications.cancelAll();
  }

  Future<void> clearBadge() async {
    if (Platform.isIOS) {
      await _notifications.show(
        0,
        '',
        '',
        const NotificationDetails(
          iOS: DarwinNotificationDetails(
            badgeNumber: 0,
            presentAlert: false,
            presentSound: false,
          ),
        ),
      );
    } else if (Platform.isAndroid) {
      await _notifications.cancelAll();
    }
  }

  // --- UTILS E CALLBACK ---
  // Callback invocati quando l'utente interagisce con una notifica.
  void _onNotificationTapped(NotificationResponse response) {
    debugPrint('📱 Notifica tappata (foreground): ${response.id}');
  }

  @pragma('vm:entry-point')
  static void _onNotificationTappedBackground(NotificationResponse response) {
    debugPrint('📱 Notifica tappata (background): ${response.id}');
  }

  // Verifica lo stato attuale dei permessi di notifica.
  Future<bool> areNotificationsEnabled() async {
    if (Platform.isAndroid) {
      final androidImplementation = _notifications
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      return await androidImplementation?.areNotificationsEnabled() ?? false;
    } else if (Platform.isIOS) {
      final iosImplementation = _notifications
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >();
      final settings = await iosImplementation?.checkPermissions();
      return settings?.isEnabled ?? false;
    }
    return true;
  }
}