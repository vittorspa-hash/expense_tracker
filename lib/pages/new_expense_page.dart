import 'package:expense_tracker/l10n/app_localizations.dart';
import 'package:expense_tracker/providers/currency_provider.dart';
import 'package:expense_tracker/theme/app_colors.dart';
import 'package:expense_tracker/utils/fade_animation_mixin.dart';
import 'package:flutter/material.dart';
import 'package:expense_tracker/components/expense/expense_edit.dart';
import 'package:expense_tracker/providers/expense_provider.dart';
import 'package:provider/provider.dart';

/// FILE: new_expense_page.dart
/// DESCRIZIONE: Pagina per la creazione di una nuova spesa.
/// Funge da container per il componente riutilizzabile ExpenseEdit, iniettando
/// la logica specifica per la creazione (createExpense) e gestendo la navigazione
/// in base all'esito dell'operazione asincrona.

class NewExpensePage extends StatefulWidget {
  static const route = "/expense/new";

  const NewExpensePage({super.key});

  @override
  State<NewExpensePage> createState() => _NewExpensePageState();
}

class _NewExpensePageState extends State<NewExpensePage>
    with SingleTickerProviderStateMixin, FadeAnimationMixin {
  
  // --- ANIMAZIONI ---
  // Configurazione del mixin per l'effetto di fade-in all'apertura della pagina.
  @override
  TickerProvider get vsync => this;

  @override
  Duration get fadeAnimationDuration => const Duration(milliseconds: 400);

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

  // --- LOGICA DI SALVATAGGIO ---
  // Callback passata al form ExpenseEdit. Esegue la creazione della spesa tramite Provider.
  // Se l'operazione ha successo, chiude la pagina (pop).
  // Se fallisce (es. errore connessione), mostra una SnackBar e mantiene l'utente sulla pagina.
  Future<void> onSubmit({
    required double value,
    required String? description,
    required DateTime date,
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

  @override
  Widget build(BuildContext context) {
    return buildWithFadeAnimation(ExpenseEdit(onSubmit: onSubmit));
  }
}