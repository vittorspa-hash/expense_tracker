/// FILE: expense_currency.dart
/// DESCRIZIONE: Enum di dominio per le valute supportate dall'applicazione.
/// Definisce le valute disponibili (Euro, USD, GBP, JPY) con le loro proprietà
/// (codice ISO, nome completo, simbolo) e fornisce logica di formattazione
/// per visualizzare correttamente gli importi secondo le convenzioni di ogni valuta.
enum ExpenseCurrency {
  euro('EUR', 'Euro', '€'),
  usd('USD', 'US Dollar', '\$'),
  gbp('GBP', 'British Pound', '£'),
  jpy('JPY', 'Japanese Yen', '¥');

  // --- PROPRIETÀ ---
  // Proprietà immutabili che identificano ciascuna valuta.
  final String code;   // Codice ISO 4217 (es. EUR, USD)
  final String name;   // Nome completo della valuta
  final String symbol; // Simbolo grafico della valuta

  const ExpenseCurrency(this.code, this.name, this.symbol);

  // --- BUSINESS LOGIC: FORMATTAZIONE IMPORTI ---
  // Formatta un importo numerico secondo le convenzioni della valuta.
  // Gestisce casi specifici: Yen senza decimali, simbolo prima/dopo l'importo
  // a seconda della valuta (USD/GBP prima, EUR dopo).
  String format(double amount, {bool showSymbol = true}) {
    final formattedAmount = amount.toStringAsFixed(2);
    if (!showSymbol) return formattedAmount;

    // Yen giapponese: nessun decimale per convenzione
    if (this == ExpenseCurrency.jpy) {
      return '$symbol${amount.toStringAsFixed(0)}';
    }

    // USD e GBP: simbolo anteposto all'importo
    if (this == ExpenseCurrency.usd || this == ExpenseCurrency.gbp) {
      return '$symbol$formattedAmount';
    }

    // Euro e altre: simbolo dopo l'importo
    return '$formattedAmount$symbol';
  }

  // --- FACTORY METHOD ---
  // Crea un'istanza ExpenseCurrency a partire dal codice ISO.
  // Restituisce Euro come fallback se il codice non è riconosciuto,
  // garantendo retrocompatibilità con spese salvate senza valuta.
  static ExpenseCurrency fromCode(String code) {
    return ExpenseCurrency.values.firstWhere(
      (c) => c.code == code,
      orElse: () => ExpenseCurrency.euro,
    );
  }
}