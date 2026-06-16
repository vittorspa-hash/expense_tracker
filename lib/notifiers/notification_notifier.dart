import 'package:expense_tracker/config/di/riverpod_providers.dart';
import 'package:expense_tracker/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// FILE: notification_notifier.dart
/// DESCRIZIONE: Gestore dello stato delle notifiche e dei promemoria (NotificationState).
/// Utilizza un Notifier sincrono di Riverpod, reso possibile dall'iniezione di
/// SharedPreferences tramite override in main.dart. La build() inizializza il plugin
/// e carica le preferenze persistite; le azioni successive gestiscono la pianificazione
/// dei promemoria giornalieri e gli avvisi di superamento del budget mensile.

// --- STATO ---
class NotificationState {
  final bool dailyReminderEnabled;
  final TimeOfDay reminderTime;
  final bool limitAlertEnabled;
  final double monthlyLimit;

  const NotificationState({
    this.dailyReminderEnabled = false,
    this.reminderTime = const TimeOfDay(hour: 20, minute: 0),
    this.limitAlertEnabled = false,
    this.monthlyLimit = 1000.0,
  });

  NotificationState copyWith({
    bool? dailyReminderEnabled,
    TimeOfDay? reminderTime,
    bool? limitAlertEnabled,
    double? monthlyLimit,
  }) {
    return NotificationState(
      dailyReminderEnabled: dailyReminderEnabled ?? this.dailyReminderEnabled,
      reminderTime: reminderTime ?? this.reminderTime,
      limitAlertEnabled: limitAlertEnabled ?? this.limitAlertEnabled,
      monthlyLimit: monthlyLimit ?? this.monthlyLimit,
    );
  }
}

// --- NOTIFIER ---
/// Controller sincrono dello stato delle notifiche. La build() inizializza il plugin
/// e legge le preferenze persistite; in caso di errore (plugin non disponibile o
/// preferenze corrotte) ricade su uno stato di default con tutte le notifiche disabilitate.
class NotificationNotifier extends Notifier<NotificationState> {
  @override
  NotificationState build() {
    try {
      final notificationService = ref.watch(notificationServiceProvider);
      notificationService.initialize();
      final hour = notificationService.getReminderHour();
      final minute = notificationService.getReminderMinute();
      return NotificationState(
        dailyReminderEnabled: notificationService.getDailyReminderEnabled(),
        reminderTime: TimeOfDay(hour: hour, minute: minute),
        limitAlertEnabled: notificationService.getLimitAlertEnabled(),
        monthlyLimit: notificationService.getMonthlyLimit(),
      );
    } catch (e) {
      // Fallback: notifiche disabilitate se il plugin non è disponibile
      return const NotificationState(
        dailyReminderEnabled: false,
        limitAlertEnabled: false,
      );
    }
  }

  // --- RIPIANIFICAZIONE ---
  /// Ripianifica il promemoria giornaliero con le impostazioni correnti.
  /// Tipicamente chiamato al cambio di lingua per aggiornare i testi localizzati.
  Future<void> rescheduleNotifications(AppLocalizations l10n) async {
    final current = state;
    if (current.dailyReminderEnabled) {
      final notificationService = ref.read(notificationServiceProvider);
      await notificationService.scheduleDailyReminder(
        time: current.reminderTime,
        title: l10n.notificationDailyTitle,
        body: l10n.notificationDailyBody,
      );
    }
  }

  // --- PERSISTENZA ---
  /// Salva tutte le preferenze di notifica correnti tramite NotificationService.
  Future<void> _saveSettings() async {
    final current = state;
    final notificationService = ref.read(notificationServiceProvider);
    await notificationService.saveDailyReminderEnabled(current.dailyReminderEnabled);
    await notificationService.saveReminderTime(
      current.reminderTime.hour,
      current.reminderTime.minute,
    );
    await notificationService.saveLimitAlertEnabled(current.limitAlertEnabled);
    await notificationService.saveMonthlyLimit(current.monthlyLimit);
  }

  // --- AZIONI ED OPERAZIONI ---
  /// Abilita o disabilita il promemoria giornaliero. Se abilitato, richiede i permessi
  /// di sistema: in caso di diniego ripristina lo stato a disabilitato senza pianificare.
  Future<void> toggleDailyReminder(bool enabled, AppLocalizations l10n) async {
    state = state.copyWith(dailyReminderEnabled: enabled);
    final notificationService = ref.read(notificationServiceProvider);
    if (enabled) {
      final hasPermission = await notificationService.requestPermissions();
      if (hasPermission) {
        await notificationService.scheduleDailyReminder(
          time: state.reminderTime,
          title: l10n.notificationDailyTitle,
          body: l10n.notificationDailyBody,
        );
      } else {
        state = state.copyWith(dailyReminderEnabled: false);
      }
    } else {
      await notificationService.cancelDailyReminder();
    }
    await _saveSettings();
  }

  /// Aggiorna l'orario del promemoria e, se il reminder è attivo,
  /// ripianifica immediatamente la notifica con il nuovo orario.
  Future<void> setReminderTime(TimeOfDay time, AppLocalizations l10n) async {
    state = state.copyWith(reminderTime: time);
    if (state.dailyReminderEnabled) {
      final notificationService = ref.read(notificationServiceProvider);
      await notificationService.scheduleDailyReminder(
        time: time,
        title: l10n.notificationDailyTitle,
        body: l10n.notificationDailyBody,
      );
    }
    await _saveSettings();
  }

  /// Abilita o disabilita l'avviso di superamento del budget mensile.
  Future<void> toggleLimitAlert(bool enabled) async {
    state = state.copyWith(limitAlertEnabled: enabled);
    await _saveSettings();
  }

  /// Aggiorna la soglia del budget mensile utilizzata per gli avvisi.
  Future<void> setMonthlyLimit(double limit) async {
    state = state.copyWith(monthlyLimit: limit);
    await _saveSettings();
  }

  /// Verifica se la spesa mensile corrente supera il limite impostato
  /// e, se gli avvisi sono abilitati, invia una notifica localizzata.
  Future<void> checkBudgetLimit({
    required double currentMonthlySpent,
    required AppLocalizations l10n,
    required String currencySymbol,
  }) async {
    final current = state;
    final notificationService = ref.read(notificationServiceProvider);
    await notificationService.checkAndNotifyBudgetLimit(
      currentMonthlySpent: currentMonthlySpent,
      monthlyLimit: current.monthlyLimit,
      alertEnabled: current.limitAlertEnabled,
      title: l10n.notificationBudgetTitle,
      body: l10n.notificationBudgetBody(
        "$currencySymbol${currentMonthlySpent.toStringAsFixed(2)}",
        "$currencySymbol${current.monthlyLimit.toStringAsFixed(2)}",
      ),
    );
  }

  /// Annulla tutte le notifiche attive e ripristina lo stato ai valori di default,
  /// persistendo il reset tramite _saveSettings().
  Future<void> resetSettings() async {
    final notificationService = ref.read(notificationServiceProvider);
    await notificationService.cancelAllNotifications();
    state = const NotificationState();
    await _saveSettings();
  }
}