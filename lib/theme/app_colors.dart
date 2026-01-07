import 'package:flutter/material.dart';

/// FILE: app_colors.dart
/// DESCRIZIONE: Classe statica che centralizza la palette colori dell'applicazione.
/// Definisce le costanti cromatiche per i temi chiaro/scuro, testi, componenti UI
/// e stati interattivi per garantire coerenza visiva in tutta l'app.
/// VERSIONE MIGLIORATA: Palette viola più tenue e armoniosa per ridurre l'affaticamento visivo
class AppColors {
  // --- PALETTE PRINCIPALE ---
  // Colori del brand con tonalità viola più morbide e moderne
  static Color primary = const Color(0xFF9575CD); // Viola medio-chiaro più delicato
  static Color secondaryLight = const Color(0xFFEDE7F6); // Lavanda chiaro 
  static Color secondaryDark = const Color(0xFFB39DDB); // Viola chiaro desaturato
  static Color tertiary = const Color(0xFF5E35B1); // Viola profondo ma non troppo scuro

  // --- SFONDI ---
  // Colori di base con maggiore morbidezza
  static Color backgroundLight = const Color(0xFFFAFAFA); // Bianco caldo invece di puro
  static Color backgroundDark = const Color(0xFF1A1A1A); // Nero più morbido

  // --- TIPOGRAFIA ---
  // Contrasti ottimizzati per minor affaticamento visivo
  static Color textLight = const Color(0xFFFAFAFA); // Bianco morbido
  static Color textDark = const Color(0xFF212121); // Nero più caldo
  static Color textDark2 = const Color(0xFF424242); // Grigio scuro per testo secondario

  // --- TONI NEUTRI ---
  // Grigi desaturati con leggera tendenza viola per coerenza cromatica
  static Color greyLight = const Color(0xFF6B6B7B); // Grigio con hint viola
  static Color greyDark = const Color(0xFFB8B8C8); // Grigio chiaro con hint viola

  // --- FEEDBACK E AZIONI ---
  // Colori più equilibrati per messaggi e azioni critiche
  static Color snackBar = const Color(0xFF2A2A2A); // Grigio scuro caldo
  static Color delete = const Color(0xFFE57373); // Rosso più morbido

  // --- COMPONENTI UI ---
  // Elementi con palette viola coerente e delicata
  static Color backgroundAvatar = const Color(0xFFD1C4E9); // Viola pastello 
  static Color avatar = const Color(0xFFFAFAFA); // Bianco caldo

  // --- PAGINA DI MODIFICA ---
  // Palette dedicata con tonalità viola ultra-leggere
  static Color snackBarEditPageLight = const Color(0xFFF3E5F5).withValues(alpha: 0.6);
  static Color snackBarEditPageDark = const Color(0xFF2A2A2A);
  static Color editPageBackgroundLight = const Color(0xFFF3E5F5); // Lavanda molto chiaro
  static Color editPageBackgroundDark = const Color(0xFF1A1A1A);
  static Color textEditPage = const Color(0xFFCE93D8); // Viola chiaro luminoso

  // --- INTERAZIONE E STRUTTURA ---
  // Superfici e divisori con contrasti ridotti per maggiore eleganza
  static Color textTappedDown = const Color(0xFF7E57C2); // Viola medio per feedback
  static Color cardDark = const Color(0xFF252525); // Card scura più morbida
  static Color cardLight = const Color(0xFFFFFFFF); // Card chiara bianco puro
  static Color shadow = const Color(0xFF000000).withValues(alpha: 0.08); // Ombra più leggera
  static Color dividerDark = const Color(0xFF3A3A3A); // Divisore scuro sottile
  static Color dividerLight = const Color(0xFFE8E8E8); // Divisore chiaro delicato
  static Color borderLight = const Color(0xFFF0F0F0); // Bordo quasi invisibile
  static Color borderDark = const Color(0xFF2F2F2F); // Bordo scuro sottile
}