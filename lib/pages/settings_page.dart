import 'package:expense_tracker/components/settings/account_section.dart';
import 'package:expense_tracker/components/settings/appearance_section.dart';
import 'package:expense_tracker/components/settings/currency_section.dart';
import 'package:expense_tracker/components/settings/language_section.dart';
import 'package:expense_tracker/components/settings/notifications_section.dart';
import 'package:expense_tracker/components/shared/custom_appbar.dart';
import 'package:expense_tracker/l10n/app_localizations.dart';
import 'package:expense_tracker/utils/fade_animation_mixin.dart';
import 'package:flutter/material.dart';
import 'package:expense_tracker/config/app_colors.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// FILE: settings_page.dart
/// DESCRIZIONE: Schermata principale delle impostazioni. Assembla le 5
/// sezioni (Aspetto, Notifiche, Valuta, Lingua, Account): ciascuna è
/// self-contained e legge da sola i propri provider Riverpod, quindi questo
/// file non contiene più stato o logica applicativa.

class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage>
    with SingleTickerProviderStateMixin, FadeAnimationMixin {
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

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final loc = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: CustomAppBar(
        title: loc.settingsTitle,
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
              const AppearanceSection(),
              SizedBox(height: 32.h),
              const NotificationsSection(),
              SizedBox(height: 32.h),
              const CurrencySection(),
              SizedBox(height: 32.h),
              const LanguageSection(),
              SizedBox(height: 32.h),
              const AccountSection(),
              SizedBox(height: 120.h),
            ],
          ),
        ),
      ),
    );
  }
}