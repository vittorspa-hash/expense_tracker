import 'package:expense_tracker/config/di/riverpod_providers.dart';
import 'package:expense_tracker/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// FILE: notification_notifier.dart
/// DESCRIZIONE: Gestore dello stato delle notifiche e dei promemoria (NotificationState).
/// Gestisce la pianificazione dei promemoria giornalieri di inserimento spese,
/// gli avvisi di superamento del budget mensile e la persistenza delle preferenze.

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
class NotificationNotifier extends Notifier<NotificationState> {
  @override
  NotificationState build() {
    return const NotificationState();
  }

  // --- INIZIALIZZAZIONE ---
  /// Inizializza il canale di notifica nativo e carica le impostazioni salvate.
  Future<void> initialize() async {
    try {
      final notificationService = await ref.read(notificationServiceProvider.future);
      await notificationService.initialize();
      await _loadSettings();
    } catch (e) {
      state = const NotificationState(
        dailyReminderEnabled: false,
        limitAlertEnabled: false,
      );
    }
  }

  /// Rischedula il promemoria attivo per allinearlo alla nuova lingua dell'applicazione.
  Future<void> rescheduleNotifications(AppLocalizations l10n) async {
    if (state.dailyReminderEnabled) {
      final notificationService = await ref.read(notificationServiceProvider.future);
      await notificationService.scheduleDailyReminder(
        time: state.reminderTime,
        title: l10n.notificationDailyTitle,
        body: l10n.notificationDailyBody,
      );
    }
  }

  // --- PERSISTENZA ---
  Future<void> _loadSettings() async {
    final notificationService = await ref.read(notificationServiceProvider.future);
    final hour = notificationService.getReminderHour();
    final minute = notificationService.getReminderMinute();

    state = state.copyWith(
      dailyReminderEnabled: notificationService.getDailyReminderEnabled(),
      reminderTime: TimeOfDay(hour: hour, minute: minute),
      limitAlertEnabled: notificationService.getLimitAlertEnabled(),
      monthlyLimit: notificationService.getMonthlyLimit(),
    );
  }

  Future<void> _saveSettings() async {
    try {
      final notificationService = await ref.read(notificationServiceProvider.future);
      await notificationService.saveDailyReminderEnabled(state.dailyReminderEnabled);
      await notificationService.saveReminderTime(
        state.reminderTime.hour,
        state.reminderTime.minute,
      );
      await notificationService.saveLimitAlertEnabled(state.limitAlertEnabled);
      await notificationService.saveMonthlyLimit(state.monthlyLimit);
    } catch (e) {
      rethrow;
    }
  }

  // --- GESTIONE PROMEMORIA GIORNALIERO ---
  /// Attiva o disattiva il promemoria locale giornaliero richiedendo i permessi di sistema se necessario.
  Future<void> toggleDailyReminder(bool enabled, AppLocalizations l10n) async {
    state = state.copyWith(dailyReminderEnabled: enabled);
    final notificationService = await ref.read(notificationServiceProvider.future);

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

  /// Aggiorna l'orario del promemoria e ne pianifica nuovamente l'esecuzione se attivo.
  Future<void> setReminderTime(TimeOfDay time, AppLocalizations l10n) async {
    state = state.copyWith(reminderTime: time);

    if (state.dailyReminderEnabled) {
      final notificationService = await ref.read(notificationServiceProvider.future);
      await notificationService.scheduleDailyReminder(
        time: time,
        title: l10n.notificationDailyTitle,
        body: l10n.notificationDailyBody,
      );
    }

    await _saveSettings();
  }

  // --- GESTIONE LIMITE BUDGET ---
  Future<void> toggleLimitAlert(bool enabled) async {
    state = state.copyWith(limitAlertEnabled: enabled);
    await _saveSettings();
  }

  Future<void> setMonthlyLimit(double limit) async {
    state = state.copyWith(monthlyLimit: limit);
    await _saveSettings();
  }

  // --- VERIFICA BUDGET ---
  /// Confronta la spesa attuale con la soglia limite impostata ed emette una notifica se necessario.
  Future<void> checkBudgetLimit({
    required double currentMonthlySpent,
    required AppLocalizations l10n,
    required String currencySymbol,
  }) async {
    final title = l10n.notificationBudgetTitle;
    final spentString = "$currencySymbol${currentMonthlySpent.toStringAsFixed(2)}";
    final limitString = "$currencySymbol${state.monthlyLimit.toStringAsFixed(2)}";
    final body = l10n.notificationBudgetBody(spentString, limitString);

    final notificationService = await ref.read(notificationServiceProvider.future);
    await notificationService.checkAndNotifyBudgetLimit(
      currentMonthlySpent: currentMonthlySpent,
      monthlyLimit: state.monthlyLimit,
      alertEnabled: state.limitAlertEnabled,
      title: title,
      body: body,
    );
  }

  // --- RESET ---
  /// Ripristina lo stato predefinito cancellando ogni notifica schedulata dal sistema.
  Future<void> resetSettings() async {
    final notificationService = await ref.read(notificationServiceProvider.future);
    await notificationService.cancelAllNotifications();
    state = const NotificationState();
    await _saveSettings();
  }
}