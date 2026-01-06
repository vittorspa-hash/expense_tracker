import 'package:flutter/material.dart';
/// FILE: app_colors.dart
/// DESCRIZIONE: Classe statica che centralizza la palette colori dell'applicazione.
/// Definisce le costanti cromatiche per i temi chiaro/scuro, testi, componenti UI
/// e stati interattivi per garantire coerenza visiva in tutta l'app.
class AppColors {
// --- PALETTE PRINCIPALE ---
// Colori del brand utilizzati per elementi primari, sfumature e accenti.
static Color primary = Colors.deepPurple.shade400;
static Color secondaryLight = Colors.deepPurple.shade50;
static Color secondaryDark = Colors.deepPurple.shade200;
static Color tertiary = Colors.deepPurple.shade900;
// --- SFONDI ---
// Colori di base per lo scaffold e le schermate in modalità Light e Dark.
static Color backgroundLight = Colors.white;
static Color backgroundDark = Colors.grey.shade900;
// --- TIPOGRAFIA ---
// Colori del testo ottimizzati per garantire leggibilità su diversi sfondi.
static Color textLight = Colors.white;
static Color textDark = Colors.black;
static Color textDark2 = Colors.grey.shade900;
// --- TONI NEUTRI ---
// Sfumature di grigio utilizzate per sottotitoli, hint o elementi disabilitati.
static Color greyLight = Colors.grey[700]!;
static Color greyDark = Colors.grey[400]!;
// --- FEEDBACK E AZIONI ---
// Colori per messaggi di sistema (Snackbar) e azioni distruttive (Errori/Eliminazione).
static Color snackBar = Colors.grey.shade800;
static Color delete = Colors.red;
// --- COMPONENTI UI ---
// Colori specifici per elementi grafici come Avatar e Chips.
static Color backgroundAvatar = Colors.deepPurple.shade100;
static Color avatar = Colors.white;
// --- PAGINA DI MODIFICA ---
// Palette colori dedicata specificamente alle schermate di creazione/modifica spesa.
static Color snackBarEditPageLight = Colors.deepPurple.withValues(alpha: 0.15);
static Color snackBarEditPageDark = Colors.grey.shade800;
static Color editPageBackgroundLight = Colors.deepPurple.shade100;
static Color editPageBackgroundDark = Colors.grey.shade900;
static Color textEditPage = Colors.deepPurple.shade200;
// --- INTERAZIONE E STRUTTURA ---
// Colori per feedback tattile, superfici delle card, ombreggiature, divisori e bordi.
static Color textTappedDown = Colors.deepPurple.shade600;
static Color cardDark = Colors.grey[850]!;
static Color cardLight = Colors.white;
static Color shadow = Colors.black;
static Color dividerDark = Colors.grey[700]!;
static Color dividerLight = Colors.grey[300]!;
static Color borderLight = Colors.grey[200]!;
static Color borderDark = Colors.grey[800]!;
} 