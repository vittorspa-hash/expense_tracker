import 'package:expense_tracker/utils/fade_animation_mixin.dart';
import 'package:flutter/material.dart';
import 'package:expense_tracker/components/expense/expense_edit.dart';
import 'package:expense_tracker/providers/expense_provider.dart';
import 'package:provider/provider.dart';

/// FILE: new_expense_page.dart
/// DESCRIZIONE: Schermata dedicata alla creazione di una nuova spesa.
/// Funge da wrapper attorno al componente riutilizzabile `ExpenseEdit`, 
/// configurandolo per la modalità di inserimento e collegando l'azione di submit
/// al metodo `createExpense` del Provider.

class NewExpensePage extends StatefulWidget {
  static const route = "/expense/new";

  const NewExpensePage({super.key});

  @override
  State<NewExpensePage> createState() => _NewExpensePageState();
}

class _NewExpensePageState extends State<NewExpensePage>
    with SingleTickerProviderStateMixin, FadeAnimationMixin {
  
  // --- CONFIGURAZIONE ANIMAZIONE ---
  // Setup del TickerProvider e definizione della durata per l'effetto 
  // di comparsa (fade-in) all'apertura della pagina.
  @override
  TickerProvider get vsync => this;

  @override
  Duration get fadeAnimationDuration => const Duration(milliseconds: 400);

  // --- CICLO DI VITA ---
  // Inizializzazione e pulizia delle risorse di animazione.
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
  // Callback passata al widget figlio `ExpenseEdit`.
  // Intercetta i dati inseriti dall'utente, invoca l'azione di creazione 
  // sul Provider (senza ascoltare cambiamenti, quindi context.read) e chiude la pagina.
  // 
  void onSubmit({
    required double value,
    required String? description,
    required DateTime date,
  }) {
    context.read<ExpenseProvider>().createExpense(
      value: value,
      description: description,
      date: date,
    );

    Navigator.pop(context);
  }

  // --- BUILD UI ---
  // Costruisce la UI avvolgendo il form di modifica nell'animazione di fade.
  @override
  Widget build(BuildContext context) {
    return buildWithFadeAnimation(ExpenseEdit(onSubmit: onSubmit));
  }
}