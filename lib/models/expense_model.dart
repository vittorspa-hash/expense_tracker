// FILE: expense_model.dart
// DESCRIZIONE: Modello dati fondamentale per una singola spesa.
// Gestisce la struttura dati, la serializzazione per il database (Firebase)
// e include metodi di utilità per la clonazione immutabile e la conversione valuta.

class ExpenseModel {
  // --- PROPRIETÀ ---
  String uuid;           // ID univoco della spesa
  double value;          // Importo
  String? description;   // Note opzionali
  DateTime createdOn;    // Timestamp creazione
  String userId;         // Riferimento proprietario
  
  // NUOVE PROPRIETÀ PER MULTI-VALUTA
  String currency;                   // Codice valuta in cui è stata salvata la spesa (es. "USD")
  Map<String, double> exchangeRates; // Snapshot dei tassi di cambio al momento della spesa

  // --- COSTRUTTORE ---
  ExpenseModel({
    required this.uuid,
    required this.value,
    required this.description,
    required this.createdOn,
    required this.userId,
    required this.currency,      // Ora richiesto
    required this.exchangeRates, // Ora richiesto
  });

  // --- SERIALIZZAZIONE (DB -> APP) ---
  factory ExpenseModel.fromMap(Map<String, dynamic> data) {
    // Parsing sicuro della mappa dei tassi
    // Se 'exchangeRates' è null (vecchie spese), usiamo una mappa vuota.
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
      // Gestione retroattiva: se la spesa è vecchia e non ha valuta, assumiamo EUR
      currency: data["currency"] ?? "EUR", 
      exchangeRates: parsedRates,
    );
  }

  // --- SERIALIZZAZIONE (APP -> DB) ---
  Map<String, dynamic> toMap() => {
    "uuid": uuid,
    "value": value,
    "description": description,
    "createdOn": createdOn.millisecondsSinceEpoch,
    "userId": userId,
    "currency": currency,
    "exchangeRates": exchangeRates,
  };

  // --- UTILITY (COPYWITH) ---
  ExpenseModel copyWith({
    String? uuid,
    double? value,
    String? description,
    DateTime? createdOn,
    String? userId,
    String? currency,
    Map<String, double>? exchangeRates,
  }) {
    return ExpenseModel(
      uuid: uuid ?? this.uuid,
      value: value ?? this.value,
      description: description ?? this.description,
      createdOn: createdOn ?? this.createdOn,
      userId: userId ?? this.userId,
      currency: currency ?? this.currency,
      exchangeRates: exchangeRates ?? this.exchangeRates,
    );
  }

  // --- LOGICA DI CONVERSIONE ---
  // Restituisce il valore della spesa convertito nella valuta target
  // utilizzando i tassi storici salvati nell'oggetto.
  double getValueIn(String targetCurrency) {
    // 1. Se la valuta target è la stessa della spesa, restituisci il valore originale
    if (currency == targetCurrency) return value;

    // 2. Se non abbiamo tassi salvati (es. vecchia spesa o offline), restituisci valore originale (fallback)
    if (exchangeRates.isEmpty) return value;

    // 3. Recupera i tassi. Assumiamo che i tassi siano relativi a una base comune (es. EUR = 1.0)
    // Se la valuta non è trovata nella mappa, fallback a 1.0 per evitare crash
    double rateSource = exchangeRates[currency] ?? 0.0;
    double rateTarget = exchangeRates[targetCurrency] ?? 0.0;

    // 4. Prevenzione divisione per zero
    if (rateSource == 0.0 || rateTarget == 0.0) return value;

    // 5. Formula di conversione: (Valore / TassoSorgente) * TassoTarget
    return (value / rateSource) * rateTarget;
  }
}