import 'package:flutter/material.dart';

/// FILE: app_colors.dart
/// DESCRIZIONE: Classe statica che centralizza la palette colori dell'applicazione.
/// VERSIONE: Palette minimale grigio ardesia (blu-grigio neutro, molto sobria)
class AppColors {
  // --- PALETTE PRINCIPALE ---
  static Color primary = const Color(0xFF64748B); // Ardesia
  static Color secondaryLight = const Color(0xFFF1F5F9); // Grigio-blu quasi bianco
  static Color secondaryDark = const Color(0xFFB6C2D1); // Grigio-blu leggermente più scuro
  static Color tertiary = const Color(0xFF334155); // Ardesia scura

  // --- SFONDI ---
  static Color backgroundLight = const Color(0xFFFAFAFA);
  static Color backgroundDark = const Color(0xFF1A1A1A);

  // --- TIPOGRAFIA ---
  static Color textLight = const Color(0xFFFAFAFA);
  static Color textDark = const Color(0xFF212121);
  static Color textDark2 = const Color(0xFF424242);

  // --- TONI NEUTRI ---
  static Color greyLight = const Color(0xFF6B7280);
  static Color greyDark = const Color(0xFFB0B7C3);

  // --- FEEDBACK E AZIONI ---
  static Color snackBar = const Color(0xFF2A2A2A);
  static Color delete = const Color(0xFFE57373);

  // --- COMPONENTI UI ---
  static Color backgroundAvatar = const Color(0xFFE2E8F0);
  static Color avatar = const Color(0xFFFAFAFA);

  // --- PAGINA DI MODIFICA ---
  static Color snackBarEditPageLight = const Color(0xFFF1F5F9).withValues(alpha: 0.6);
  static Color snackBarEditPageDark = const Color(0xFF2A2A2A);
  static Color editPageBackgroundLight = const Color(0xFFF1F5F9);
  static Color editPageBackgroundDark = const Color(0xFF1A1A1A);
  static Color textEditPage = const Color(0xFF94A3B8);

  // --- INTERAZIONE E STRUTTURA ---
  static Color textTappedDown = const Color(0xFF64748B);
  static Color cardDark = const Color(0xFF252525);
  static Color cardLight = const Color(0xFFFFFFFF);
  static Color shadow = const Color(0xFF000000).withValues(alpha: 0.08);
  static Color dividerDark = const Color(0xFF3A3A3A);
  static Color dividerLight = const Color(0xFFE2E8F0);
  static Color borderLight = const Color(0xFFEDEFF2);
  static Color borderDark = const Color(0xFF2F2F2F);
}