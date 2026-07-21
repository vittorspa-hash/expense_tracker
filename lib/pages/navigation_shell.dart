import 'package:expense_tracker/components/navbar/floating_nav_bar.dart';
import 'package:expense_tracker/config/di/riverpod_providers.dart';
import 'package:expense_tracker/l10n/app_localizations.dart';
import 'package:expense_tracker/pages/home_page.dart';
import 'package:expense_tracker/pages/profile_page.dart';
import 'package:expense_tracker/pages/settings_page.dart';
import 'package:expense_tracker/pages/years_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// FILE: navigation_shell.dart
/// DESCRIZIONE: Shell principale dell'app post-autenticazione. Possiede la
/// `FloatingNavBar` e mantiene vive le 4 pagine principali tramite
/// `IndexedStack`, preservandone lo stato locale al cambio tab. La navbar è
/// posizionata in uno `Stack` sopra il contenuto per ottenere l'effetto
/// "floating" staccato dal bordo inferiore dello schermo, e viene nascosta
/// automaticamente quando la tastiera è aperta.

class NavigationShell extends ConsumerWidget {
  const NavigationShell({super.key});

  // --- PAGINE GESTITE ---
  // Le 4 pagine principali, tenute in vita simultaneamente dall'IndexedStack
  // così da preservarne stato e scroll al cambio tab.
  static const _pages = [
    HomePage(),
    YearsPage(),
    ProfilePage(),
    SettingsPage(),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedIndex = ref.watch(navigationNotifierProvider);
    final loc = AppLocalizations.of(context)!;
    final isKeyboardOpen = MediaQuery.of(context).viewInsets.bottom > 0;

    // --- COSTRUZIONE VOCI DELLA NAVBAR ---
    // Definisce icone (stato inattivo/attivo) e label localizzate per ciascuna
    // delle 4 tab, in ordine coerente con `_pages`.
    final navItems = [
      NavBarItem(
        icon: Icons.home_outlined,
        activeIcon: Icons.home_rounded,
        label: loc.navHome,
      ),
      NavBarItem(
        icon: Icons.bar_chart_outlined,
        activeIcon: Icons.bar_chart_rounded,
        label: loc.navReport,
      ),
      NavBarItem(
        icon: Icons.person_outline_rounded,
        activeIcon: Icons.person_rounded,
        label: loc.profileTitle,
      ),
      NavBarItem(
        icon: Icons.settings_outlined,
        activeIcon: Icons.settings_rounded,
        label: loc.settingsTitle,
      ),
    ];

    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          // Padding inferiore per evitare che il contenuto scrollabile
          // finisca nascosto dietro la navbar floating.
          IndexedStack(index: selectedIndex, children: _pages),

          // --- NAVBAR FLOATING ---
          // Nascosta quando la tastiera è aperta per non sovrapporsi ai campi
          // di input; altrimenti ancorata al bordo inferiore con effetto "floating".
          if (!isKeyboardOpen)
            Align(
              alignment: Alignment.bottomCenter,
              child: FloatingNavBar(
                items: navItems,
                selectedIndex: selectedIndex,
                onTap: (index) => ref
                    .read(navigationNotifierProvider.notifier)
                    .setIndex(index),
              ),
            ),
        ],
      ),
    );
  }
}
