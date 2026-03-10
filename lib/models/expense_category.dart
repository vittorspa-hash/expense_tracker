import 'package:expense_tracker/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

/// FILE: expense_category.dart
/// DESCRIZIONE: Enum di dominio per le categorie di spesa supportate dall'applicazione.
/// Ogni variante espone un'icona Material e una label localizzata tramite AppLocalizations,
/// e fornisce logica di serializzazione per il salvataggio e il recupero da Firestore.
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

  // --- LABEL LOCALIZZATA ---
  // Restituisce la stringa tradotta corrispondente alla categoria.
  // Centralizzato nell'enum per evitare duplicazione nei widget che mostrano la categoria.
  String label(AppLocalizations loc) {
    switch (this) {
      case ExpenseCategory.food:
        return loc.categoryFood;
      case ExpenseCategory.transport:
        return loc.categoryTransport;
      case ExpenseCategory.home:
        return loc.categoryHome;
      case ExpenseCategory.health:
        return loc.categoryHealth;
      case ExpenseCategory.entertainment:
        return loc.categoryEntertainment;
      case ExpenseCategory.shopping:
        return loc.categoryShopping;
      case ExpenseCategory.education:
        return loc.categoryEducation;
      case ExpenseCategory.travel:
        return loc.categoryTravel;
      case ExpenseCategory.other:
        return loc.categoryOther;
    }
  }

  // --- COLORE SEMANTICO associato alla categoria ---
  // Source of truth centralizzata per la rappresentazione visiva della categoria.
  // Usato in grafici, badge e qualsiasi widget che necessiti di un colore per categoria.
  Color get color {
    switch (this) {
      case ExpenseCategory.food:
        return const Color(0xFFFF6B6B);
      case ExpenseCategory.transport:
        return const Color(0xFF4ECDC4);
      case ExpenseCategory.home:
        return const Color(0xFF45B7D1);
      case ExpenseCategory.health:
        return const Color(0xFF06D6A0);
      case ExpenseCategory.entertainment:
        return const Color(0xFFFFBE0B);
      case ExpenseCategory.shopping:
        return const Color(0xFFFF9F1C);
      case ExpenseCategory.education:
        return const Color(0xFF7B2FBE);
      case ExpenseCategory.travel:
        return const Color(0xFFE76F51);
      case ExpenseCategory.other:
        return const Color(0xFF8D99AE);
    }
  }

  // --- SERIALIZZAZIONE: enum <-> String (per Firestore) ---

  // Converte la categoria in stringa leggibile per il salvataggio su DB.
  // Es: ExpenseCategory.food → "food"
  String toJson() => name;

  // Ricrea la categoria da una stringa proveniente dal DB.
  // Se la stringa è sconosciuta (dati corrotti o categoria deprecata),
  // restituisce [ExpenseCategory.other] come fallback sicuro.
  static ExpenseCategory fromJson(String? value) {
    if (value == null) return ExpenseCategory.other;
    return ExpenseCategory.values.firstWhere(
      (e) => e.name == value,
      orElse: () => ExpenseCategory.other,
    );
  }
}
