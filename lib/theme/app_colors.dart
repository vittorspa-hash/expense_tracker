// app_colors.dart
// -----------------------------------------------------------------------------
// 🎨 PALETTE COLORI DELL'APPLICAZIONE
//
// Classe centralizzata per la gestione dei colori principali dell'intera app.
// Tutti i colori (tema chiaro/scuro, testi, sfondi, card, pulsanti, stati)
// sono definiti qui per mantenere uno stile coerente e facilitare modifiche
// future.
// -----------------------------------------------------------------------------

import 'package:flutter/material.dart';

// -----------------------------------------------------------------------------
// 🎨 AppColors – Raccolta statica di colori utilizzata in tutta l’app
// -----------------------------------------------------------------------------
class AppColors {

  // ---------------------------------------------------------------------------
  // 🌈 COLORI PRINCIPALI (brand palette)
  // ---------------------------------------------------------------------------
  static Color primary = Colors.deepPurple.shade400;          // Colore principale
  static Color secondaryLight = Colors.deepPurple.shade50;     // Variante chiara
  static Color secondaryDark = Colors.deepPurple.shade200;     // Variante media-scura
  static Color tertiary = Colors.deepPurple.shade900;          // Tonalità molto scura

  // ---------------------------------------------------------------------------
  // 🖼️ BACKGROUND (tema chiaro/scuro)
  // ---------------------------------------------------------------------------
  static Color backgroundLight = Colors.white;                 // Sfondo light mode
  static Color backgroundDark = Colors.grey.shade900;          // Sfondo dark mode

  // ---------------------------------------------------------------------------
  // ✍️ COLORI TESTO
  // ---------------------------------------------------------------------------
  static Color textLight = Colors.white;                       // Testo su sfondo scuro
  static Color textDark = Colors.black;                        // Testo principale su sfondo chiaro
  static Color textDark2 = Colors.grey.shade900;               // Variante leggermente più scura

  // ---------------------------------------------------------------------------
  // ⚙️ TONALITÀ DI GRIGIO (Light/Dark modes)
  // ---------------------------------------------------------------------------
  static Color greyLight = Colors.grey[700]!;                  // Grigio scuro per testo/icone in light mode
  static Color greyDark = Colors.grey[400]!;                   // Grigio chiaro per testo/icone in dark mode

  // ---------------------------------------------------------------------------
  // 🍫 SNACKBAR & ALERT
  // ---------------------------------------------------------------------------
  static Color snackBar = Colors.grey.shade800;                // Sfondo snackbar scuro

  // ---------------------------------------------------------------------------
  // ❌ COLORI DI ERRORE / AZIONI DISTRUTTIVE
  // ---------------------------------------------------------------------------
  static Color delete = Colors.red;                            // Feedback di eliminazione

  // ---------------------------------------------------------------------------
  // 🧩 AVATAR E CHIP
  // ---------------------------------------------------------------------------
  static Color backgroundAvatar = Colors.deepPurple.shade100;  // Sfondo avatar
  static Color avatar = Colors.white;                          // Icona/avatar

  // ---------------------------------------------------------------------------
  // ✏️ COLORI PER EDIT PAGE (modalità personalizzata)
  // ---------------------------------------------------------------------------
  static Color snackBarEditPageLight = Colors.deepPurple.withValues(alpha: 0.15);
  static Color snackBarEditPageDark = Colors.grey.shade800;
  static Color editPageBackgroundLight = Colors.deepPurple.shade100;
  static Color editPageBackgroundDark = Colors.grey.shade900;
  static Color textEditPage = Colors.deepPurple.shade200;

  // ---------------------------------------------------------------------------
  // 🟣 FEEDBACK VISIVO TAPP (PRESSIONE BTN)
  // ---------------------------------------------------------------------------
  static Color textTappedDown = Colors.deepPurple.shade600;

  // ---------------------------------------------------------------------------
  // 🗂️ CARD (tema chiaro/scuro)
  // ---------------------------------------------------------------------------
  static Color cardDark = Colors.grey[850]!;
  static Color cardLight = Colors.white;

  // ---------------------------------------------------------------------------
  // 🖤 SHADOW & LINEE
  // ---------------------------------------------------------------------------
  static Color shadow = Colors.black;                          // Ombre

  static Color dividerDark = Colors.grey[700]!;                // Divider in dark mode
  static Color dividerLight = Colors.grey[300]!;               // Divider in light mode

  // ---------------------------------------------------------------------------
  // ⬛ BORDER (borderInput, card, ecc…)
  // ---------------------------------------------------------------------------
  static Color borderLight = Colors.grey[200]!;                // Bordo light mode
  static Color borderDark = Colors.grey[800]!;                 // Bordo dark mode
}
