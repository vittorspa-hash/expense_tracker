import 'package:expense_tracker/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:expense_tracker/services/notification_service.dart';

/// FILE: notification_provider.dart
/// DESCRIZIONE: Provider per la gestione dello stato delle notifiche.
/// Gestisce SOLO lo stato UI e orchestra le chiamate al service.
/// La business logic (quando notificare) è delegata a NotificationService.
/// La localizzazione dei testi rimane responsabilità del Provider (è UI).

class NotificationProvider extends ChangeNotifier {
  final NotificationService _notificationService;

  NotificationProvider({required NotificationService notificationService})
      : _notificationService = notificationService;

  // --- STATO ---
  // Variabili di stato per configurare i promemoria e i limiti di spesa.
  bool _dailyReminderEnabled = false;
  TimeOfDay _reminderTime = const TimeOfDay(hour: 20, minute: 0);
  bool _limitAlertEnabled = false;
  double _monthlyLimit = 1000.0;

  // --- GETTERS ---
  bool get dailyReminderEnabled => _dailyReminderEnabled;
  TimeOfDay get reminderTime => _reminderTime;
  bool get limitAlertEnabled => _limitAlertEnabled;
  double get monthlyLimit => _monthlyLimit;

  // --- CICLO DI VITA (INIT) ---
  // Inizializza il servizio di notifiche e carica le preferenze salvate.
  // Nota: La schedulazione effettiva delle notifiche viene rimandata a un metodo successivo
  // (rescheduleNotifications) poiché in questa fase le traduzioni (l10n) non sono ancora disponibili.
  Future<void> initialize() async {
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
  // Carica le impostazioni dal service o imposta valori di default.
  Future<void> _loadSettings() async {
    _dailyReminderEnabled = _notificationService.getDailyReminderEnabled();
    
    final hour = _notificationService.getReminderHour();
    final minute = _notificationService.getReminderMinute();
    _reminderTime = TimeOfDay(hour: hour, minute: minute);
    
    _limitAlertEnabled = _notificationService.getLimitAlertEnabled();
    _monthlyLimit = _notificationService.getMonthlyLimit();
    
    notifyListeners();
  }

  // Salva lo stato corrente delle impostazioni tramite il service.
  Future<void> _saveSettings() async {
    await _notificationService.saveDailyReminderEnabled(_dailyReminderEnabled);
    await _notificationService.saveReminderTime(_reminderTime.hour, _reminderTime.minute);
    await _notificationService.saveLimitAlertEnabled(_limitAlertEnabled);
    await _notificationService.saveMonthlyLimit(_monthlyLimit);
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

  // --- ORCHESTRAZIONE: VERIFICA BUDGET ---
  
  /// Orchestrazione: Prepara i testi localizzati (UI) e delega la decisione al service
  /// La business logic (se notificare) è TUTTA nel NotificationService
  Future<void> checkBudgetLimit(
    double currentMonthlySpent,
    AppLocalizations l10n,
    String currencySymbol,
  ) async {
    // RESPONSABILITÀ UI: Preparare i testi localizzati
    final String title = l10n.notificationBudgetTitle;
    final String spentString = "$currencySymbol${currentMonthlySpent.toStringAsFixed(2)}";
    final String limitString = "$currencySymbol${_monthlyLimit.toStringAsFixed(2)}";
    final String body = l10n.notificationBudgetBody(spentString, limitString);
    
    // DELEGA TUTTA LA DECISIONE AL SERVICE (when + how)
    await _notificationService.checkAndNotifyBudgetLimit(
      currentMonthlySpent: currentMonthlySpent,
      monthlyLimit: _monthlyLimit,
      alertEnabled: _limitAlertEnabled,
      title: title,
      body: body,
    );
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