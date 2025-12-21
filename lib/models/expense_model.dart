// FILE: expense_model.dart
// DESCRIZIONE: Modello dati fondamentale per una singola spesa.
// Gestisce la struttura dati, la serializzazione per il database (Firebase)
// e include metodi di utilità per la clonazione immutabile.

class ExpenseModel {
  // --- PROPRIETÀ ---
  // Definiscono lo stato della spesa. 
  // 
  String uuid;          // ID univoco della spesa
  double value;         // Importo
  String? description;  // Note opzionali
  DateTime createdOn;   // Timestamp creazione
  String userId;        // Riferimento proprietario (Foreign Key logica)

  // --- COSTRUTTORE ---
  ExpenseModel({
    required this.uuid,
    required this.value,
    required this.description,
    required this.createdOn,
    required this.userId,
  });

  // --- SERIALIZZAZIONE (DB -> APP) ---
  // Factory method per creare un'istanza partendo da una Mappa (es. JSON da Firebase).
  // Gestisce la conversione sicura dei tipi numerici e delle date (Epoch ms -> DateTime).
  factory ExpenseModel.fromMap(Map<String, dynamic> data) {
    return ExpenseModel(
      uuid: data["uuid"], 
      value: (data["value"] as num).toDouble(), // Gestione sicura int/double
      description: data["description"], 
      createdOn: DateTime.fromMillisecondsSinceEpoch(
        data["createdOn"],
      ), 
      userId: data["userId"], 
    );
  }

  // --- SERIALIZZAZIONE (APP -> DB) ---
  // Converte l'oggetto in Mappa per il salvataggio su database.
  // Le date vengono convertite in millisecondi (Epoch) per compatibilità.
  Map<String, dynamic> toMap() => {
    "uuid": uuid,
    "value": value,
    "description": description,
    "createdOn": createdOn.millisecondsSinceEpoch,
    "userId": userId,
  };

  // --- UTILITY (COPYWITH) ---
  // Pattern standard per creare una copia modificata dell'oggetto corrente
  // senza alterare l'istanza originale (utile per aggiornamenti di stato parziali).
  ExpenseModel copyWith({
    String? uuid,
    double? value,
    String? description,
    DateTime? createdOn,
    String? userId,
  }) {
    return ExpenseModel(
      uuid: uuid ?? this.uuid,
      value: value ?? this.value,
      description: description ?? this.description,
      createdOn: createdOn ?? this.createdOn,
      userId: userId ?? this.userId,
    );
  }
}