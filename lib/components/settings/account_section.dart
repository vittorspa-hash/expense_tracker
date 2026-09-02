import 'package:expense_tracker/components/settings/settings_container.dart';
import 'package:expense_tracker/components/settings/settings_section_header.dart';
import 'package:expense_tracker/components/settings/settings_tile.dart';
import 'package:expense_tracker/config/di/riverpod_providers.dart';
import 'package:expense_tracker/l10n/app_localizations.dart';
import 'package:expense_tracker/utils/dialogs/dialog_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// FILE: account_section.dart
/// DESCRIZIONE: Sezione Impostazioni per le azioni sull'account — al
/// momento solo il logout, con dialog di conferma.

class AccountSection extends ConsumerWidget {
  const AccountSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loc = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SettingsSectionHeader(icon: Icons.manage_accounts_outlined, title: loc.profileTitle),
        SizedBox(height: 12.h),
        SettingsContainer(
          child: SettingsTile(
            icon: Icons.logout_rounded,
            title: loc.logout,
            logout: true,
            onPressed: () => _confirmLogout(context, ref),
          ),
        ),
      ],
    );
  }

  Future<void> _confirmLogout(BuildContext context, WidgetRef ref) async {
    final loc = AppLocalizations.of(context)!;
    final confirm = await DialogUtils.showConfirmDialog(
      context,
      title: loc.logoutConfirmTitle,
      content: loc.logoutConfirmMessage,
      confirmText: loc.logout,
      cancelText: loc.cancel,
    );

    if (confirm == true && context.mounted) {
      await ref.read(authNotifierProvider.notifier).signOut();
    }
  }
}