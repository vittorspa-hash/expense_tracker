import 'package:expense_tracker/l10n/app_localizations.dart';
import 'package:expense_tracker/providers/currency_provider.dart';
import 'package:expense_tracker/theme/app_colors.dart';
import 'package:expense_tracker/utils/fade_animation_mixin.dart';
import 'package:flutter/material.dart';
import 'package:expense_tracker/components/expense/expense_edit.dart';
import 'package:expense_tracker/providers/expense_provider.dart';
import 'package:provider/provider.dart';

/// FILE: new_expense_page.dart
/// DESCRIZIONE: Pagina dedicata alla creazione di una nuova spesa.
/// Funge da wrapper per il componente riutilizzabile ExpenseEdit, gestendo
/// specificamente la logica di creazione (onSubmit) e l'animazione di ingresso.

class NewExpensePage extends StatefulWidget {
  static const route = "/expense/new";

  const NewExpensePage({super.key});

  @override
  State<NewExpensePage> createState() => _NewExpensePageState();
}

class _NewExpensePageState extends State<NewExpensePage>
    with SingleTickerProviderStateMixin, FadeAnimationMixin {
  
  // --- CONFIGURAZIONE ANIMAZIONE ---
  // Implementazione dei getter richiesti dal FadeAnimationMixin.
  // vsync fornisce il ticker necessario per controllare l'animazione.
  @override
  TickerProvider get vsync => this;

  @override
  Duration get fadeAnimationDuration => const Duration(milliseconds: 400);

  // --- CICLO DI VITA ---
  // Inizializza l'animazione all'apertura della pagina e libera le risorse alla chiusura.
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
  // Recupera i provider necessari, tenta la creazione della spesa e gestisce
  // il feedback visivo (chiusura pagina o snackbar di errore).
  Future<void> onSubmit({
    required double value,
    required String? description,
    required DateTime date,
    required String currencyCode, 
    required AppLocalizations l10n
  }) async {
    final provider = context.read<ExpenseProvider>();
    final currencySymbol = context.read<CurrencyProvider>().currencySymbol;

    await provider.createExpense(
      value: value,
      description: description,
      date: date,
      l10n: l10n,
      currencySymbol: currencySymbol,
      currencyCode: currencyCode, 
    );

    if (!mounted) return;

    if (provider.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(provider.errorMessage!),
          backgroundColor: AppColors.snackBar,
        ),
      );
      return; 
    }

    Navigator.pop(context);
  }

  // --- COSTRUZIONE UI ---
  // Renderizza il componente ExpenseEdit avvolto nell'animazione di dissolvenza.
  // Non vengono passati parametri opzionali come initialValue poiché si tratta di una nuova spesa.
  @override
  Widget build(BuildContext context) {
    return buildWithFadeAnimation(ExpenseEdit(onSubmit: onSubmit));
  }
}