import 'package:expense_tracker/config/di/riverpod_providers.dart';
import 'package:expense_tracker/l10n/app_localizations.dart';
import 'package:expense_tracker/services/notification_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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

  NotificationService get _notificationService =>
      ref.read(notificationServiceProvider).requireValue;

  // --- INIZIALIZZAZIONE ---
  Future<void> initialize() async {
    try {
      await _notificationService.initialize();
      await _loadSettings();
    } catch (e) {
      debugPrint('❌ Errore inizializzazione notifiche: $e');
      state = const NotificationState(
        dailyReminderEnabled: false,
        limitAlertEnabled: false,
      );
    }
  }

  Future<void> rescheduleNotifications(AppLocalizations l10n) async {
    if (state.dailyReminderEnabled) {
      await _notificationService.scheduleDailyReminder(
        time: state.reminderTime,
        title: l10n.notificationDailyTitle,
        body: l10n.notificationDailyBody,
      );
      debugPrint('🔄 Notifiche rischedulate con lingua: ${l10n.localeName}');
    }
  }

  // --- PERSISTENZA ---
  Future<void> _loadSettings() async {
    final hour = _notificationService.getReminderHour();
    final minute = _notificationService.getReminderMinute();

    state = state.copyWith(
      dailyReminderEnabled: _notificationService.getDailyReminderEnabled(),
      reminderTime: TimeOfDay(hour: hour, minute: minute),
      limitAlertEnabled: _notificationService.getLimitAlertEnabled(),
      monthlyLimit: _notificationService.getMonthlyLimit(),
    );
  }

  Future<void> _saveSettings() async {
    try {
      await _notificationService.saveDailyReminderEnabled(state.dailyReminderEnabled);
      await _notificationService.saveReminderTime(
        state.reminderTime.hour,
        state.reminderTime.minute,
      );
      await _notificationService.saveLimitAlertEnabled(state.limitAlertEnabled);
      await _notificationService.saveMonthlyLimit(state.monthlyLimit);
    } catch (e) {
      debugPrint('❌ Errore salvataggio impostazioni notifiche: $e');
      rethrow;
    }
  }

  // --- GESTIONE PROMEMORIA GIORNALIERO ---
  Future<void> toggleDailyReminder(bool enabled, AppLocalizations l10n) async {
    state = state.copyWith(dailyReminderEnabled: enabled);

    if (enabled) {
      final hasPermission = await _notificationService.requestPermissions();
      if (hasPermission) {
        await _notificationService.scheduleDailyReminder(
          time: state.reminderTime,
          title: l10n.notificationDailyTitle,
          body: l10n.notificationDailyBody,
        );
        debugPrint('✅ Promemoria giornaliero attivato');
      } else {
        state = state.copyWith(dailyReminderEnabled: false);
        debugPrint('❌ Permessi notifiche negati');
      }
    } else {
      await _notificationService.cancelDailyReminder();
      debugPrint('🗑️ Promemoria giornaliero disattivato');
    }

    await _saveSettings();
  }

  Future<void> setReminderTime(TimeOfDay time, AppLocalizations l10n) async {
    state = state.copyWith(reminderTime: time);

    if (state.dailyReminderEnabled) {
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
  }

  // --- GESTIONE LIMITE BUDGET ---
  Future<void> toggleLimitAlert(bool enabled) async {
    state = state.copyWith(limitAlertEnabled: enabled);
    await _saveSettings();
    debugPrint(enabled
        ? '✅ Avviso limite spesa attivato (€${state.monthlyLimit})'
        : '🗑️ Avviso limite spesa disattivato');
  }

  Future<void> setMonthlyLimit(double limit) async {
    state = state.copyWith(monthlyLimit: limit);
    await _saveSettings();
    debugPrint('💰 Limite mensile impostato: €${limit.toStringAsFixed(2)}');
  }

  // --- ORCHESTRAZIONE: VERIFICA BUDGET ---
  Future<void> checkBudgetLimit(
    double currentMonthlySpent,
    AppLocalizations l10n,
    String currencySymbol,
  ) async {
    final title = l10n.notificationBudgetTitle;
    final spentString = "$currencySymbol${currentMonthlySpent.toStringAsFixed(2)}";
    final limitString = "$currencySymbol${state.monthlyLimit.toStringAsFixed(2)}";
    final body = l10n.notificationBudgetBody(spentString, limitString);

    await _notificationService.checkAndNotifyBudgetLimit(
      currentMonthlySpent: currentMonthlySpent,
      monthlyLimit: state.monthlyLimit,
      alertEnabled: state.limitAlertEnabled,
      title: title,
      body: body,
    );
  }

  // --- RESET ---
  Future<void> resetSettings() async {
    await _notificationService.cancelAllNotifications();
    state = const NotificationState();
    await _saveSettings();
    debugPrint('🔄 Impostazioni resettate ai valori predefiniti');
  }
}