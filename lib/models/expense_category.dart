import 'package:flutter/material.dart';

// ---------------------------------------------------------------------------
// ENUM: ExpenseCategory
// ---------------------------------------------------------------------------
// Ogni variante espone due proprietà calcolate:
//   • icon      → IconData Material da mostrare nell'UI
//   • labelKey  → Chiave stringa per la localizzazione (l10n)
// ---------------------------------------------------------------------------

enum ExpenseCategory {
  food,
  transport,
  home,
  health,
  entertainment,
  shopping,
  education,
  travel,
  other;

  // --- ICONA MATERIAL associata alla categoria ---
  IconData get icon {
    switch (this) {
      case ExpenseCategory.food:
        return Icons.restaurant;
      case ExpenseCategory.transport:
        return Icons.directions_car;
      case ExpenseCategory.home:
        return Icons.home;
      case ExpenseCategory.health:
        return Icons.local_hospital;
      case ExpenseCategory.entertainment:
        return Icons.movie;
      case ExpenseCategory.shopping:
        return Icons.shopping_bag;
      case ExpenseCategory.education:
        return Icons.school;
      case ExpenseCategory.travel:
        return Icons.flight;
      case ExpenseCategory.other:
        return Icons.category;
    }
  }

  // --- CHIAVE L10N per la traduzione nell'UI ---
  String get labelKey {
    switch (this) {
      case ExpenseCategory.food:
        return 'categoryFood';
      case ExpenseCategory.transport:
        return 'categoryTransport';
      case ExpenseCategory.home:
        return 'categoryHome';
      case ExpenseCategory.health:
        return 'categoryHealth';
      case ExpenseCategory.entertainment:
        return 'categoryEntertainment';
      case ExpenseCategory.shopping:
        return 'categoryShopping';
      case ExpenseCategory.education:
        return 'categoryEducation';
      case ExpenseCategory.travel:
        return 'categoryTravel';
      case ExpenseCategory.other:
        return 'categoryOther';
    }
  }

  // ---------------------------------------------------------------------------
  // SERIALIZZAZIONE: enum <-> String (per Firestore)
  // ---------------------------------------------------------------------------

  /// Converte la categoria in stringa leggibile per il salvataggio su DB.
  /// Es: ExpenseCategory.food → "food"
  String toJson() => name;

  /// Ricrea la categoria da una stringa proveniente dal DB.
  /// Se la stringa è sconosciuta (dati corrotti o categoria deprecata),
  /// restituisce [ExpenseCategory.other] come fallback sicuro.
  static ExpenseCategory fromJson(String? value) {
    if (value == null) return ExpenseCategory.other;
    return ExpenseCategory.values.firstWhere(
      (e) => e.name == value,
      orElse: () => ExpenseCategory.other,
    );
  }
}
