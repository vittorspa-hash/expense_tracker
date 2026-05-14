import 'package:expense_tracker/config/di/riverpod_providers.dart';
import 'package:expense_tracker/l10n/app_localizations.dart';
import 'package:expense_tracker/models/expense_category.dart';
import 'package:expense_tracker/models/expense_currency.dart';
import 'package:expense_tracker/utils/fade_animation_mixin.dart';
import 'package:flutter/material.dart';
import 'package:expense_tracker/components/expense/expense_edit.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// FILE: new_expense_page.dart
/// DESCRIZIONE: Pagina dedicata alla creazione di una nuova spesa.
/// Funge da wrapper per il componente riutilizzabile ExpenseEdit, gestendo
/// specificamente la logica di creazione (onSubmit) e l'animazione di ingresso.

class NewExpensePage extends ConsumerStatefulWidget {
  static const route = "/expense/new";
  const NewExpensePage({super.key});

  @override
  ConsumerState<NewExpensePage> createState() => _NewExpensePageState();
}

class _NewExpensePageState extends ConsumerState<NewExpensePage>
    with SingleTickerProviderStateMixin, FadeAnimationMixin {
  // --- CONFIGURAZIONE ANIMAZIONE ---
  @override
  TickerProvider get vsync => this;

  @override
  Duration get fadeAnimationDuration => const Duration(milliseconds: 400);

  // --- CICLO DI VITA ---
  @override
  void initState() {
    super.initState();
    initFadeAnimation();
  }

  @override
  void dispose() {
    disposeFadeAnimation();
    super.dispose();
  }

  // --- LOGICA DI CREAZIONE ---
  // Callback invocata quando l'utente conferma l'inserimento nel form.
  // Ora include il parametro category selezionato dall'utente.
  Future<void> onSubmit({
    required double value,
    required String? description,
    required DateTime date,
    required ExpenseCurrency currencyCode,
    required ExpenseCategory category, 
    required AppLocalizations l10n,
  }) async {
    
    await ref.read(expenseNotifierProvider.notifier).createExpense(
      value: value,
      description: description,
      date: date,
      l10n: l10n,
      currencyCode: currencyCode,
      category: category, 
    );
  }

  // --- COSTRUZIONE UI ---
  @override
  Widget build(BuildContext context) {
    return buildWithFadeAnimation(ExpenseEdit(onSubmit: onSubmit));
  }
}