import 'package:expense_tracker/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:expense_tracker/services/notification_service.dart';

/// FILE: notification_provider.dart
/// DESCRIZIONE: Provider per la gestione dello stato delle notifiche.
/// Gestisce la logica di business relativa ai promemoria e agli avvisi di budget,
/// occupandosi della persistenza delle preferenze utente, della localizzazione dei testi
/// e della comunicazione con il NotificationService.

class NotificationProvider extends ChangeNotifier {
  final NotificationService _notificationService;

  NotificationProvider({required NotificationService notificationService})
      : _notificationService = notificationService;

  // --- STATO E PERSISTENZA ---
  // Variabili di stato per configurare i promemoria e i limiti di spesa.
  late SharedPreferences _prefs;

  bool _dailyReminderEnabled = false;
  TimeOfDay _reminderTime = const TimeOfDay(hour: 20, minute: 0);
  bool _limitAlertEnabled = false;
  double _monthlyLimit = 1000.0;

  static const String _keyDailyReminderEnabled = 'daily_reminder_enabled';
  static const String _keyReminderHour = 'reminder_hour';
  static const String _keyReminderMinute = 'reminder_minute';
  static const String _keyLimitAlertEnabled = 'limit_alert_enabled';
  static const String _keyMonthlyLimit = 'monthly_limit';

  // --- GETTERS ---
  bool get dailyReminderEnabled => _dailyReminderEnabled;
  TimeOfDay get reminderTime => _reminderTime;
  bool get limitAlertEnabled => _limitAlertEnabled;
  double get monthlyLimit => _monthlyLimit;

  // --- CICLO DI VITA (INIT) ---
  // Inizializza il servizio di notifiche e carica le preferenze salvate su disco.
  // Nota: La schedulazione effettiva delle notifiche viene rimandata a un metodo successivo
  // (rescheduleNotifications) poiché in questa fase le traduzioni (l10n) non sono ancora disponibili.
  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
    
