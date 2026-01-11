import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// FILE: report_date_utils.dart
/// DESCRIZIONE: Classe di utilità statica per la gestione delle date nei report.
/// Contiene metodi centralizzati per la formattazione locale
/// e generatori dinamici (es. nomi dei mesi) per evitare duplicazioni
/// nelle pagine Years, Months e Days.

class ReportDateUtils {
  
  // --- COSTANTI ---
  // Genera la lista dei nomi dei mesi localizzata in base al contesto.
  // Utilizzata per popolare i grafici e le intestazioni delle liste.
  static List<String> getMonthNames(BuildContext context) {
    final locale = Localizations.localeOf(context).toString();
    return List.generate(12, (index) {
      // Crea una data fittizia per ogni mese (es. 1 Gennaio, 1 Febbraio...)
      final date = DateTime(2024, index + 1, 1);
      final formatter = DateFormat("MMMM", locale);
      final name = formatter.format(date);
      
      // Capitalizza la prima lettera (necessario per IT, innocuo per EN)
      return name[0].toUpperCase() + name.substring(1);
    });
  }

  // --- METODI DI FORMATTAZIONE ---

  /// Converte un oggetto DateTime in una stringa formattata completa localizzata.
  /// Esempio output IT: "12 Ottobre 2023"
  /// Esempio output EN: "October 12, 2023" (o simile in base al locale)
  static String formatDate(BuildContext context, DateTime date) {
    final locale = Localizations.localeOf(context).toString();
    
    // Pattern adattivo o specifico: qui usiamo un formato lungo standard
    // Puoi usare "d MMMM y" per forzare l'ordine Giorno Mese Anno se preferisci,
    // oppure DateFormat.yMMMMd(locale) per il formato standard locale.
    final giorno = DateFormat("d", locale).format(date);
    final mese = DateFormat("MMMM", locale).format(date);
    final anno = DateFormat("y", locale).format(date);
    
    // Capitalizza la prima lettera del mese (DateFormat restituisce minuscolo in IT)
    final meseCapitalizzato = mese.isNotEmpty 
        ? mese[0].toUpperCase() + mese.substring(1) 
        : mese;
    
    // Manteniamo la struttura visiva richiesta: Giorno Mese Anno
    return "$giorno $meseCapitalizzato $anno";
  }

  /// Restituisce il nome del giorno della settimana localizzato.
  /// Esempio output IT: "Lunedì"
  /// Esempio output EN: "Monday"
  static String getDayOfWeek(BuildContext context, DateTime date) {
    final locale = Localizations.localeOf(context).toString();
    final giornoSettimana = DateFormat("EEEE", locale).format(date);
    
    // Assicura che la prima lettera sia maiuscola
    return giornoSettimana.isNotEmpty
        ? giornoSettimana[0].toUpperCase() + giornoSettimana.substring(1)
        : giornoSettimana;
  }
}