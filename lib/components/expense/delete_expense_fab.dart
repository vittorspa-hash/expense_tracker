import 'package:expense_tracker/config/app_colors.dart';
import 'package:expense_tracker/config/di/riverpod_providers.dart';
import 'package:expense_tracker/l10n/app_localizations.dart';
import 'package:expense_tracker/models/expense_model.dart';
import 'package:expense_tracker/notifiers/expense_notifier.dart';
import 'package:expense_tracker/utils/dialogs/dialog_utils.dart';
import 'package:expense_tracker/utils/snackbar_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// FILE: delete_expense_fab.dart
/// DESCRIZIONE: Floating Action Button di eliminazione, con dialog di
/// conferma, gestione errore e feedback di successo con opzione Undo.
/// Estratto da ExpenseEdit; è un ConsumerWidget perché ha bisogno di leggere
/// e riusare expenseNotifierProvider per l'esito dell'operazione e il restore.

class DeleteExpenseFab extends ConsumerWidget {
  final IconData icon;
  final Future<ExpenseModel?> Function() onDeletePressed;

  const DeleteExpenseFab({
    super.key,
    required this.icon,
    required this.onDeletePressed,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loc = AppLocalizations.of(context)!;

    return FloatingActionButton(
      heroTag: null,
      backgroundColor: AppColors.delete.withValues(alpha: 0.3),
      foregroundColor: AppColors.delete,
      onPressed: () async {
        final confirm = await DialogUtils.showConfirmDialog(
          context,
          title: loc.deleteConfirmTitle,
          content: loc.deleteConfirmMessageSwipe,
          confirmText: loc.delete,
          cancelText: loc.cancel,
        );

        if (confirm != true) return;

        final deletedExpense = await onDeletePressed();

        if (!context.mounted) return;

        final currentState = ref.read(expenseNotifierProvider).value ?? ExpenseState();

        // Gestione degli errori derivati dal tentativo di cancellazione
        if (currentState.errorMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(currentState.errorMessage!),
              backgroundColor: AppColors.snackBar,
            ),
          );
          return;
        }

        if (deletedExpense != null) {
          final expenseNotifier = ref.read(expenseNotifierProvider.notifier);
          final locCopy = loc;

          SnackbarUtils.show(
            context: context,
            title: loc.deletedTitleSingle,
            message: loc.deleteSuccessMessageSwipe,
            deletedItem: deletedExpense,
            undo: loc.undo,
            navBar: true,
            onDelete: (_) {},
            onRestore: (exp) async {
              await expenseNotifier.restoreExpenses([exp], locCopy);
            },
          );
          if (context.mounted) Navigator.pop(context);
        }
      },
      child: Icon(icon, size: 28.sp),
    );
  }
}