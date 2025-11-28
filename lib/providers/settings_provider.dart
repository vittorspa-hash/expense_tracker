// settings_provider.dart
// -----------------------------------------------------------------------------
// ⚙️ PROVIDER IMPOSTAZIONI
// -----------------------------------------------------------------------------
// Gestisce lo stato e la persistenza delle impostazioni dell'app:
// - Notifiche giornaliere (attivo/disattivo, orario)
// - Limite spesa mensile (attivo/disattivo, importo)
// - Salvataggio in SharedPreferences
// - Integrazione con NotificationService
// -----------------------------------------------------------------------------

import 'package:expense_tracker/services/notification_service.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsProvider with ChangeNotifier {
  // 🔧 SharedPreferences
  late SharedPreferences _prefs;

  // 🔔 Stati notifiche
  bool _dailyReminderEnabled = false;
  TimeOfDay _reminderTime = const TimeOfDay(hour: 20, minute: 0);
  bool _limitAlertEnabled = false;
  double _monthlyLimit = 1000.0;

  // 📱 Servizio notifiche
  final NotificationService _notificationService = NotificationService();

  // 🔑 Chiavi SharedPreferences
  static const String _keyDailyReminderEnabled = 'daily_reminder_enabled';
  static const String _keyReminderHour = 'reminder_hour';
  static const String _keyReminderMinute = 'reminder_minute';
  static const String _keyLimitAlertEnabled = 'limit_alert_enabled';
  static const String _keyMonthlyLimit = 'monthly_limit';

  // -----------------------------------------------------------------------------
  // 📖 GETTERS
  // -----------------------------------------------------------------------------
  bool get dailyReminderEnabled => _dailyReminderEnabled;
  TimeOfDay get reminderTime => _reminderTime;
  bool get limitAlertEnabled => _limitAlertEnabled;
  double get monthlyLimit => _monthlyLimit;

  // -----------------------------------------------------------------------------
  // 🚀 INIZIALIZZAZIONE
  // -----------------------------------------------------------------------------
  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
    
    // Inizializza servizio notifiche
    await _notificationService.initialize();
    
    // Carica impostazioni salvate
    await _loadSettings();
    
    // Se le notifiche giornaliere erano attive, riprogrammale
    if (_dailyReminderEnabled) {
      await _notificationService.scheduleDailyReminder(time: _reminderTime);
    }
  }

  // -----------------------------------------------------------------------------
  // 📥 CARICA IMPOSTAZIONI
  // -----------------------------------------------------------------------------
  Future<void> _loadSettings() async {
    _dailyReminderEnabled = _prefs.getBool(_keyDailyReminderEnabled) ?? false;
    
    final hour = _prefs.getInt(_keyReminderHour) ?? 20;
    final minute = _prefs.getInt(_keyReminderMinute) ?? 0;
    _reminderTime = TimeOfDay(hour: hour, minute: minute);
    
    _limitAlertEnabled = _prefs.getBool(_keyLimitAlertEnabled) ?? false;
    _monthlyLimit = _prefs.getDouble(_keyMonthlyLimit) ?? 1000.0;
    
    notifyListeners();
  }

  // -----------------------------------------------------------------------------
  // 💾 SALVA IMPOSTAZIONI
  // -----------------------------------------------------------------------------
  Future<void> _saveSettings() async {
    await _prefs.setBool(_keyDailyReminderEnabled, _dailyReminderEnabled);
    await _prefs.setInt(_keyReminderHour, _reminderTime.hour);
    await _prefs.setInt(_keyReminderMinute, _reminderTime.minute);
    await _prefs.setBool(_keyLimitAlertEnabled, _limitAlertEnabled);
    await _prefs.setDouble(_keyMonthlyLimit, _monthlyLimit);
  }

  // -----------------------------------------------------------------------------
  // 🔔 TOGGLE PROMEMORIA GIORNALIERO
  // -----------------------------------------------------------------------------
  Future<void> toggleDailyReminder(bool enabled) async {
    _dailyReminderEnabled = enabled;
    
    if (enabled) {
      // Richiedi permessi se necessario
      final hasPermission = await _notificationService.requestPermissions();
      
      if (hasPermission) {
        // Programma notifica
        await _notificationService.scheduleDailyReminder(time: _reminderTime);
        debugPrint('✅ Promemoria giornaliero attivato');
      } else {
        // Permessi negati, disabilita
        _dailyReminderEnabled = false;
        debugPrint('❌ Permessi notifiche negati');
      }
    } else {
      // Cancella notifica
      await _notificationService.cancelDailyReminder();
      debugPrint('🗑️ Promemoria giornaliero disattivato');
    }
    
    await _saveSettings();
    notifyListeners();
  }

  // -----------------------------------------------------------------------------
  // 🕐 CAMBIA ORARIO PROMEMORIA
  // -----------------------------------------------------------------------------
  Future<void> setReminderTime(TimeOfDay time) async {
    _reminderTime = time;
    
    // Se il promemoria è attivo, riprogramma la notifica
    if (_dailyReminderEnabled) {
      await _notificationService.scheduleDailyReminder(time: time);
      debugPrint('🔄 Orario promemoria aggiornato: ${time.format}');
    }
    
    await _saveSettings();
    notifyListeners();
  }

  // -----------------------------------------------------------------------------
  // 💰 TOGGLE AVVISO LIMITE SPESA
  // -----------------------------------------------------------------------------
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

  // -----------------------------------------------------------------------------
  // 💶 IMPOSTA LIMITE MENSILE
  // -----------------------------------------------------------------------------
  Future<void> setMonthlyLimit(double limit) async {
    _monthlyLimit = limit;
    await _saveSettings();
    notifyListeners();
    
    debugPrint('💰 Limite mensile impostato: €${limit.toStringAsFixed(2)}');
  }

  // -----------------------------------------------------------------------------
  // ⚠️ VERIFICA LIMITE SPESA
  // -----------------------------------------------------------------------------
  /// Verifica se la spesa mensile ha superato il limite
  /// Se sì, mostra una notifica
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

  // -----------------------------------------------------------------------------
  // 🔄 RESET IMPOSTAZIONI
  // -----------------------------------------------------------------------------
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