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
  static Color primary = Colors.deepPurple.shade400;         
  static Color secondaryLight = Colors.deepPurple.shade50;    
  static Color secondaryDark = Colors.deepPurple.shade200;  
  static Color tertiary = Colors.deepPurple.shade900;         

  // ---------------------------------------------------------------------------
  // 🖼️ BACKGROUND (tema chiaro/scuro)
  // ---------------------------------------------------------------------------
  static Color backgroundLight = Colors.white;                 
  static Color backgroundDark = Colors.grey.shade900;          

  // ---------------------------------------------------------------------------
  // ✍️ COLORI TESTO
  // ---------------------------------------------------------------------------
  static Color textLight = Colors.white;          
  static Color textDark = Colors.black;                 
  static Color textDark2 = Colors.grey.shade900;              

  // ---------------------------------------------------------------------------
  // ⚙️ TONALITÀ DI GRIGIO (Light/Dark modes)
  // ---------------------------------------------------------------------------
  static Color greyLight = Colors.grey[700]!;                 
  static Color greyDark = Colors.grey[400]!;             

  // ---------------------------------------------------------------------------
  // 🍫 SNACKBAR & ALERT
  // ---------------------------------------------------------------------------
  static Color snackBar = Colors.grey.shade800;           

  // ---------------------------------------------------------------------------
  // ❌ COLORI DI ERRORE / AZIONI DISTRUTTIVE
  // ---------------------------------------------------------------------------
  static Color delete = Colors.red;                       

  // ---------------------------------------------------------------------------
  // 🧩 AVATAR E CHIP
  // ---------------------------------------------------------------------------
  static Color backgroundAvatar = Colors.deepPurple.shade100; 
  static Color avatar = Colors.white;                        

  // ---------------------------------------------------------------------------
  // ✏️ COLORI PER EDIT PAGE (modalità personalizzata)
  // ---------------------------------------------------------------------------
  static Color snackBarEditPageLight = Colors.deepPurple.withValues(alpha: 0.15);
  static Color snackBarEditPageDark = Colors.grey.shade800;
  static Color editPageBackgroundLight = Colors.deepPurple.shade100;
  static Color editPageBackgroundDark = Colors.grey.shade900;
  static Color textEditPage = Colors.deepPurple.shade200;

  // ---------------------------------------------------------------------------
  // 🟣 FEEDBACK VISIVO TAP
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
  static Color shadow = Colors.black;                        

  static Color dividerDark = Colors.grey[700]!;              
  static Color dividerLight = Colors.grey[300]!;            

  // ---------------------------------------------------------------------------
  // ⬛ BORDER (borderInput, card, ecc…)
  // ---------------------------------------------------------------------------
  static Color borderLight = Colors.grey[200]!;          
  static Color borderDark = Colors.grey[800]!;                
}
