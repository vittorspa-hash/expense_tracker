import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io' show Platform;

/// FILE: notification_service.dart
/// DESCRIZIONE: Service Layer per la gestione delle notifiche locali e persistenza.
/// Si occupa dell'inizializzazione del plugin, della configurazione dei fusi orari,
/// della gestione dei permessi, della schedulazione delle notifiche (promemoria giornalieri
/// e avvisi di superamento del budget) e della persistenza delle impostazioni.
/// CONTIENE TUTTA LA BUSINESS LOGIC relativa a quando e come notificare.

class NotificationService {
  final SharedPreferences _prefs;

  NotificationService({required SharedPreferences sharedPreferences})
      : _prefs = sharedPreferences;

  // --- CONFIGURAZIONE PLUGIN ---
  // Istanza principale del plugin e costanti per ID e Canali.
  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  static const int _dailyReminderId = 0;
  static const int _budgetLimitId = 1;

  static const String _dailyReminderChannel = 'daily_reminder';
  static const String _budgetAlertChannel = 'budget_alert';

  static const String _keyDailyReminderEnabled = 'daily_reminder_enabled';
  static const String _keyReminderHour = 'reminder_hour';
  static const String _keyReminderMinute = 'reminder_minute';
  static const String _keyLimitAlertEnabled = 'limit_alert_enabled';
  static const String _keyMonthlyLimit = 'monthly_limit';

  // --- INIZIALIZZAZIONE ---
  // Configura il sistema di notifiche all'avvio dell'app.
  // Inizializza SharedPreferences, il database dei fusi orari (essenziale per le notifiche schedulate),
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
      'Daily Reminder',
      description: 'Notifications to remind you to track expenses',
      importance: Importance.high,
      enableVibration: true,
      playSound: true,
    );

    const budgetChannel = AndroidNotificationChannel(
      _budgetAlertChannel,
      'Budget Alerts',
      description: 'Notifications when you exceed your monthly spending limit',
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

  // --- PERSISTENZA (LOAD/SAVE) ---
  // Carica le impostazioni da SharedPreferences o restituisce valori di default.
  bool getDailyReminderEnabled() {
    return _prefs.getBool(_keyDailyReminderEnabled) ?? false;
  }

  int getReminderHour() {
    return _prefs.getInt(_keyReminderHour) ?? 20;
  }

  int getReminderMinute() {
    return _prefs.getInt(_keyReminderMinute) ?? 0;
  }

  bool getLimitAlertEnabled() {
    return _prefs.getBool(_keyLimitAlertEnabled) ?? false;
  }

  double getMonthlyLimit() {
    return _prefs.getDouble(_keyMonthlyLimit) ?? 1000.0;
  }

  // Salva le impostazioni su SharedPreferences.
  Future<void> saveDailyReminderEnabled(bool enabled) async {
    await _prefs.setBool(_keyDailyReminderEnabled, enabled);
  }

  Future<void> saveReminderTime(int hour, int minute) async {
    await _prefs.setInt(_keyReminderHour, hour);
    await _prefs.setInt(_keyReminderMinute, minute);
  }

  Future<void> saveLimitAlertEnabled(bool enabled) async {
    await _prefs.setBool(_keyLimitAlertEnabled, enabled);
  }

  Future<void> saveMonthlyLimit(double limit) async {
    await _prefs.setDouble(_keyMonthlyLimit, limit);
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
      'Daily Reminder',
      channelDescription: 'Notifications to remind you to track expenses',
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
      title,
      body,
      tzScheduledDate,
      notificationDetails,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );

    debugPrint('✅ Notifica programmata per: $tzScheduledDate con testo: "$title"');
  }

  // --- BUSINESS LOGIC: VERIFICA E NOTIFICA BUDGET ---
  
  /// BUSINESS LOGIC: Decide se notificare il superamento budget
  /// Contiene TUTTE le regole: alert abilitato, confronto con limite
  Future<void> checkAndNotifyBudgetLimit({
    required double currentMonthlySpent,
    required double monthlyLimit,
    required bool alertEnabled,
    required String title,
    required String body,
  }) async {
    // REGOLA 1: Se alert disabilitato, non fare nulla
    if (!alertEnabled) {
      debugPrint('⏭️ Avviso budget disabilitato, skip notifica');
      return;
    }
    
    // REGOLA 2: Se non ha superato il limite, non fare nulla
    if (currentMonthlySpent < monthlyLimit) {
      debugPrint('✅ Budget OK: ${currentMonthlySpent.toStringAsFixed(2)} < ${monthlyLimit.toStringAsFixed(2)}');
      return;
    }
    
    // REGOLA 3: Superamento rilevato, invia notifica
    await _showBudgetLimitNotification(title: title, body: body);
    debugPrint('⚠️ Limite budget superato! ${currentMonthlySpent.toStringAsFixed(2)} >= ${monthlyLimit.toStringAsFixed(2)}');
  }

  // --- TRIGGER IMMEDIATI (BUDGET) - METODO PRIVATO ---
  // Mostra immediatamente una notifica ad alta priorità.
  // Utilizzato internamente da checkAndNotifyBudgetLimit.
  Future<void> _showBudgetLimitNotification({
    required String title,
    required String body,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      _budgetAlertChannel,
      'Budget Alerts',
      channelDescription: 'Notifications when you exceed your monthly spending limit',
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
      title,
      body,
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