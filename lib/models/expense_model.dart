// FILE: expense_model.dart
// DESCRIZIONE: Modello dati per una singola spesa.
// Gestisce la struttura dati, la serializzazione per il database (Firebase)
// e include metodi di utilità per la clonazione immutabile e la conversione valuta.
import 'package:expense_tracker/models/expense_category.dart';
import 'package:expense_tracker/models/expense_currency.dart';

class ExpenseModel {
  // --- PROPRIETÀ ---
  String uuid;             // ID univoco della spesa
  double value;            // Importo
  String? description;     // Note opzionali
  DateTime createdOn;      // Timestamp creazione
  String userId;           // Riferimento proprietario
  ExpenseCurrency currency;          // Valuta della spesa
  ExpenseCategory category;          // Categoria della spesa
  Map<String, double> exchangeRates; // Snapshot tassi storici al momento della spesa

  // --- COSTRUTTORE ---
  ExpenseModel({
    required this.uuid,
    required this.value,
    required this.description,
    required this.createdOn,
    required this.userId,
    required this.currency,         
    required this.exchangeRates,
    this.category = ExpenseCategory.other, // Default: "Altro" per retrocompatibilità
  });

  // --- SERIALIZZAZIONE (DB -> APP) ---
  factory ExpenseModel.fromMap(Map<String, dynamic> data) {
    // Parsing sicuro della mappa dei tassi
    Map<String, double> parsedRates = {};
    if (data["exchangeRates"] != null) {
      (data["exchangeRates"] as Map<String, dynamic>).forEach((key, val) {
        parsedRates[key] = (val as num).toDouble();
      });
    }

    return ExpenseModel(
      uuid: data["uuid"],
      value: (data["value"] as num).toDouble(),
      description: data["description"],
      createdOn: DateTime.fromMillisecondsSinceEpoch(data["createdOn"]),
      userId: data["userId"],
      // Conversione da String (DB) a Enum (App)
      // Gestione retroattiva valuta: vecchie spese senza valuta → EUR
      currency: ExpenseCurrency.fromCode(data["currency"] ?? "EUR"),
      exchangeRates: parsedRates,
      // Gestione retroattiva categoria: vecchie spese senza categoria → other
      category: ExpenseCategory.fromJson(data["category"]),
    );
  }

  // --- SERIALIZZAZIONE (APP -> DB) ---
  Map<String, dynamic> toMap() => {
    "uuid": uuid,
    "value": value,
    "description": description,
    "createdOn": createdOn.millisecondsSinceEpoch,
    "userId": userId,
    // Conversione da Enum (App) a String (DB)
    "currency": currency.code,
    "exchangeRates": exchangeRates,
    "category": category.toJson(), // Salvata come stringa leggibile
  };

  // --- UTILITY (COPYWITH) ---
  // Clonazione immutabile: restituisce una nuova istanza con i campi modificati.
  // I campi non specificati vengono preservati dall'istanza originale.
  ExpenseModel copyWith({
    String? uuid,
    double? value,
    String? description,
    DateTime? createdOn,
    String? userId,
    ExpenseCurrency? currency,
    Map<String, double>? exchangeRates,
    ExpenseCategory? category,
  }) {
    return ExpenseModel(
      uuid: uuid ?? this.uuid,
      value: value ?? this.value,
      description: description ?? this.description,
      createdOn: createdOn ?? this.createdOn,
      userId: userId ?? this.userId,
      currency: currency ?? this.currency,
      exchangeRates: exchangeRates ?? this.exchangeRates,
      category: category ?? this.category,
    );
  }

  // --- LOGICA DI CONVERSIONE ---
  // Restituisce il valore della spesa convertito nella valuta target
  // utilizzando i tassi storici salvati nell'oggetto.
  double getValueIn(ExpenseCurrency targetCurrency) {
    // 1. Se la valuta target è la stessa della spesa, restituisci il valore originale
    if (currency == targetCurrency) return value;
    // 2. Se non abbiamo tassi salvati (es. vecchia spesa o offline), fallback
    if (exchangeRates.isEmpty) return value;
    // 3. Recupera i tassi relativi alla base comune (es. EUR = 1.0)
    double rateSource = exchangeRates[currency.code] ?? 0.0;
    double rateTarget = exchangeRates[targetCurrency.code] ?? 0.0;
    // 4. Prevenzione divisione per zero
    if (rateSource == 0.0 || rateTarget == 0.0) return value;
    // 5. Formula: (Valore / TassoSorgente) * TassoTarget
    return (value / rateSource) * rateTarget;
  }
}