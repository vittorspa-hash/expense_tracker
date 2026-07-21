import 'package:flutter_riverpod/flutter_riverpod.dart';

/// FILE: navigation_notifier.dart
/// DESCRIZIONE: Notifier che gestisce l'indice della tab attualmente
/// selezionata nella `FloatingNavBar`. Stato sincrono, nessuna dipendenza
/// esterna richiesta in fase di build: rispetta la regola del `Notifier` puro.

class NavigationNotifier extends Notifier<int> {
  @override
  int build() => 0; // Home come tab di default

  void setIndex(int index) => state = index;
}