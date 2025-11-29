// notification_service.dart
// -----------------------------------------------------------------------------
// 🔔 SERVIZIO NOTIFICHE LOCALI
// -----------------------------------------------------------------------------
// Gestisce tutte le notifiche locali dell'app:
// - Inizializzazione e permessi
// - Notifiche giornaliere programmabili
// - Notifiche per superamento limite spesa
// - Cancellazione notifiche
// -----------------------------------------------------------------------------

import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz;
import 'dart:io' show Platform;

class NotificationService {
  // 🔧 Singleton pattern
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  // 📱 Plugin per notifiche locali
  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  // 🆔 ID notifiche
  static const int _dailyReminderId = 0;
  static const int _budgetLimitId = 1;

  // 🎯 Canali notifiche Android
  static const String _dailyReminderChannel = 'daily_reminder';
  static const String _budgetAlertChannel = 'budget_alert';

  // -----------------------------------------------------------------------------
  // 🚀 INIZIALIZZAZIONE
  // -----------------------------------------------------------------------------
  Future<void> initialize() async {
    // Inizializza timezone per notifiche programmate
    tz.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Europe/Rome'));

    // ⚙️ Impostazioni Android
    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );

    // ⚙️ Impostazioni iOS - AGGIUNTO: Richiedi permessi all'inizializzazione
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
      // ✅ FIX: Abilita presentazione in foreground
      defaultPresentAlert: true,
      defaultPresentSound: true,
      defaultPresentBadge: true,
    );

    // ⚙️ Impostazioni generali
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    // 🎬 Inizializza plugin
    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
      onDidReceiveBackgroundNotificationResponse:
          _onNotificationTappedBackground,
    );

    // ✅ iOS: Richiedi permessi esplicitamente
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

    // 📢 Crea canali Android
    await _createAndroidChannels();
  }

  // -----------------------------------------------------------------------------
  // 📢 CREA CANALI ANDROID
  // -----------------------------------------------------------------------------
  Future<void> _createAndroidChannels() async {
    // Canale per promemoria giornaliero
    const dailyChannel = AndroidNotificationChannel(
      _dailyReminderChannel,
      'Promemoria giornaliero',
      description: 'Notifiche per ricordarti di inserire le spese',
      importance: Importance.high,
      enableVibration: true,
      playSound: true,
    );

    // Canale per avvisi limite budget
    const budgetChannel = AndroidNotificationChannel(
      _budgetAlertChannel,
      'Avvisi budget',
      description: 'Notifiche quando superi il limite di spesa mensile',
      importance: Importance.max,
      enableVibration: true,
      playSound: true,
    );

    await _notifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(dailyChannel);

    await _notifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(budgetChannel);
  }

  // -----------------------------------------------------------------------------
  // 🔔 RICHIEDI PERMESSI
  // -----------------------------------------------------------------------------
  Future<bool> requestPermissions() async {
    // iOS - richiedi permessi esplicitamente
    final iosImplementation = _notifications
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >();

    if (iosImplementation != null) {
      final granted = await iosImplementation.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
      return granted ?? false;
    }

    // Android 13+ - richiedi permessi
    final androidImplementation = _notifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();

    if (androidImplementation != null) {
      final granted = await androidImplementation
          .requestNotificationsPermission();
      return granted ?? false;
    }

    return true;
  }

  // -----------------------------------------------------------------------------
  // 📅 PROGRAMMA NOTIFICA GIORNALIERA
  // -----------------------------------------------------------------------------
  Future<void> scheduleDailyReminder({required TimeOfDay time}) async {
    // Cancella notifica esistente
    await cancelDailyReminder();

    // Crea data/ora per la notifica
    final now = DateTime.now();
    var scheduledDate = DateTime(
      now.year,
      now.month,
      now.day,
      time.hour,
      time.minute,
    );

    // Se l'orario è già passato oggi, programma per domani
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    // Converti in TZDateTime
    final tzScheduledDate = tz.TZDateTime.from(scheduledDate, tz.local);

    // 📱 Dettagli notifica Android
    const androidDetails = AndroidNotificationDetails(
      _dailyReminderChannel,
      'Promemoria giornaliero',
      channelDescription: 'Notifiche per ricordarti di inserire le spese',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );

    // 🍎 Dettagli notifica iOS - ✅ FIX: Abilita presentazione foreground
    const iosDetails = DarwinNotificationDetails(
      presentAlert: true, // 🔑 Mostra in foreground
      presentBadge: true, // 🔑 Badge in foreground
      presentSound: true, // 🔑 Suona in foreground
      sound: 'default', // Suono di sistema
      badgeNumber: 1,
    );

    const notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    // 🔔 Programma notifica ricorrente giornaliera
    await _notifications.zonedSchedule(
      _dailyReminderId,
      '💰 Promemoria spese',
      'Non dimenticare di inserire le tue spese di oggi!',
      tzScheduledDate,
      notificationDetails,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );

    debugPrint(
      '✅ Notifica giornaliera programmata per le ${time.hour}:${time.minute.toString().padLeft(2, '0')}',
    );
  }

  // -----------------------------------------------------------------------------
  // ❌ CANCELLA NOTIFICA GIORNALIERA
  // -----------------------------------------------------------------------------
  Future<void> cancelDailyReminder() async {
    await _notifications.cancel(_dailyReminderId);
    debugPrint('🗑️ Notifica giornaliera cancellata');
  }

  // -----------------------------------------------------------------------------
  // 💰 MOSTRA NOTIFICA LIMITE BUDGET
  // -----------------------------------------------------------------------------
  Future<void> showBudgetLimitNotification({
    required double currentSpent,
    required double limit,
  }) async {
    // 📱 Dettagli notifica Android
    const androidDetails = AndroidNotificationDetails(
      _budgetAlertChannel,
      'Avvisi budget',
      channelDescription: 'Notifiche quando superi il limite di spesa mensile',
      importance: Importance.max,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
      styleInformation: BigTextStyleInformation(''),
    );

    // 🍎 Dettagli notifica iOS - ✅ FIX: Presentazione in foreground
    const iosDetails = DarwinNotificationDetails(
      presentAlert: true, // 🔑 CRITICO: Mostra anche in foreground
      presentBadge: true, // 🔑 Badge anche in foreground
      presentSound: true, // 🔑 Suona anche in foreground
      sound: 'default', // Suono di sistema
      badgeNumber: 1,
      interruptionLevel: InterruptionLevel.timeSensitive, // ⚡ Alta priorità
    );

    const notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    // 🔔 Mostra notifica immediata
    await _notifications.show(
      _budgetLimitId,
      '⚠️ Limite budget superato!',
      'Hai speso €${currentSpent.toStringAsFixed(2)} su €${limit.toStringAsFixed(2)} questo mese',
      notificationDetails,
    );

    debugPrint('⚠️ Notifica limite budget mostrata');
  }

  // -----------------------------------------------------------------------------
  // 🗑️ CANCELLA TUTTE LE NOTIFICHE
  // -----------------------------------------------------------------------------
  Future<void> cancelAllNotifications() async {
    await _notifications.cancelAll();
    debugPrint('🗑️ Tutte le notifiche cancellate');
  }

  // -----------------------------------------------------------------------------
  // 👆 GESTIONE TAP SU NOTIFICA (FOREGROUND)
  // -----------------------------------------------------------------------------
  void _onNotificationTapped(NotificationResponse response) {
    debugPrint('📱 Notifica tappata (foreground): ${response.id}');
    // Qui puoi navigare a schermate specifiche in base all'ID notifica
  }

  // -----------------------------------------------------------------------------
  // 👆 GESTIONE TAP SU NOTIFICA (BACKGROUND)
  // -----------------------------------------------------------------------------
  @pragma('vm:entry-point')
  static void _onNotificationTappedBackground(NotificationResponse response) {
    debugPrint('📱 Notifica tappata (background): ${response.id}');
  }

  // -----------------------------------------------------------------------------
  // 📊 VERIFICA SE LE NOTIFICHE SONO ABILITATE
  // -----------------------------------------------------------------------------
  Future<bool> areNotificationsEnabled() async {
    if (Platform.isAndroid) {
      final androidImplementation = _notifications
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      return await androidImplementation?.areNotificationsEnabled() ?? false;
    }

    // iOS - controlla i permessi
    if (Platform.isIOS) {
      final iosImplementation = _notifications
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >();

      if (iosImplementation != null) {
        // Verifica se l'utente ha concesso i permessi
        final settings = await iosImplementation.checkPermissions();
        return settings?.isEnabled ?? false;
      }
    }

    return true;
  }

  // -----------------------------------------------------------------------------
  // 🔢 RESETTA BADGE NOTIFICHE
  // -----------------------------------------------------------------------------
  /// Resetta il numero del badge sull'icona dell'app a 0
  /// Utile per rimuovere l'indicatore rosso quando l'utente apre l'app
  Future<void> clearBadge() async {
    // --- iOS ---
    if (Platform.isIOS) {
      await _notifications.show(
        0,
        '', // titolo vuoto
        '', // corpo vuoto
        const NotificationDetails(
          iOS: DarwinNotificationDetails(
            badgeNumber: 0, // azzera il badge
            presentAlert: false, // non mostra alert
            presentSound: false, // non suona
          ),
        ),
      );

      debugPrint('🔢 Badge iOS resettato senza suono o vibrazione');
    }

    // --- Android ---
    if (Platform.isAndroid) {
      // Su Android il badge si resetta solo se non ci sono notifiche attive
      await _notifications.cancelAll();
      debugPrint('🔢 Badge Android resettato');
    }
  }
}
