import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:expense_tracker/theme/app_colors.dart';

/// FILE: components/settings/settings_container.dart
/// DESCRIZIONE: Wrapper riutilizzabile per le sezioni delle impostazioni.
/// Gestisce l'aspetto grafico (sfondo, bordi, ombre) in base al tema.

class SettingsContainer extends StatelessWidget {
  final Widget child;

  const SettingsContainer({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
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
      // Il clip behavior assicura che il child (es. l'effetto splash dei bottoni)
      // rispetti i bordi arrotondati del container.
      clipBehavior: Clip.hardEdge, 
      child: child,
    );
  }
}