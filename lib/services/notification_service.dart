import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz;
import 'dart:io' show Platform;

/// FILE: notification_service.dart
/// DESCRIZIONE: Service per la gestione delle notifiche locali.
/// Astrarre la complessità del plugin 'flutter_local_notifications', gestendo:
/// 1. Configurazione canali Android e permessi iOS.
/// 2. Calcolo delle date per notifiche ricorrenti (Scheduling).
/// 3. Trigger immediati per avvisi critici (es. Budget superato).

class NotificationService {
  // --- CONFIGURAZIONE PLUGIN ---
  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  // ID costanti per evitare sovrapposizioni o duplicati
  static const int _dailyReminderId = 0;
  static const int _budgetLimitId = 1;

  // Canali Android (richiesti per Android 8.0+)
  static const String _dailyReminderChannel = 'daily_reminder';
  static const String _budgetAlertChannel = 'budget_alert';

  // --- INIZIALIZZAZIONE ---
  // Configura i settings specifici per piattaforma e inizializza i fusi orari.
  // Su iOS, configura anche la presentazione delle notifiche quando l'app è in primo piano.
  // 
  Future<void> initialize() async {
    // Setup Timezone (essenziale per zonedSchedule)
    tz.initializeTimeZones();
    
    try {
      // Usa flutter_timezone per ottenere il timezone IANA corretto dalle API native
      // Questo restituisce sempre una stringa valida come "Europe/Rome" o "America/New_York"
      final timezoneInfo = await FlutterTimezone.getLocalTimezone();
      final String timeZoneName = timezoneInfo.identifier;
      
      tz.setLocalLocation(tz.getLocation(timeZoneName));
      debugPrint('✅ Fuso orario rilevato e impostato: $timeZoneName');
      
    } catch (e) {
      // Questo catch scatta solo se il database timezone locale è corrotto 
      // o se il device restituisce qualcosa di assurdo
      debugPrint('⚠️ Errore rilevamento timezone: $e. Uso fallback.');
      _setLocationByOffset();
    }

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');

    // Configurazione iOS: Richiede permessi e abilita alert in foreground
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

    // Richiesta permessi specifica per iOS post-init
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

  // Metodo di fallback per impostare il timezone basandosi sull'offset UTC
  // Usato solo come ultima risorsa in caso di errori critici
  void _setLocationByOffset() {
    final now = DateTime.now();
    final offset = now.timeZoneOffset;
    
    // Trova un timezone che corrisponde all'offset corrente
    final locations = tz.timeZoneDatabase.locations;
    
    for (final location in locations.values) {
      final tzDateTime = tz.TZDateTime.now(location);
      if (tzDateTime.timeZoneOffset == offset) {
        tz.setLocalLocation(location);
        debugPrint('✅ Fuso orario impostato tramite offset: ${location.name}');
        return;
      }
    }
    
    // Ultimo fallback: usa UTC
    tz.setLocalLocation(tz.getLocation('UTC'));
    debugPrint('⚠️ Uso UTC come fallback finale');
  }

  // --- CANALI ANDROID ---
  // Crea i canali di notifica necessari per Android O e superiori.
  // Definisce l'importanza e il comportamento (suono, vibrazione) per ogni tipo di avviso.
  Future<void> _createAndroidChannels() async {
    const dailyChannel = AndroidNotificationChannel(
      _dailyReminderChannel,
      'Promemoria giornaliero',
      description: 'Notifiche per ricordarti di inserire le spese',
      importance: Importance.high,
      enableVibration: true,
      playSound: true,
    );

    const budgetChannel = AndroidNotificationChannel(
      _budgetAlertChannel,
      'Avvisi budget',
      description: 'Notifiche quando superi il limite di spesa mensile',
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

  // --- GESTIONE PERMESSI ---
  // Wrapper per richiedere o verificare i permessi su entrambe le piattaforme.
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
  // Calcola la prossima occorrenza dell'orario scelto.
  // Se l'orario è già passato per la giornata odierna, programma per il giorno successivo.
  // 
  Future<void> scheduleDailyReminder({required TimeOfDay time}) async {
    await cancelDailyReminder();

    final now = DateTime.now();
    var scheduledDate = DateTime(
      now.year,
      now.month,
      now.day,
      time.hour,
      time.minute,
    );

    // Logica "Next Day": Se è passato, aggiungi 24h
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    final tzScheduledDate = tz.TZDateTime.from(scheduledDate, tz.local);

    const androidDetails = AndroidNotificationDetails(
      _dailyReminderChannel,
      'Promemoria giornaliero',
      channelDescription: 'Notifiche per ricordarti di inserire le spese',
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
      '💰 Promemoria spese',
      'Non dimenticare di inserire le tue spese di oggi!',
      tzScheduledDate,
      notificationDetails,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time, // Ripeti ogni giorno alla stessa ora
    );

    debugPrint('✅ Notifica programmata per: $tzScheduledDate');
  }

  // --- TRIGGER IMMEDIATI (BUDGET) ---
  // Mostra una notifica istantanea ad alta priorità quando il budget viene superato.
  // 
  Future<void> showBudgetLimitNotification({
    required double currentSpent,
    required double limit,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      _budgetAlertChannel,
      'Avvisi budget',
      channelDescription: 'Notifiche quando superi il limite di spesa mensile',
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
      '⚠️ Limite budget superato!',
      'Hai speso €${currentSpent.toStringAsFixed(2)} su €${limit.toStringAsFixed(2)} questo mese',
      const NotificationDetails(android: androidDetails, iOS: iosDetails),
    );
  }

  // --- CANCELLAZIONE E PULIZIA ---
  // Metodi per rimuovere notifiche programmate, cancellare tutto o resettare i badge.
  Future<void> cancelDailyReminder() async {
    await _notifications.cancel(_dailyReminderId);
  }

  Future<void> cancelAllNotifications() async {
    await _notifications.cancelAll();
  }

  Future<void> clearBadge() async {
    if (Platform.isIOS) {
      // Su iOS, resettiamo il badge inviando una notifica "silenziosa" o settando il numero
      // (Qui simuliamo un reset tramite dettaglio notifica vuota ma con badge 0)
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
  void _onNotificationTapped(NotificationResponse response) {
    debugPrint('📱 Notifica tappata (foreground): ${response.id}');
  }

  @pragma('vm:entry-point')
  static void _onNotificationTappedBackground(NotificationResponse response) {
    debugPrint('📱 Notifica tappata (background): ${response.id}');
  }

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