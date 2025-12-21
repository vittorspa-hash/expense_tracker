import 'package:expense_tracker/components/shared/custom_appbar.dart';
import 'package:expense_tracker/utils/dialogs/dialog_utils.dart';
import 'package:expense_tracker/utils/fade_animation_mixin.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:expense_tracker/providers/theme_provider.dart';
import 'package:expense_tracker/providers/notification_provider.dart';
import 'package:expense_tracker/theme/app_colors.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:expense_tracker/components/settings/settings_tile.dart';
import 'package:expense_tracker/components/settings/settings_section_header.dart';

/// FILE: settings_page.dart
/// DESCRIZIONE: Schermata principale delle impostazioni.
/// Permette all'utente di configurare:
/// 1. L'aspetto dell'app (Tema Chiaro/Scuro).
/// 2. Le notifiche locali (Promemoria giornaliero e Avviso limite budget).
/// Utilizza Switch e Dialoghi adattivi per modificare lo stato dei Provider.

class SettingsPage extends StatefulWidget {
  static const route = "/settings/page";
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage>
    with SingleTickerProviderStateMixin, FadeAnimationMixin {
  
  // --- INIZIALIZZAZIONE ---
  // Setup delle animazioni di ingresso (Fade-in).
  @override
  TickerProvider get vsync => this;

  @override
  void initState() {
    super.initState();
    initFadeAnimation();
  }

  @override
  void dispose() {
    disposeFadeAnimation();
    super.dispose();
  }

  // --- BUILD UI ---
  // Costruzione della lista di opzioni divisa per sezioni (Aspetto, Notifiche).
  // 
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final notificationProvider = Provider.of<NotificationProvider>(context);

    return Scaffold(
      appBar: CustomAppBar(
        title: "Impostazioni",
        icon: Icons.settings_rounded,
        isDark: isDark,
      ),

      body: Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
        ),
        child: buildWithFadeAnimation(
          ListView(
            padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 20.h),
            children: [
              // --- SEZIONE ASPETTO ---
              // Gestione del cambio tema tramite ThemeProvider.
              const SettingsSectionHeader(
                icon: Icons.palette_outlined,
                title: "Aspetto",
              ),

              SizedBox(height: 12.h),

              Container(
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.cardDark.withValues(alpha: 0.5)
                      : AppColors.cardLight.withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(20.r),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.shadow.withValues(
                        alpha: isDark ? 0.3 : 0.08,
                      ),
                      blurRadius: 15,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: SettingsTile(
                  icon: isDark
                      ? Icons.dark_mode_rounded
                      : Icons.light_mode_rounded,
                  title: "Tema scuro",
                  subtitle: isDark
                      ? "Attivato"
                      : "Disattivato",
                  trailingWidget: Consumer<ThemeProvider>(
                    builder: (context, themeProvider, _) {
                      return Transform.scale(
                        scale: 0.9,
                        child: Switch(
                          value: themeProvider.isDarkMode,
                          onChanged: (value) =>
                              themeProvider.toggleTheme(value),
                          activeThumbColor: AppColors.primary,
                        ),
                      );
                    },
                  ),
                ),
              ),

              SizedBox(height: 32.h),

              // --- SEZIONE NOTIFICHE ---
              // Configurazione dei promemoria locali.
              // Include logica condizionale per mostrare/nascondere le opzioni secondarie
              // (es. orario o importo limite) solo se il toggle principale è attivo.
              // 
              const SettingsSectionHeader(
                icon: Icons.notifications_outlined,
                title: "Notifiche",
              ),

              SizedBox(height: 12.h),

              Container(
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.cardDark.withValues(alpha: 0.5)
                      : AppColors.cardLight.withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(20.r),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.shadow.withValues(
                        alpha: isDark ? 0.3 : 0.08,
                      ),
                      blurRadius: 15,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Promemoria Giornaliero (Toggle)
                    SettingsTile(
                      icon: Icons.alarm_rounded,
                      title: "Promemoria giornaliero",
                      subtitle: notificationProvider.dailyReminderEnabled
                          ? "Attivo alle ${notificationProvider.reminderTime.format(context)}"
                          : "Disattivato",
                      trailingWidget: Transform.scale(
                        scale: 0.9,
                        child: Switch(
                          value: notificationProvider.dailyReminderEnabled,
                          onChanged: (value) {
                            notificationProvider.toggleDailyReminder(value);
                          },
                          activeThumbColor: AppColors.primary,
                        ),
                      ),
                    ),

                    // Selettore Orario (Visibile solo se attivo)
                    if (notificationProvider.dailyReminderEnabled) ...[
                      _buildDivider(isDark),
                      SettingsTile(
                        icon: Icons.schedule_rounded,
                        title: "Orario promemoria",
                        subtitle: notificationProvider.reminderTime.format(context),
                        trailingIcon: Icons.chevron_right_rounded,
                        onPressed: () => _selectTime(context, notificationProvider),
                      ),
                    ],

                    _buildDivider(isDark),

                    // Avviso Limite Spesa (Toggle)
                    SettingsTile(
                      icon: Icons.warning_amber_rounded,
                      title: "Avviso limite spesa",
                      subtitle: notificationProvider.limitAlertEnabled
                          ? "Attivo (€${notificationProvider.monthlyLimit.toStringAsFixed(0)}/mese)"
                          : "Disattivato",
                      trailingWidget: Transform.scale(
                        scale: 0.9,
                        child: Switch(
                          value: notificationProvider.limitAlertEnabled,
                          onChanged: (value) {
                            notificationProvider.toggleLimitAlert(value);
                          },
                          activeThumbColor: AppColors.primary,
                        ),
                      ),
                    ),

                    // Selettore Importo Limite (Visibile solo se attivo)
                    if (notificationProvider.limitAlertEnabled) ...[
                      _buildDivider(isDark),
                      SettingsTile(
                        icon: Icons.euro_rounded,
                        title: "Limite mensile",
                        subtitle:
                            "€${notificationProvider.monthlyLimit.toStringAsFixed(0)}",
                        trailingIcon: Icons.chevron_right_rounded,
                        onPressed: () =>
                            _selectLimit(context, notificationProvider),
                      ),
                    ],
                  ],
                ),
              ),

              SizedBox(height: 24.h),

              // Box Informativo
              Container(
                padding: EdgeInsets.all(16.w),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16.r),
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.2),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline_rounded,
                      color: AppColors.primary,
                      size: 24.r,
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: Text(
                        "Le notifiche ti aiuteranno a tenere traccia delle tue spese quotidiane e a rispettare il budget mensile",
                        style: TextStyle(
                          fontSize: 13.sp,
                          color: isDark
                              ? AppColors.textLight
                              : AppColors.textDark,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- HELPER SELETTORI ---
  // Funzioni per aprire i dialoghi di scelta orario (TimePicker) e importo (InputDialog).
  Future<void> _selectTime(
    BuildContext context,
    NotificationProvider provider,
  ) async {
    final picked = await DialogUtils.showTimePickerAdaptive(
      context,
      initialTime: provider.reminderTime,
    );

    if (picked != null && picked != provider.reminderTime) {
      await provider.setReminderTime(picked);
    }
  }

  Future<void> _selectLimit(
    BuildContext context,
    NotificationProvider provider,
  ) async {
    final result = await DialogUtils.showInputDialogAdaptive(
      context,
      title: "Imposta limite mensile",
      fields: [
        {
          "label": "Limite mensile",
          "hintText": "Inserisci importo",
          "prefixIcon": Icons.euro_rounded,
          "keyboardType": TextInputType.number,
          "initialValue": provider.monthlyLimit.toStringAsFixed(0),
          "obscureText": false,
        },
      ],
    );

    if (result != null && result.isNotEmpty) {
      final value = double.tryParse(result.first);
      if (value != null && value > 0) {
        provider.setMonthlyLimit(value);
      }
    }
  }

  // --- UTILS UI ---
  Widget _buildDivider(bool isDark) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      child: Divider(
        height: 1,
        thickness: 1,
        color: isDark
            ? AppColors.dividerDark.withValues(alpha: 0.3)
            : AppColors.dividerLight.withValues(alpha: 0.5),
      ),
    );
  }
}