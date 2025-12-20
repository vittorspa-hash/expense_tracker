// days_page.dart

import 'package:expense_tracker/components/report/total_card_widget.dart';
import 'package:expense_tracker/components/shared/custom_appbar.dart';
import 'package:expense_tracker/providers/multi_select_provider.dart';
import 'package:expense_tracker/utils/fade_animation_mixin.dart';
import 'package:expense_tracker/utils/snackbar_utils.dart';
import 'package:expense_tracker/utils/dialog_utils.dart';
import 'package:expense_tracker/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:expense_tracker/providers/expense_provider.dart';
import 'package:expense_tracker/components/shared/expense_tile.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class DaysPage extends StatefulWidget {
  static const route = "/days";

  final int year;
  final int month;
  final int day;

  const DaysPage({
    super.key,
    required this.year,
    required this.month,
    required this.day,
  });

  @override
  State<DaysPage> createState() => _DaysPageState();
}

class _DaysPageState extends State<DaysPage>
    with SingleTickerProviderStateMixin, FadeAnimationMixin {
  @override
  TickerProvider get vsync => this;

  @override
  void initState() {
    super.initState();
    initFadeAnimation();

    // Reset della selezione quando si entra nella pagina per evitare residui
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<MultiSelectProvider>().cancelSelection();
      }
    });
  }

  @override
  void dispose() {
    disposeFadeAnimation();
    super.dispose();
  }

  String formatDateItaliano(DateTime date) {
    final giorno = DateFormat("d", "it_IT").format(date);
    final mese = DateFormat("MMMM", "it_IT").format(date);
    final anno = DateFormat("y", "it_IT").format(date);
    final meseCapitalizzato = mese[0].toUpperCase() + mese.substring(1);
    return "$giorno $meseCapitalizzato $anno";
  }

  String getDayOfWeek(DateTime date) {
    final giornoSettimana = DateFormat("EEEE", "it_IT").format(date);
    return giornoSettimana[0].toUpperCase() + giornoSettimana.substring(1);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final date = DateTime(widget.year, widget.month, widget.day);
    final dateLabel = formatDateItaliano(date);
    final dayOfWeek = getDayOfWeek(date);

    return Consumer2<ExpenseProvider, MultiSelectProvider>(
      builder: (context, expenseProvider, multiSelect, child) {
        // Recupero la lista delle spese del giorno
        final expensesList = expenseProvider.expensesOfDay(
          widget.year,
          widget.month,
          widget.day,
        );

        final isSelectionMode = multiSelect.isSelectionMode;
        final selectedCount = multiSelect.selectedCount;

        return Scaffold(
          appBar: isSelectionMode
              ? CustomAppBar(
                  title: "",
                  isDark: isDark,
                  isSelectionMode: true,
                  selectedCount: selectedCount,
                  totalCount: expensesList.length,
                  onCancelSelection: multiSelect.cancelSelection,
                  // 👇 Qui colleghiamo la funzione locale
                  onDeleteSelected: _handleDeleteSelected,
                  onSelectAll: () => multiSelect.selectAll(expensesList),
                  onDeselectAll: multiSelect.deselectAll,
                )
              : CustomAppBar(
                  title: dayOfWeek,
                  subtitle: dateLabel,
                  isDark: isDark,
                  icon: Icons.calendar_today_rounded,
                ),
          body: Container(
            decoration: BoxDecoration(
              color: isDark
                  ? AppColors.backgroundDark
                  : AppColors.backgroundLight,
            ),
            child: SafeArea(
              child: _buildBody(
                context,
                expensesList,
                isSelectionMode,
                multiSelect,
                expenseProvider,
                isDark,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildBody(
    BuildContext context,
    List<dynamic> expensesList,
    bool isSelectionMode,
    MultiSelectProvider multiSelect,
    ExpenseProvider expenseprovider,
    bool isDark,
  ) {
    if (expensesList.isEmpty) {
      return buildWithFadeAnimation(Center(child: _buildEmptyState(isDark)));
    }

    final totalDay = expensesList.fold<double>(
      0.0,
      (sum, expense) => sum + expense.value,
    );

    return buildWithFadeAnimation(
      Column(
        children: [
          TotalCardWidget(
            label: "Totale giornata",
            totalAmount: totalDay,
            icon: Icons.receipt_rounded,
            itemCount: expensesList.length,
            itemLabel: expensesList.length == 1 ? "spesa" : "spese",
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 20.w),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "Tutte le spese",
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w700,
                  color: isDark ? AppColors.greyDark : AppColors.greyLight,
                  letterSpacing: 0.3,
                ),
              ),
            ),
          ),
          SizedBox(height: 12.h),
          Expanded(
            child: RefreshIndicator(
              color: AppColors.primary,
              onRefresh: () async {
                multiSelect.cancelSelection();
                await expenseprovider.initialise();
              },
              child: ListView.separated(
                padding: EdgeInsets.fromLTRB(20.w, 0, 20.w, 20.h),
                itemCount: expensesList.length,
                separatorBuilder: (_, _) => SizedBox(height: 4.h),
                itemBuilder: (context, index) {
                  final expense = expensesList[index];
                  final isSelected = multiSelect.selectedIds.contains(
                    expense.uuid,
                  );

                  return Dismissible(
                    key: Key(expense.uuid),
                    direction: isSelectionMode
                        ? DismissDirection.none
                        : DismissDirection.endToStart,
                    confirmDismiss: (_) async {
                      if (isSelectionMode) return false;
                      final confirm = await DialogUtils.showConfirmDialog(
                        context,
                        title: "Conferma eliminazione",
                        content: "Vuoi eliminare la spesa selezionata?",
                        confirmText: "Elimina",
                        cancelText: "Annulla",
                      );
                      return confirm ?? false;
                    },
                    background: _buildDismissibleBackground(),
                    onDismissed: (_) {
                      SnackbarUtils.show(
                        context: context,
                        title: "Eliminata!",
                        message: "Spesa eliminata con successo.",
                        deletedItem: expense,
                        // Qui chiamiamo direttamente il provider perché è uno Swipe Singolo
                        onDelete: (exp) => expenseprovider.deleteExpense(exp),
                        onRestore: (exp) => expenseprovider.restoreExpense(exp),
                      );
                    },
                    child: ExpenseTile(
                      expense,
                      isSelectionMode: isSelectionMode,
                      isSelected: isSelected,
                      onLongPress: () => multiSelect.onLongPress(expense),
                      onSelectToggle: () => multiSelect.onToggleSelect(expense),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: EdgeInsets.all(24.w),
          decoration: BoxDecoration(
            color: isDark ? AppColors.secondaryDark : AppColors.secondaryLight,
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.receipt_long_rounded,
            size: 64.sp,
            color: isDark ? AppColors.greyLight : AppColors.greyDark,
          ),
        ),
        SizedBox(height: 24.h),
        Text(
          "Nessuna spesa in questo giorno",
          style: TextStyle(
            fontSize: 16.sp,
            color: isDark ? AppColors.textLight : AppColors.textDark2,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
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
      child: Icon(
        Icons.delete_rounded,
        color: AppColors.textLight,
        size: 28.sp,
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 🗑️ GESTIONE ELIMINAZIONE SELEZIONATI
  // ---------------------------------------------------------------------------
  Future<void> _handleDeleteSelected() async {
    final multiSelect = context.read<MultiSelectProvider>();
    final count = multiSelect.selectedCount;

    if (count == 0) return;

    // 1. Dialogo di conferma
    final confirm = await DialogUtils.showConfirmDialog(
      context,
      title: "Eliminazione ${count == 1 ? 'singola' : 'multipla'}",
      content:
          "Vuoi eliminare $count ${count == 1 ? 'spesa selezionata' : 'spese selezionate'}?",
      confirmText: "Elimina",
      cancelText: "Annulla",
    );

    if (confirm != true) return;
    if (!mounted) return;

    // 2. Esecuzione tramite Provider
    final deletedItems = await multiSelect.deleteSelectedExpenses();

    if (!mounted) return;

    // 3. SnackBar con Undo
    SnackbarUtils.show(
      context: context,
      title: count == 1 ? "Eliminata!" : "Eliminate!",
      message:
          "$count ${count == 1 ? 'spesa eliminata' : 'spese eliminate'} con successo.",
      deletedItem: deletedItems,
      // La cancellazione reale è già avvenuta nel provider
      onDelete: (_) {},
      // Ripristino
      onRestore: (_) async {
        await multiSelect.restoreExpenses(deletedItems);
      },
    );
  }
}
