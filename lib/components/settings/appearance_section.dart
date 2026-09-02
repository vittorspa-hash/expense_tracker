import 'package:expense_tracker/components/settings/settings_container.dart';
import 'package:expense_tracker/components/settings/settings_section_header.dart';
import 'package:expense_tracker/components/settings/settings_tile.dart';
import 'package:expense_tracker/config/app_colors.dart';
import 'package:expense_tracker/config/di/riverpod_providers.dart';
import 'package:expense_tracker/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// FILE: appearance_section.dart
/// DESCRIZIONE: Sezione Impostazioni per il tema Chiaro/Scuro. Widget
/// self-contained: legge da solo themeNotifierProvider e gestisce il toggle.

class AppearanceSection extends ConsumerWidget {
  const AppearanceSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final loc = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SettingsSectionHeader(icon: Icons.palette_outlined, title: loc.appearance),
        SizedBox(height: 12.h),
        SettingsContainer(
          child: SettingsTile(
            icon: isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
            title: loc.darkMode,
            subtitle: isDark ? loc.activated : loc.deactivated,
            trailingWidget: Transform.scale(
              scale: 0.9,
              child: Switch(
                value: isDark,
                onChanged: (value) =>
                    ref.read(themeNotifierProvider.notifier).toggleTheme(value),
                activeThumbColor: AppColors.primary,
              ),
            ),
            logout: false,
          ),
        ),
      ],
    );
  }
}