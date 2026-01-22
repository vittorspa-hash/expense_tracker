// ignore: dangling_library_doc_comments
/// FILE: models/currency.dart
/// DESCRIZIONE: Model di dominio per le valute supportate

enum Currency {
  euro('EUR', 'Euro', '€'),
  usd('USD', 'US Dollar', '\$'),
  gbp('GBP', 'British Pound', '£'),
  jpy('JPY', 'Japanese Yen', '¥');

  final String code;
  final String name;
  final String symbol;

  const Currency(this.code, this.name, this.symbol);

  /// Business logic: Formattazione importi
  String format(double amount, {bool showSymbol = true}) {
    final formattedAmount = amount.toStringAsFixed(2);
    if (!showSymbol) return formattedAmount;

    if (this == Currency.jpy) {
      return '$symbol${amount.toStringAsFixed(0)}';
    }
    if (this == Currency.usd || this == Currency.gbp) {
      return '$symbol$formattedAmount';
    }
    return '$formattedAmount$symbol';
  }

  static Currency fromCode(String code) {
    return Currency.values.firstWhere(
      (c) => c.code == code,
      orElse: () => Currency.euro,
    );
  }
}