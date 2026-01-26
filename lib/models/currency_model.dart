// ignore: dangling_library_doc_comments
/// FILE: currency_model.dart
/// DESCRIZIONE: Model di dominio per le valute supportate dall'applicazione.
/// Definisce le valute disponibili (Euro, USD, GBP, JPY) con le loro proprietà
/// (codice ISO, nome completo, simbolo) e fornisce logica di formattazione
/// per visualizzare correttamente gli importi secondo le convenzioni di ogni valuta.

enum Currency {
  euro('EUR', 'Euro', '€'),
  usd('USD', 'US Dollar', '\$'),
  gbp('GBP', 'British Pound', '£'),
  jpy('JPY', 'Japanese Yen', '¥');

  // --- PROPRIETÀ ---
  // Proprietà immutabili che identificano ciascuna valuta.
  
  final String code;   // Codice ISO 4217 (es. EUR, USD)
  final String name;   // Nome completo della valuta
  final String symbol; // Simbolo grafico della valuta

  const Currency(this.code, this.name, this.symbol);

  // --- BUSINESS LOGIC: FORMATTAZIONE IMPORTI ---
  // Formatta un importo numerico secondo le convenzioni della valuta.
  // Gestisce casi specifici: Yen senza decimali, simbolo prima/dopo l'importo
  // a seconda della valuta (USD/GBP prima, EUR dopo).
  String format(double amount, {bool showSymbol = true}) {
    final formattedAmount = amount.toStringAsFixed(2);
    if (!showSymbol) return formattedAmount;
    
    // Yen giapponese: niente decimali
    if (this == Currency.jpy) {
      return '$symbol${amount.toStringAsFixed(0)}';
    }
    
    // USD e GBP: simbolo prima dell'importo
    if (this == Currency.usd || this == Currency.gbp) {
      return '$symbol$formattedAmount';
    }
    
    // Euro e altre: simbolo dopo l'importo
    return '$formattedAmount$symbol';
  }

  // --- FACTORY METHOD ---
  // Crea un'istanza Currency a partire dal codice ISO.
  // Restituisce Euro come fallback se il codice non è riconosciuto.
  static Currency fromCode(String code) {
    return Currency.values.firstWhere(
      (c) => c.code == code,
      orElse: () => Currency.euro,
    );
  }
}