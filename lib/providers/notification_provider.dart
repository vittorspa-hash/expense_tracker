import 'package:expense_tracker/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:expense_tracker/services/notification_service.dart';

/// FILE: notification_provider.dart
/// DESCRIZIONE: State Manager per le notifiche (ChangeNotifier).
/// Gestisce ESCLUSIVAMENTE lo stato UI e orchestra le chiamate al service.
/// La business logic (quando notificare) è delegata a NotificationService.
/// La localizzazione dei testi rimane responsabilità del Provider poiché è un aspetto UI.

class NotificationProvider extends ChangeNotifier {
  // --- STATO E DIPENDENZE ---
  // Iniezione del servizio di notifiche per la gestione della logica di pianificazione.
  
  final NotificationService _notificationService;

  NotificationProvider({required NotificationService notificationService})
      : _notificationService = notificationService;

  // --- STATO ---
  // Variabili di stato per configurare i promemoria giornalieri e i limiti di budget.
  // Questi valori vengono persistiti tramite il service e caricati all'inizializzazione.
  
  bool _dailyReminderEnabled = false;
  TimeOfDay _reminderTime = const TimeOfDay(hour: 20, minute: 0);
  bool _limitAlertEnabled = false;
  double _monthlyLimit = 1000.0;

  // --- GETTERS ---
  // Espongono lo stato delle impostazioni notifiche alla UI in modo read-only.
  
  bool get dailyReminderEnabled => _dailyReminderEnabled;
  TimeOfDay get reminderTime => _reminderTime;
  bool get limitAlertEnabled => _limitAlertEnabled;
  double get monthlyLimit => _monthlyLimit;

  // --- CICLO DI VITA (INIT) ---
  // Inizializza il servizio di notifiche e carica le preferenze salvate.
  // Nota: La schedulazione effettiva delle notifiche viene rimandata a rescheduleNotifications()
  // poiché in questa fase le traduzioni (l10n) non sono ancora disponibili.
  Future<void> initialize() async {
    try {
      await _notificationService.initialize();
      await _loadSettings();
    } catch (e) {
      debugPrint('❌ Errore inizializzazione notifiche: $e');
      // Fallback: disabilita tutte le notifiche per evitare stati inconsistenti
      _dailyReminderEnabled = false;
      _limitAlertEnabled = false;
      notifyListeners();
    }
  }
  
  // Metodo da invocare all'avvio della UI principale (es. Home Screen).
  // Ripristina o aggiorna le notifiche pianificate utilizzando la lingua corrente dell'utente,
  // garantendo che i testi siano localizzati correttamente anche dopo cambio lingua.
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
  // Carica le impostazioni delle notifiche dal service o imposta valori di default.
  // Tutte le preferenze vengono recuperate atomicamente per garantire consistenza.
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
  // Persiste tutte le preferenze per garantire che vengano mantenute tra sessioni.
  Future<void> _saveSettings() async {
    try {
      await _notificationService.saveDailyReminderEnabled(_dailyReminderEnabled);
      await _notificationService.saveReminderTime(_reminderTime.hour, _reminderTime.minute);
      await _notificationService.saveLimitAlertEnabled(_limitAlertEnabled);
      await _notificationService.saveMonthlyLimit(_monthlyLimit);
    } catch (e) {
      debugPrint('❌ Errore salvataggio impostazioni notifiche: $e');
      rethrow;
    }
  }

  // --- GESTIONE PROMEMORIA GIORNALIERO ---
  // Attiva o disattiva il promemoria giornaliero.
  // Gestisce la richiesta dei permessi di notifica al sistema operativo e,
  // se concessi, pianifica la notifica utilizzando i testi localizzati forniti.
  Future<void> toggleDailyReminder(bool enabled, AppLocalizations l10n) async {
    _dailyReminderEnabled = enabled;
    
    if (enabled) {
      // Richiede i permessi al sistema operativo (iOS/Android)
      final hasPermission = await _notificationService.requestPermissions();
      
      if (hasPermission) {
        // Pianifica il promemoria con testi localizzati dal file .arb
        await _notificationService.scheduleDailyReminder(
          time: _reminderTime,
          title: l10n.notificationDailyTitle,
          body: l10n.notificationDailyBody,
        );
        debugPrint('✅ Promemoria giornaliero attivato');
      } else {
        // Se l'utente nega i permessi, disabilita il promemoria
        _dailyReminderEnabled = false;
        debugPrint('❌ Permessi notifiche negati');
      }
    } else {
      // Cancella il promemoria pianificato
      await _notificationService.cancelDailyReminder();
      debugPrint('🗑️ Promemoria giornaliero disattivato');
    }
    
    await _saveSettings();
    notifyListeners();
  }

  // Modifica l'orario del promemoria giornaliero.
  // Se il promemoria è attivo, lo riprogramma immediatamente con il nuovo orario
  // mantenendo i testi localizzati aggiornati.
  Future<void> setReminderTime(TimeOfDay time, AppLocalizations l10n) async {
    _reminderTime = time;
    
    if (_dailyReminderEnabled) {
      // Riprogramma con il nuovo orario e testi tradotti nella lingua corrente
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
  // Attiva o disattiva il controllo del limite di budget mensile.
  // Quando attivo, l'utente riceverà notifiche al superamento del limite.
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
  // Il limite viene utilizzato per determinare quando inviare notifiche di superamento budget.
  Future<void> setMonthlyLimit(double limit) async {
    _monthlyLimit = limit;
    await _saveSettings();
    notifyListeners();
    debugPrint('💰 Limite mensile impostato: €${limit.toStringAsFixed(2)}');
  }

  // --- ORCHESTRAZIONE: VERIFICA BUDGET ---
  // Orchestrazione: Prepara i testi localizzati (responsabilità UI) e delega
  // la decisione di notificare al service (responsabilità business logic).
  // Questo metodo viene chiamato dal ExpenseProvider dopo operazioni che modificano le spese.
  Future<void> checkBudgetLimit(
    double currentMonthlySpent,
    AppLocalizations l10n,
    String currencySymbol,
  ) async {
    // RESPONSABILITÀ UI: Preparare i testi localizzati con valori formattati
    final String title = l10n.notificationBudgetTitle;
    final String spentString = "$currencySymbol${currentMonthlySpent.toStringAsFixed(2)}";
    final String limitString = "$currencySymbol${_monthlyLimit.toStringAsFixed(2)}";
    final String body = l10n.notificationBudgetBody(spentString, limitString);
    
    // DELEGA TUTTA LA DECISIONE AL SERVICE (quando e come notificare)
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
  // tutte le notifiche pendenti. Utile durante logout o reset dell'app.
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