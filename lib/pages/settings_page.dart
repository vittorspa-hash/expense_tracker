// settings_page.dart
// -----------------------------------------------------------------------------
// ⚙️ PAGINA IMPOSTAZIONI
// -----------------------------------------------------------------------------
// Gestisce:
// - Tema scuro ON/OFF
// - Notifiche giornaliere (promemoria spese)
// - Notifiche limite spesa mensile
// - Animazione fade-in iniziale
// -----------------------------------------------------------------------------

import 'package:expense_tracker/components/shared/custom_appbar.dart';
import 'package:expense_tracker/utils/dialog_utils.dart';
import 'package:expense_tracker/utils/fade_animation_mixin.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:expense_tracker/providers/theme_provider.dart';
import 'package:expense_tracker/providers/settings_provider.dart';
import 'package:expense_tracker/theme/app_colors.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:expense_tracker/components/settings/settings_tile.dart';
import 'package:expense_tracker/components/settings/settings_section_header.dart';

class SettingsPage extends StatefulWidget {
  static const route = "/settings/page";
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage>
    with SingleTickerProviderStateMixin, FadeAnimationMixin {
  // 🔧 Getter per il vsync richiesto dal mixin
  @override
  TickerProvider get vsync => this;

  @override
  void initState() {
    super.initState();
    // 🎞️ Animazione fade-in iniziale
    initFadeAnimation();
  }

  @override
  void dispose() {
    disposeFadeAnimation();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final settingsProvider = Provider.of<SettingsProvider>(context);

    return Scaffold(
      // -------------------------------------------------------------------------
      // 🔝 APPBAR IMPOSTAZIONI
      // -------------------------------------------------------------------------
      appBar: CustomAppBar(
        title: "Impostazioni",
        icon: Icons.settings_rounded,
        isDark: isDark,
      ),

      // -------------------------------------------------------------------------
      // 🎨 BODY CON ANIMAZIONE
      // -------------------------------------------------------------------------
      body: Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
        ),
        child: buildWithFadeAnimation(
          ListView(
            padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 20.h),
            children: [
              // -----------------------------------------------------------------
              // 🎨 SEZIONE ASPETTO
              // -----------------------------------------------------------------
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

              // -----------------------------------------------------------------
              // 🔔 SEZIONE NOTIFICHE
              // -----------------------------------------------------------------
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
                    // 📅 Promemoria giornaliero
                    SettingsTile(
                      icon: Icons.alarm_rounded,
                      title: "Promemoria giornaliero",
                      subtitle: settingsProvider.dailyReminderEnabled
                          ? "Attivo alle ${settingsProvider.reminderTime.format(context)}"
                          : "Disattivato",
                      trailingWidget: Transform.scale(
                        scale: 0.9,
                        child: Switch(
                          value: settingsProvider.dailyReminderEnabled,
                          onChanged: (value) {
                            settingsProvider.toggleDailyReminder(value);
                          },
                          activeThumbColor: AppColors.primary,
                        ),
                      ),
                    ),

                    // Mostra selettore orario solo se attivo
                    if (settingsProvider.dailyReminderEnabled) ...[
                      _buildDivider(isDark),
                      SettingsTile(
                        icon: Icons.schedule_rounded,
                        title: "Orario promemoria",
                        subtitle: settingsProvider.reminderTime.format(context),
                        trailingIcon: Icons.chevron_right_rounded,
                        onPressed: () => _selectTime(context, settingsProvider),
                      ),
                    ],

                    _buildDivider(isDark),

                    // 💰 Avviso limite spesa
                    SettingsTile(
                      icon: Icons.warning_amber_rounded,
                      title: "Avviso limite spesa",
                      subtitle: settingsProvider.limitAlertEnabled
                          ? "Attivo (€${settingsProvider.monthlyLimit.toStringAsFixed(0)}/mese)"
                          : "Disattivato",
                      trailingWidget: Transform.scale(
                        scale: 0.9,
                        child: Switch(
                          value: settingsProvider.limitAlertEnabled,
                          onChanged: (value) {
                            settingsProvider.toggleLimitAlert(value);
                          },
                          activeThumbColor: AppColors.primary,
                        ),
                      ),
                    ),

                    // Mostra selettore limite solo se attivo
                    if (settingsProvider.limitAlertEnabled) ...[
                      _buildDivider(isDark),
                      SettingsTile(
                        icon: Icons.euro_rounded,
                        title: "Limite mensile",
                        subtitle:
                            "€${settingsProvider.monthlyLimit.toStringAsFixed(0)}",
                        trailingIcon: Icons.chevron_right_rounded,
                        onPressed: () =>
                            _selectLimit(context, settingsProvider),
                      ),
                    ],
                  ],
                ),
              ),

              SizedBox(height: 24.h),

              // -----------------------------------------------------------------
              // ℹ️ INFO NOTIFICHE
              // -----------------------------------------------------------------
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

  // -----------------------------------------------------------------------------
  // 🕐 SELETTORE ORARIO PROMEMORIA
  // -----------------------------------------------------------------------------
  Future<void> _selectTime(
    BuildContext context,
    SettingsProvider provider,
  ) async {
    final picked = await DialogUtils.showTimePickerAdaptive(
      context,
      initialTime: provider.reminderTime,
    );

    if (picked != null && picked != provider.reminderTime) {
      await provider.setReminderTime(picked);
    }
  }

  // -----------------------------------------------------------------------------
  // 💶 SELETTORE LIMITE SPESA (dialog adattivo)
  // -----------------------------------------------------------------------------
  Future<void> _selectLimit(
    BuildContext context,
    SettingsProvider provider,
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

  // -----------------------------------------------------------------------------
  // ➖ DIVIDER SEZIONI
  // -----------------------------------------------------------------------------
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
