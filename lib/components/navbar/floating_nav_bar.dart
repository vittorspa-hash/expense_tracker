import 'dart:io';

import 'package:expense_tracker/config/app_colors.dart';
import 'package:expense_tracker/config/di/riverpod_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// FILE: floating_nav_bar.dart
/// DESCRIZIONE: Componente della floating bottom navigation bar e dei suoi
/// elementi ausiliari. Contiene il modello dati per una voce (`NavBarItem`),
/// il widget principale che disegna la barra "staccata" dal bordo inferiore
/// dello schermo, il singolo pulsante di navigazione con animazione icona/label,
/// e l'avatar profilo mostrato al posto dell'icona standard nella tab Profile.

// --- MODELLO VOCE NAVBAR ---
// Rappresenta una singola destinazione: icona inattiva, icona attiva e label.
class NavBarItem {
  const NavBarItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
  });

  final IconData icon;
  final IconData activeIcon;
  final String label;
}

// --- FLOATING NAV BAR ---
// Bottom navigation bar "floating": staccata dal bordo inferiore dello
// schermo, bordi leggermente arrotondati, con icona + label per ogni
// destinazione. Va posizionata in uno [Stack] sopra il contenuto della
// pagina (vedi [NavigationShell]), non come [Scaffold.bottomNavigationBar]
// classico, altrimenti Flutter ne forza i bordi inferiori a 0.
class FloatingNavBar extends ConsumerWidget {
  const FloatingNavBar({
    super.key,
    required this.items,
    required this.selectedIndex,
    required this.onTap,
  });

  final List<NavBarItem> items;
  final int selectedIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bottomInset = MediaQuery.of(context).padding.bottom;

    // Lettura dello stato profilo per l'avatar nella tab Profile.
    final profileState = ref.watch(profileNotifierProvider).value;
    final localAvatar = profileState?.localImage;
    final photoURL = profileState?.user?.photoURL;

    return Padding(
      padding: EdgeInsets.fromLTRB(16, 0, 16, bottomInset),
      child: Container(
        height: 64,
        decoration: BoxDecoration(
          color: isDark
              ? AppColors.cardDark.withValues(alpha: 0.8)
              : AppColors.cardLight.withValues(alpha: 0.8),
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: AppColors.shadow.withValues(alpha: 0.15),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: List.generate(items.length, (index) {
            final isSelected = index == selectedIndex;
            final activeColor = isDark ? AppColors.textDark : AppColors.primary;
            final inactiveColor = isDark ? AppColors.textLight : AppColors.textDark;

            // Solo per la tab Profile (indice 2) costruiamo l'avatar.
            Widget? avatarWidget;
            if (index == 2) {
              avatarWidget = _ProfileAvatar(
                localAvatar: localAvatar,
                photoURL: photoURL,
                isSelected: isSelected,
                activeColor: activeColor,
                inactiveColor: inactiveColor,
              );
            }

            return _NavBarButton(
              item: items[index],
              isSelected: isSelected,
              activeColor: activeColor,
              boxDecorationColor: isDark
                  ? AppColors.secondaryDark
                  : AppColors.secondaryLight,
              inactiveColor: isDark ? AppColors.textLight : AppColors.textDark,
              onTap: () => onTap(index),
              customIconWidget: avatarWidget,
            );
          }),
        ),
      ),
    );
  }
}

// --- PULSANTE SINGOLO ---
// Singolo pulsante della navbar: mostra icona (o avatar custom) + label,
// con sfondo evidenziato e animazione di transizione quando selezionato.
class _NavBarButton extends StatelessWidget {
  const _NavBarButton({
    required this.item,
    required this.isSelected,
    required this.activeColor,
    required this.inactiveColor,
    required this.onTap,
    required this.boxDecorationColor,
    this.customIconWidget, // Avatar per la tab Profile; null per le altre tab.
  });

  final NavBarItem item;
  final bool isSelected;
  final Color activeColor;
  final Color inactiveColor;
  final Color boxDecorationColor;
  final VoidCallback onTap;
  final Widget? customIconWidget; // Avatar per la tab Profile; null per le altre tab.

  @override
  Widget build(BuildContext context) {
    final color = isSelected ? activeColor : inactiveColor;

    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
            decoration: BoxDecoration(
              color: isSelected ? boxDecorationColor : Colors.transparent,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Se esiste un widget custom (avatar) lo mostra,
                // altrimenti cade sull'icona standard con AnimatedSwitcher.
                customIconWidget ??
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 150),
                      transitionBuilder: (child, animation) =>
                          FadeTransition(opacity: animation, child: child),
                      child: Icon(
                        isSelected ? item.activeIcon : item.icon,
                        key: ValueKey(isSelected),
                        color: color,
                        size: 24,
                      ),
                    ),
                const SizedBox(height: 2),
                Text(
                  item.label,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: color,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// --- AVATAR PROFILO ---
// Sostituisce l'icona standard nella tab Profile con la foto utente (locale
// o remota via `photoURL`); se non è presente alcuna immagine, ricade
// sull'icona persona di default (piena se selezionata, outline altrimenti).
class _ProfileAvatar extends StatelessWidget {
  const _ProfileAvatar({
    required this.localAvatar,
    required this.photoURL,
    required this.isSelected,
    required this.activeColor,
    required this.inactiveColor,
  });

  final File? localAvatar; 
  final String? photoURL;
  final bool isSelected;
  final Color activeColor;
  final Color inactiveColor;

  @override
  Widget build(BuildContext context) {
    final hasImage = localAvatar != null || photoURL != null;

    return Container(
      width: 26,
      height: 26,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: hasImage ? Border.all(color: activeColor, width: 2) : null,
      ),
      child: CircleAvatar(
        radius: 13,
        backgroundColor: Colors.transparent,
        backgroundImage: localAvatar != null
            ? FileImage(localAvatar!)
            : (photoURL != null ? NetworkImage(photoURL!) : null),
        child: !hasImage
            ? Icon(
                isSelected
                    ? Icons.person_rounded
                    : Icons.person_outline_rounded,
                size: 20,
                color: isSelected ? activeColor : inactiveColor,
              )
            : null,
      ),
    );
  }
}