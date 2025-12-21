import 'package:expense_tracker/services/notification_service.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// FILE: notification_provider.dart 
/// DESCRIZIONE: State Manager per le impostazioni legate alle notifiche.
/// Gestisce la persistenza delle preferenze utente (SharedPreferences) e coordina
/// il NotificationService per programmare o cancellare gli avvisi.
/// Include la logica di business per verificare il superamento del budget.

class NotificationProvider extends ChangeNotifier {
  final NotificationService _notificationService;

  NotificationProvider({required NotificationService notificationService})
      : _notificationService = notificationService;

  // --- STATO E PERSISTENZA ---
  late SharedPreferences _prefs;

  // Variabili di stato (con valori di default)
  bool _dailyReminderEnabled = false;
  TimeOfDay _reminderTime = const TimeOfDay(hour: 20, minute: 0);
  bool _limitAlertEnabled = false;
  double _monthlyLimit = 1000.0;

  // Chiavi per SharedPreferences
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
  // Inizializza il servizio di notifiche, carica le preferenze dal disco
  // e, se necessario, ripristina le notifiche programmate (resilienza al riavvio).
  // 
  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
    
    await _notificationService.initialize();
    await _loadSettings();
    
    if (_dailyReminderEnabled) {
      await _notificationService.scheduleDailyReminder(time: _reminderTime);
    }
  }

  // --- PERSISTENZA (LOAD/SAVE) ---
  Future<void> _loadSettings() async {
    _dailyReminderEnabled = _prefs.getBool(_keyDailyReminderEnabled) ?? false;
    
    final hour = _prefs.getInt(_keyReminderHour) ?? 20;
    final minute = _prefs.getInt(_keyReminderMinute) ?? 0;
    _reminderTime = TimeOfDay(hour: hour, minute: minute);
    
    _limitAlertEnabled = _prefs.getBool(_keyLimitAlertEnabled) ?? false;
    _monthlyLimit = _prefs.getDouble(_keyMonthlyLimit) ?? 1000.0;
    
    notifyListeners();
  }

  Future<void> _saveSettings() async {
    await _prefs.setBool(_keyDailyReminderEnabled, _dailyReminderEnabled);
    await _prefs.setInt(_keyReminderHour, _reminderTime.hour);
    await _prefs.setInt(_keyReminderMinute, _reminderTime.minute);
    await _prefs.setBool(_keyLimitAlertEnabled, _limitAlertEnabled);
    await _prefs.setDouble(_keyMonthlyLimit, _monthlyLimit);
  }

  // --- GESTIONE PROMEMORIA GIORNALIERO ---
  // Attiva o disattiva il promemoria.
  // Include la logica di richiesta permessi: se negati, lo switch torna su off.
  // 
  Future<void> toggleDailyReminder(bool enabled) async {
    _dailyReminderEnabled = enabled;
    
    if (enabled) {
      // Richiedi permessi al sistema operativo
      final hasPermission = await _notificationService.requestPermissions();
      
      if (hasPermission) {
        await _notificationService.scheduleDailyReminder(time: _reminderTime);
        debugPrint('✅ Promemoria giornaliero attivato');
      } else {
        // Rollback se permessi negati
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

  Future<void> setReminderTime(TimeOfDay time) async {
    _reminderTime = time;
    
    // Riprogramma immediatamente se attivo
    if (_dailyReminderEnabled) {
      await _notificationService.scheduleDailyReminder(time: time);
      debugPrint('🔄 Orario promemoria aggiornato: ${time.format}');
    }
    
    await _saveSettings();
    notifyListeners();
  }

  // --- GESTIONE LIMITE BUDGET ---
  // Configurazione della soglia di spesa mensile.
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

  Future<void> setMonthlyLimit(double limit) async {
    _monthlyLimit = limit;
    await _saveSettings();
    notifyListeners();
    
    debugPrint('💰 Limite mensile impostato: €${limit.toStringAsFixed(2)}');
  }

  // --- BUSINESS LOGIC (CHECK SPESA) ---
  // Metodo cruciale chiamato dall'ExpenseProvider ogni volta che una spesa cambia.
  // Confronta il totale attuale con il limite impostato e, se superato, innesca l'avviso.
  // 
  Future<void> checkBudgetLimit(double currentMonthlySpent) async {
    if (!_limitAlertEnabled) return;
    
    if (currentMonthlySpent >= _monthlyLimit) {
      await _notificationService.showBudgetLimitNotification(
        currentSpent: currentMonthlySpent,
        limit: _monthlyLimit,
      );
      
      debugPrint('⚠️ Limite budget superato! €$currentMonthlySpent / €$_monthlyLimit');
    }
  }

  // --- RESET ---
  // Ripristina tutte le impostazioni ai valori di fabbrica e cancella le notifiche pendenti.
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