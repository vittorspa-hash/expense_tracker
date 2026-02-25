import 'package:expense_tracker/models/expense_category.dart';
import 'package:expense_tracker/models/expense_currency.dart';

class ExpenseModel {
  String uuid;
  double value;
  String? description;
  DateTime createdOn;
  String userId;
  
  // ORA ENTRAMBI SONO ENUM
  ExpenseCurrency currency; 
  ExpenseCategory category;
  
  Map<String, double> exchangeRates;

  ExpenseModel({
    required this.uuid,
    required this.value,
    required this.description,
    required this.createdOn,
    required this.userId,
    required this.currency, // Richiede l'enum
    required this.exchangeRates,
    this.category = ExpenseCategory.other,
  });

  factory ExpenseModel.fromMap(Map<String, dynamic> data) {
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
      currency: ExpenseCurrency.fromCode(data["currency"] ?? "EUR"), 
      exchangeRates: parsedRates,
      category: ExpenseCategory.fromJson(data["category"]),
    );
  }

  Map<String, dynamic> toMap() => {
        "uuid": uuid,
        "value": value,
        "description": description,
        "createdOn": createdOn.millisecondsSinceEpoch,
        "userId": userId,
        // Conversione da Enum (App) a String (DB)
        "currency": currency.code, 
        "exchangeRates": exchangeRates,
        "category": category.toJson(),
      };

  // Aggiorna anche il copyWith
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

  double getValueIn(ExpenseCurrency targetCurrency) {
  // Molto più pulito e sicuro
  if (currency == targetCurrency) return value;
  if (exchangeRates.isEmpty) return value;

  double rateSource = exchangeRates[currency.code] ?? 0.0;
  double rateTarget = exchangeRates[targetCurrency.code] ?? 0.0;

  if (rateSource == 0.0 || rateTarget == 0.0) return value;
  return (value / rateSource) * rateTarget;
}
}