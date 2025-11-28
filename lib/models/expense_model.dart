// expense_model.dart
// Modello che rappresenta una singola spesa dell'utente.
// Contiene informazioni su valore, descrizione, data di creazione e proprietario.

class ExpenseModel {
  // Identificatore univoco della spesa
  String uuid;

  // Valore numerico della spesa
  double value;

  // Descrizione opzionale della spesa
  String? description;

  // Data e ora in cui è stata creata la spesa
  DateTime createdOn;

  // ID dell'utente proprietario della spesa
  String userId;

  // Costruttore principale
  ExpenseModel({
    required this.uuid,
    required this.value,
    required this.description,
    required this.createdOn,
    required this.userId,
  });

  // Factory per creare un ExpenseModel da una mappa (es. dati Firebase)
  factory ExpenseModel.fromMap(Map<String, dynamic> data) {
    return ExpenseModel(
      uuid: data["uuid"], // Recupera l'UUID
      value: (data["value"] as num).toDouble(), // Converte il valore in double
      description: data["description"], // Descrizione opzionale
      createdOn: DateTime.fromMillisecondsSinceEpoch(
        data["createdOn"],
      ), // Converte millisecondi in DateTime
      userId: data["userId"], // ID dell'utente
    );
  }

  // Converte l'oggetto in mappa (utile per salvare su Firebase)
  Map<String, dynamic> toMap() => {
    "uuid": uuid,
    "value": value,
    "description": description,
    "createdOn":
        createdOn.millisecondsSinceEpoch, // Salva la data in millisecondi
    "userId": userId,
  };

  // Crea una copia modificata dell'oggetto
  // Utile per aggiornamenti senza alterare l'originale
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
