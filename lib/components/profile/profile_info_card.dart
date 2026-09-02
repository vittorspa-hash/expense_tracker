import 'package:expense_tracker/components/profile/profile_tile.dart';
import 'package:expense_tracker/config/app_colors.dart';
import 'package:expense_tracker/l10n/app_localizations.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// FILE: profile_info_card.dart
/// DESCRIZIONE: Card con i dati personali dell'utente (Nome, Email, Password,
/// ID). Estratta da ProfilePage per isolare la sezione "dati personali" come
/// unità autonoma, riceve tutto dall'esterno (nessuna dipendenza diretta da
/// Riverpod) per restare un componente puramente presentazionale.

class ProfileInfoCard extends StatelessWidget {
  final User? user;
  final bool isLoading;
  final VoidCallback onEditName;
  final VoidCallback onEditEmail;
  final VoidCallback onEditPassword;
  final VoidCallback onCopyId;

  const ProfileInfoCard({
    super.key,
    required this.user,
    required this.isLoading,
    required this.onEditName,
    required this.onEditEmail,
    required this.onEditPassword,
    required this.onCopyId,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final loc = AppLocalizations.of(context)!;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.cardLight,
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow.withValues(alpha: isDark ? 0.3 : 0.08),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          // Nome
          ProfileTile(
            icon: Icons.person_outline_rounded,
            title: loc.nameLabel,
            value: user?.displayName,
            tooltip: loc.editNameTooltip,
            onPressed: onEditName,
            isLoading: isLoading,
          ),

          _buildDivider(isDark),

          // Email
          ProfileTile(
            icon: Icons.email_outlined,
            title: loc.emailLabel,
            value: user?.email,
            tooltip: loc.editEmailTooltip,
            onPressed: onEditEmail,
            isLoading: isLoading,
          ),

          _buildDivider(isDark),

          // Password
          ProfileTile(
            icon: Icons.lock_outline_rounded,
            title: loc.passwordLabel,
            value: "••••••••••",
            tooltip: loc.editPasswordTooltip,
            onPressed: onEditPassword,
            isLoading: isLoading,
          ),

          _buildDivider(isDark),

          // ID Utente (Copiabile)
          ProfileTile(
            icon: Icons.badge_outlined,
            title: loc.userIdLabel,
            value: user?.uid,
            trailingIcon: Icons.content_copy_rounded,
            tooltip: loc.copyIdTooltip,
            onPressed: onCopyId,
            isLoading: isLoading,
          ),
        ],
      ),
    );
  }

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
