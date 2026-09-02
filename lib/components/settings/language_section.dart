import 'package:expense_tracker/components/settings/settings_container.dart';
import 'package:expense_tracker/components/settings/settings_section_header.dart';
import 'package:expense_tracker/components/settings/settings_tile.dart';
import 'package:expense_tracker/config/di/riverpod_providers.dart';
import 'package:expense_tracker/l10n/app_localizations.dart';
import 'package:expense_tracker/utils/dialogs/dialog_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// FILE: language_section.dart
/// DESCRIZIONE: Sezione Impostazioni per la lingua globale dell'app. Al
/// cambio lingua, ricarica le traduzioni e rischedula le notifiche con i
/// testi aggiornati.

class LanguageSection extends ConsumerWidget {
  const LanguageSection({super.key});

  String _getLanguageName(BuildContext context, String code) {
    switch (code) {
      case 'it':
        return AppLocalizations.of(context)!.languageNameIt;
      case 'en':
        return AppLocalizations.of(context)!.languageNameEn;
      case 'fr':
        return AppLocalizations.of(context)!.languageNameFr;
      case 'es':
        return AppLocalizations.of(context)!.languageNameEs;
      case 'de':
        return AppLocalizations.of(context)!.languageNameDe;
      case 'pt':
        return AppLocalizations.of(context)!.languageNamePt;
      default:
        return AppLocalizations.of(context)!.languageNameIt;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final languageState = ref.watch(languageNotifierProvider);
    final loc = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SettingsSectionHeader(icon: Icons.language_rounded, title: loc.language),
        SizedBox(height: 12.h),
        SettingsContainer(
          child: SettingsTile(
            icon: Icons.translate_rounded,
            title: loc.defaultLanguage,
            subtitle: _getLanguageName(context, languageState.currentLocale.languageCode),
            trailingIcon: Icons.chevron_right_rounded,
            logout: false,
            onPressed: () => _selectLanguage(context, ref, isDark),
          ),
        ),
      ],
    );
  }

  Future<void> _selectLanguage(BuildContext context, WidgetRef ref, bool isDark) async {
    final loc = AppLocalizations.of(context)!;
    final result = await DialogUtils.showSortSheet(
      context,
      isDark: isDark,
      title: loc.selectLanguageTitle,
      options: [
        {"title": loc.languageNameIt, "criteria": "it"},
        {"title": loc.languageNameEn, "criteria": "en"},
        {"title": loc.languageNameFr, "criteria": "fr"},
        {"title": loc.languageNameEs, "criteria": "es"},
        {"title": loc.languageNameDe, "criteria": "de"},
        {"title": loc.languageNamePt, "criteria": "pt"},
      ],
    );

    if (result != null) {
      // 1. Creiamo il Locale per la nuova lingua scelta
      final newLocale = Locale(result);

      // 2. Aggiorniamo la lingua nell'app (questo aggiorna la UI)
      await ref.read(languageNotifierProvider.notifier).changeLanguage(newLocale);

      // 3. AGGIORNAMENTO NOTIFICHE:
      // Carichiamo manualmente le traduzioni per la NUOVA lingua, invece di
      // affidarci a '.of(context)', per avere le stringhe nuove al 100%
      // immediatamente.
      final newL10n = await AppLocalizations.delegate.load(newLocale);

      // 4. Se il widget è ancora montato, rischeduliamo le notifiche
      if (context.mounted) {
        ref.read(notificationNotifierProvider.notifier).rescheduleNotifications(newL10n);
        debugPrint("🌍 Notifiche aggiornate alla lingua: $result");
      }
    }
  }
}