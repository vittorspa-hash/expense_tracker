// lib/utils/fade_animation_mixin.dart
import 'package:flutter/material.dart';

/// Mixin che fornisce un'animazione di fade-in per le pagine.
/// Richiede che lo State usi SingleTickerProviderStateMixin.
mixin FadeAnimationMixin {
  // Questi getter devono essere implementati dalla classe che usa il mixin
  TickerProvider get vsync;

  late AnimationController fadeAnimationController;
  late Animation<double> fadeAnimation;

  /// Durata dell'animazione (può essere sovrascritta)
  Duration get fadeAnimationDuration => const Duration(milliseconds: 800);

  /// Curva dell'animazione (può essere sovrascritta)
  Curve get fadeAnimationCurve => Curves.easeInOut;

  /// Inizializza l'animazione di fade
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

  /// Rilascia le risorse dell'animazione
  void disposeFadeAnimation() {
    fadeAnimationController.dispose();
  }

  /// Widget helper per wrappare il contenuto con FadeTransition
  Widget buildWithFadeAnimation(Widget child) {
    return FadeTransition(opacity: fadeAnimation, child: child);
  }
}
