import 'package:expense_tracker/l10n/app_localizations.dart';
import 'package:expense_tracker/theme/app_colors.dart';
import 'package:expense_tracker/utils/fade_animation_mixin.dart';
import 'package:flutter/material.dart';
import 'package:expense_tracker/components/expense/expense_edit.dart';
import 'package:expense_tracker/models/expense_model.dart';
import 'package:expense_tracker/providers/expense_provider.dart';
import 'package:expense_tracker/utils/snackbar_utils.dart'; // Importante per Undo
import 'package:provider/provider.dart';

/// FILE: edit_expense_page.dart
/// DESCRIZIONE: Pagina per la modifica di una spesa esistente.
/// Riceve un modello di spesa tramite costruttore e popola il form `ExpenseEdit`.
/// Gestisce la logica specifica di aggiornamento (Update) ed eliminazione (Delete),
/// inclusa la gestione della UX per il feedback (SnackBar) durante la chiusura della pagina.

class EditExpensePage extends StatefulWidget {
  static const route = "/expense/edit";
  final ExpenseModel expenseModel;

  const EditExpensePage(this.expenseModel, {super.key});

  @override
  State<EditExpensePage> createState() => _EditExpensePageState();
}

class _EditExpensePageState extends State<EditExpensePage>
    with SingleTickerProviderStateMixin, FadeAnimationMixin {
  
  // --- ANIMAZIONI ---
  // Configurazione del mixin per l'effetto di fade-in.
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

  // --- UPDATE (SALVATAGGIO) ---
  // Esegue l'aggiornamento dei dati tramite Provider.
  // In caso di errore mostra un avviso e mantiene l'utente nella pagina per correggere.
  // In caso di successo, chiude la pagina.
  Future<void> onSubmit({
    required double value,
    required String? description,
    required DateTime date,
  }) async {
    final provider = context.read<ExpenseProvider>();

    await provider.editExpense(
      widget.expenseModel,
      value: value,
      description: description,
      date: date,
    );

    if (!mounted) return;

    // Check Errore
    if (provider.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(provider.errorMessage!), backgroundColor: AppColors.snackBar),
      );
      provider.clearError();
      return;
    }

    Navigator.pop(context);
  }

  // --- DELETE (ELIMINAZIONE) ---
  // Gestisce l'eliminazione della spesa corrente.
  // Poiché la pagina viene chiusa immediatamente dopo il successo, la SnackBar di conferma/undo
  // viene invocata manualmente qui (nel contesto parent) invece che delegata al widget figlio.
  Future<ExpenseModel?> onDelete() async {
    final provider = context.read<ExpenseProvider>();
    final modelToDelete = widget.expenseModel;
    final loc = AppLocalizations.of(context)!;

    await provider.deleteExpenses([modelToDelete]);

    if (!mounted) return null;

    // Check Errore
    if (provider.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(provider.errorMessage!), backgroundColor: AppColors.snackBar),
      );
      return null; // Ritorna null per fermare ExpenseEdit
    }

    // SUCCESSO E UNDO
    // Poiché stiamo per chiudere la pagina (pop), ExpenseEdit verrà smontato 
    // e non potrà mostrare la sua SnackBar interna.
    // La mostriamo noi manualmente qui prima di uscire.
    SnackbarUtils.show(
      context: context,
      title: loc.deletedTitleSingle,
      message: loc.deleteSuccessMessageSwipe,
      deletedItem: modelToDelete,
      onDelete: (_) {}, // Già eliminata
      onRestore: (exp) => provider.restoreExpenses([exp]),
    );

    Navigator.pop(context);
    return null; // Ritorniamo null perché abbiamo già gestito tutto noi
  }

  @override
  Widget build(BuildContext context) {
    return buildWithFadeAnimation(
      ExpenseEdit(
        initialValue: widget.expenseModel.value,
        initialDescription: widget.expenseModel.description,
        initialDate: widget.expenseModel.createdOn,

        floatingActionButtonIcon: Icons.delete,
        
        // Colleghiamo la nostra logica custom di delete
        onFloatingActionButtonPressed: onDelete,

        onSubmit: onSubmit,
      ),
    );
  }
}