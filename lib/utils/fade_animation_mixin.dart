import 'package:flutter/material.dart';

/// FILE: fade_animation_mixin.dart
/// DESCRIZIONE: Mixin riutilizzabile per aggiungere un'animazione di ingresso (Fade In)
/// a qualsiasi schermata o widget Stateful.
/// Richiede che la classe ospitante fornisca un `TickerProvider` (solitamente
/// tramite `SingleTickerProviderStateMixin`).

mixin FadeAnimationMixin {
  // --- REQUISITI ---
  // Il mixin richiede accesso al TickerProvider dello stato per sincronizzare l'animazione col frame rate.
  TickerProvider get vsync;

  late AnimationController fadeAnimationController;
  late Animation<double> fadeAnimation;

  // --- CONFIGURAZIONE ---
  // Getter sovrascrivibili per personalizzare durata e curva dell'animazione
  // senza dover modificare la logica interna.
  Duration get fadeAnimationDuration => const Duration(milliseconds: 800);

  Curve get fadeAnimationCurve => Curves.easeInOut;

  // --- LIFECYCLE (INIT) ---
  // Inizializza il controller e avvia l'animazione in avanti (0.0 -> 1.0).
  // Va chiamato nel metodo `initState` del widget ospitante.
  // 
  void initFadeAnimation() {
    fadeAnimationController = AnimationController(
      duration: fadeAnimationDuration,
      vsync: vsync,
    );

    fadeAnimation = CurvedAnimation(
      parent: fadeAnimationController,
      curve: fadeAnimationCurve,
    );

    fadeAnimationController.forward();
  }

  // --- LIFECYCLE (DISPOSE) ---
  // Pulisce le risorse del controller per evitare memory leak.
  // Va chiamato nel metodo `dispose` del widget ospitante.
  void disposeFadeAnimation() {
    fadeAnimationController.dispose();
  }

  // --- UI HELPER ---
  // Metodo wrapper che applica la FadeTransition al widget figlio.
  // Semplifica il metodo `build` del widget ospitante riducendo il boilerplate.
  // 
  Widget buildWithFadeAnimation(Widget child) {
    return FadeTransition(opacity: fadeAnimation, child: child);
  }
}