    await _notificationService.initialize();
    await _loadSettings();
  }
  
  // Metodo da invocare all'avvio della UI principale (es. Home Screen).
  // Serve per ripristinare o aggiornare le notifiche pianificate utilizzando
  // la lingua corrente dell'utente, garantendo che i testi siano localizzati correttamente.
  Future<void> rescheduleNotifications(AppLocalizations l10n) async {
    if (_dailyReminderEnabled) {
      await _notificationService.scheduleDailyReminder(
        time: _reminderTime,
        title: l10n.notificationDailyTitle,
        body: l10n.notificationDailyBody,
      );
      debugPrint('🔄 Notifiche rischedulate con lingua: ${l10n.localeName}');
    }
  }

  // --- PERSISTENZA (LOAD/SAVE) ---
  // Carica le impostazioni da SharedPreferences o imposta valori di default.
  Future<void> _loadSettings() async {
    _dailyReminderEnabled = _prefs.getBool(_keyDailyReminderEnabled) ?? false;
    
    final hour = _prefs.getInt(_keyReminderHour) ?? 20;
    final minute = _prefs.getInt(_keyReminderMinute) ?? 0;
    _reminderTime = TimeOfDay(hour: hour, minute: minute);
    
    _limitAlertEnabled = _prefs.getBool(_keyLimitAlertEnabled) ?? false;
    _monthlyLimit = _prefs.getDouble(_keyMonthlyLimit) ?? 1000.0;
    
    notifyListeners();
  }

  // Salva lo stato corrente delle impostazioni su disco.
  Future<void> _saveSettings() async {
    await _prefs.setBool(_keyDailyReminderEnabled, _dailyReminderEnabled);
    await _prefs.setInt(_keyReminderHour, _reminderTime.hour);
    await _prefs.setInt(_keyReminderMinute, _reminderTime.minute);
    await _prefs.setBool(_keyLimitAlertEnabled, _limitAlertEnabled);
    await _prefs.setDouble(_keyMonthlyLimit, _monthlyLimit);
  }

  // --- GESTIONE PROMEMORIA GIORNALIERO ---
  // Attiva o disattiva il promemoria giornaliero.
  // Gestisce la richiesta dei permessi di notifica al sistema operativo e,
  // se concessi, pianifica la notifica utilizzando i testi localizzati forniti.
  Future<void> toggleDailyReminder(bool enabled, AppLocalizations l10n) async {
    _dailyReminderEnabled = enabled;
    
    if (enabled) {
      final hasPermission = await _notificationService.requestPermissions();
      
      if (hasPermission) {
        // Passiamo titolo e corpo presi dal file .arb
        await _notificationService.scheduleDailyReminder(
          time: _reminderTime,
          title: l10n.notificationDailyTitle,
          body: l10n.notificationDailyBody,
        );
        debugPrint('✅ Promemoria giornaliero attivato');
      } else {
        _dailyReminderEnabled = false;
        debugPrint('❌ Permessi notifiche negati');
      }
    } else {
      await _notificationService.cancelDailyReminder();
      debugPrint('🗑️ Promemoria giornaliero disattivato');
    }
    
    await _saveSettings();
    notifyListeners();
  }

  // Modifica l'orario del promemoria.
  // Se il promemoria è attivo, lo riprogramma immediatamente con il nuovo orario
  // mantenendo i testi localizzati aggiornati.
  Future<void> setReminderTime(TimeOfDay time, AppLocalizations l10n) async {
    _reminderTime = time;
    
    if (_dailyReminderEnabled) {
      // Riprogrammiamo con i nuovi orari e le stringhe tradotte
      await _notificationService.scheduleDailyReminder(
        time: time,
        title: l10n.notificationDailyTitle,
        body: l10n.notificationDailyBody,
      );
      final hour = time.hour.toString().padLeft(2, '0');
      final minute = time.minute.toString().padLeft(2, '0');
      debugPrint('🔄 Orario promemoria aggiornato: $hour:$minute');
    }
    
    await _saveSettings();
    notifyListeners();
  }

  // --- GESTIONE LIMITE BUDGET ---
  // Attiva o disattiva il controllo del limite di budget.
  // Nota: Questo metodo gestisce solo il flag di stato, la logica di notifica
  // risiede in checkBudgetLimit.
  Future<void> toggleLimitAlert(bool enabled) async {
    _limitAlertEnabled = enabled;
    await _saveSettings();
    notifyListeners();
    
    if (enabled) {
      debugPrint('✅ Avviso limite spesa attivato (€$_monthlyLimit)');
    } else {
      debugPrint('🗑️ Avviso limite spesa disattivato');
    }
  }

  // Imposta l'importo massimo del budget mensile.
  Future<void> setMonthlyLimit(double limit) async {
    _monthlyLimit = limit;
    await _saveSettings();
    notifyListeners();
    debugPrint('💰 Limite mensile impostato: €${limit.toStringAsFixed(2)}');
  }

  // --- BUSINESS LOGIC (CHECK SPESA) ---
  // Verifica se la spesa corrente ha superato il limite mensile impostato.
  // Se il limite è superato e l'avviso è abilitato, genera dinamicamente il testo
  // della notifica (con i valori monetari formattati) e la invia immediatamente.
  Future<void> checkBudgetLimit(double currentMonthlySpent, AppLocalizations l10n, String currencySymbol) async {
    if (!_limitAlertEnabled) return;
    
    if (currentMonthlySpent >= _monthlyLimit) {
      
      // Recuperiamo le stringhe tradotte dal file .arb
      final String title = l10n.notificationBudgetTitle;
      
      // Formattiamo i numeri come stringhe (come richiesto dal tuo .arb)
      final String spentString = "$currencySymbol${currentMonthlySpent.toStringAsFixed(2)}";
      final String limitString = "$currencySymbol${_monthlyLimit.toStringAsFixed(2)}";
      
      // Generiamo il body usando il metodo generato da Flutter
      final String body = l10n.notificationBudgetBody(spentString, limitString);

      // Chiamiamo il service con le stringhe pronte
      await _notificationService.showBudgetLimitNotification(
        title: title,
        body: body,
      );
      
      debugPrint('⚠️ Limite budget superato! $body');
    }
  }

  // --- RESET ---
  // Ripristina tutte le impostazioni ai valori predefiniti e cancella
  // tutte le notifiche pendenti.
  Future<void> resetSettings() async {
    await _notificationService.cancelAllNotifications();
    
    _dailyReminderEnabled = false;
    _reminderTime = const TimeOfDay(hour: 20, minute: 0);
    _limitAlertEnabled = false;
    _monthlyLimit = 1000.0;
    
    await _saveSettings();
    notifyListeners();
    
    debugPrint('🔄 Impostazioni resettate ai valori predefiniti');
  }
}