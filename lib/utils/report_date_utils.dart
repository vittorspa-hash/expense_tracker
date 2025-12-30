import 'package:intl/intl.dart';

/// FILE: report_date_utils.dart
/// DESCRIZIONE: Classe di utilità statica per la gestione delle date nei report.
/// Contiene metodi centralizzati per la formattazione locale (IT)
/// e costanti condivise (es. nomi dei mesi) per evitare duplicazioni
/// nelle pagine Years, Months e Days.

class ReportDateUtils {
  
  // --- COSTANTI ---
  // Lista dei nomi dei mesi in italiano.
  // Utilizzata per popolare i grafici e le intestazioni delle liste.
  static const List<String> monthNames = [
    "Gennaio", "Febbraio", "Marzo", "Aprile", "Maggio", "Giugno",
    "Luglio", "Agosto", "Settembre", "Ottobre", "Novembre", "Dicembre",
  ];

  // --- METODI DI FORMATTAZIONE ---

  /// Converte un oggetto DateTime in una stringa formattata completa.
  /// Esempio output: "12 Ottobre 2023"
  static String formatDateItaliano(DateTime date) {
    final giorno = DateFormat("d", "it_IT").format(date);
    final mese = DateFormat("MMMM", "it_IT").format(date);
    final anno = DateFormat("y", "it_IT").format(date);
    
    // Capitalizza la prima lettera del mese (DateFormat restituisce minuscolo in IT)
    final meseCapitalizzato = mese[0].toUpperCase() + mese.substring(1);
    
    return "$giorno $meseCapitalizzato $anno";
  }

  /// Restituisce il nome del giorno della settimana localizzato.
  /// Esempio output: "Lunedì"
  static String getDayOfWeek(DateTime date) {
    final giornoSettimana = DateFormat("EEEE", "it_IT").format(date);
    // Assicura che la prima lettera sia maiuscola
    return giornoSettimana[0].toUpperCase() + giornoSettimana.substring(1);
  }
}