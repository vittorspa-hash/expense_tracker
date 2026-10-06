import 'package:expense_tracker/config/app_colors.dart';
import 'package:expense_tracker/config/di/riverpod_providers.dart';
import 'package:expense_tracker/l10n/app_localizations.dart';
import 'package:expense_tracker/models/expense_model.dart';
import 'package:expense_tracker/notifiers/expense_notifier.dart';
import 'package:expense_tracker/components/shared/expense_tile.dart';
import 'package:expense_tracker/utils/dialogs/dialog_utils.dart';
import 'package:expense_tracker/utils/snackbar_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// FILE: swipe_to_delete_expense_tile.dart
/// DESCRIZIONE: Riga spesa con swipe-to-delete, dialog di conferma, verifica
/// dell'esito dell'operazione sul provider e feedback con Undo. Centralizza
/// un pattern identico che prima era duplicato in HomeContentList e DaysPage:
/// Dismissible -> conferma -> deleteExpenses -> check errore -> snackbar.
class SwipeToDeleteExpenseTile extends ConsumerWidget {
  final ExpenseModel expense;
  final bool isSelectionMode;
  final bool isSelected;
  final VoidCallback onLongPress;
  final VoidCallback onSelectToggle;
  final VoidCallback onReturn;

  const SwipeToDeleteExpenseTile({
    super.key,
    required this.expense,
    required this.isSelectionMode,
    required this.isSelected,
    required this.onLongPress,
    required this.onSelectToggle,
    this.onReturn = _noOp,
  });

  static void _noOp() {}

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loc = AppLocalizations.of(context)!;

    return Dismissible(
      key: Key(expense.uuid),
      direction: isSelectionMode ? DismissDirection.none : DismissDirection.endToStart,
      background: _buildDismissibleBackground(),

      // --- LOGICA DISMISS (SWIPE TO DELETE) ---
      // Conferma UI -> chiamata provider -> verifica errore (letto DOPO
      // l'operazione, non prima) -> feedback con Undo.
      confirmDismiss: (_) async {
        if (isSelectionMode) return false;

        // Cache preventiva dei riferimenti asincroni, validi anche se il
        // widget viene smontato prima che le Future si risolvano.
        final expenseNotifier = ref.read(expenseNotifierProvider.notifier);
        final locCopy = loc;

        final confirm = await DialogUtils.showConfirmDialog(
          context,
          title: loc.deleteConfirmTitle,
          content: loc.deleteConfirmMessageSwipe,
          confirmText: loc.delete,
          cancelText: loc.cancel,
        );

        if (confirm != true) return false;

        await expenseNotifier.deleteExpenses([expense]);

        final currentState = ref.read(expenseNotifierProvider).value ?? ExpenseState();
        if (currentState.errorMessage != null) return false;

        if (context.mounted) {
          SnackbarUtils.show(
            context: context,
            title: loc.deletedTitleSingle,
            message: loc.deleteSuccessMessageSwipe,
            undo: loc.undo,
            deletedItem: expense,
            navBar: true,
            onDelete: (_) {},
            onRestore: (exp) => expenseNotifier.restoreExpenses([exp], locCopy),
          );
        }
        return true;
      },
      onDismissed: (_) {},
      child: ExpenseTile(
        expense,
        isSelectionMode: isSelectionMode,
        isSelected: isSelected,
        onLongPress: onLongPress,
        onSelectToggle: onSelectToggle,
        onReturn: onReturn,
      ),
    );
  }

  Widget _buildDismissibleBackground() {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 4.h),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.delete.withValues(alpha: 0.8), AppColors.delete],
        ),
        borderRadius: BorderRadius.circular(16.r),
      ),
      alignment: Alignment.centerRight,
      padding: EdgeInsets.symmetric(horizontal: 24.w),
      child: Icon(Icons.delete_rounded, color: AppColors.textLight, size: 28.sp),
    );
  }
}