import 'package:expense_tracker/components/report/report_empty_state.dart';
import 'package:expense_tracker/components/report/report_section_header.dart';
import 'package:expense_tracker/components/report/report_total_card.dart';
import 'package:expense_tracker/components/shared/custom_appbar.dart';
import 'package:expense_tracker/config/di/riverpod_providers.dart';
import 'package:expense_tracker/l10n/app_localizations.dart';
import 'package:expense_tracker/notifiers/multi_select_notifier.dart';
import 'package:expense_tracker/utils/expense_action_handler.dart';
import 'package:expense_tracker/utils/fade_animation_mixin.dart';
import 'package:expense_tracker/utils/report_date_utils.dart';
import 'package:expense_tracker/utils/snackbar_utils.dart';
import 'package:expense_tracker/utils/dialogs/dialog_utils.dart';
import 'package:expense_tracker/config/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:expense_tracker/notifiers/expense_notifier.dart';
import 'package:expense_tracker/components/shared/expense_tile.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// FILE: days_page.dart
/// DESCRIZIONE: Pagina di dettaglio giornaliero dei report.
/// Mostra la lista analitica delle spese effettuate in una data specifica.
/// Supporta la selezione multipla (MultiSelect) per cancellazioni massive,
/// l'eliminazione a scorrimento (Dismissible) e i ripristini tramite Snackbar.

class DaysPage extends ConsumerStatefulWidget {
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
  ConsumerState<DaysPage> createState() => _DaysPageState();
}

class _DaysPageState extends ConsumerState<DaysPage>
    with SingleTickerProviderStateMixin, FadeAnimationMixin {
  // --- INIZIALIZZAZIONE ---
  @override
  TickerProvider get vsync => this;

  @override
  void initState() {
    super.initState();
    initFadeAnimation();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref.read(multiSelectNotifierProvider.notifier).deselectAll();
      }
    });
  }

  @override
  void dispose() {
    disposeFadeAnimation();
    super.dispose();
  }

  // --- NOTIFICHE ERRORI ---
  void _showErrorSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: TextStyle(color: AppColors.textLight)),
        backgroundColor: AppColors.snackBar,
        behavior: SnackBarBehavior.floating,
        action: SnackBarAction(
          label: AppLocalizations.of(context)!.ok,
          textColor: AppColors.textLight,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }

  // --- BUILD UI ---
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final date = DateTime(widget.year, widget.month, widget.day);

    final dateLabel = ReportDateUtils.formatDate(context, date);
    final dayOfWeek = ReportDateUtils.getDayOfWeek(context, date);

    final expenseState =
        ref.watch(expenseNotifierProvider).value ?? ExpenseState();
    final multiSelectState = ref.watch(multiSelectNotifierProvider);
    final expensesList = ref.watch(expensesOfDayProvider)(
      widget.year,
      widget.month,
      widget.day,
    );

    // Listener per la gestione degli errori asincroni a database
    ref.listen(expenseNotifierProvider.select((s) => s.value?.errorMessage), (
      previous,
      next,
    ) {
      if (next != null) {
        _showErrorSnackBar(context, next);
        ref.read(expenseNotifierProvider.notifier).clearError();
      }
    });

    final isSelectionMode = multiSelectState.isSelectionMode;

    return Scaffold(
      appBar: isSelectionMode
          ? CustomAppBar(
              appBarBackgroundColor: isDark
                  ? AppColors.backgroundDark
                  : AppColors.backgroundLight,
              appBarTextColor: AppColors.primary,
              title: "",
              isDark: isDark,
              isSelectionMode: true,
              selectedCount: multiSelectState.selectedCount,
              totalCount: expensesList.length,
              onCancelSelection: ref
                  .read(multiSelectNotifierProvider.notifier)
                  .deselectAll,
              onDeleteSelected: () =>
                  ExpenseActionHandler.handleDeleteSelected(context, ref),
              onSelectAll: () => ref
                  .read(multiSelectNotifierProvider.notifier)
                  .selectAll(expensesList),
              onDeselectAll: ref
                  .read(multiSelectNotifierProvider.notifier)
                  .deselectAll,
            )
          : CustomAppBar(
              title: dayOfWeek,
              subtitle: dateLabel,
              isDark: isDark,
              icon: Icons.calendar_today_rounded,
            ),
      body: Stack(
        children: [
          Container(
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
                multiSelectState,
                expenseState,
                isDark,
              ),
            ),
          ),

          // Schermata di blocco per caricamento/eliminazioni batch in corso
          if (expenseState.isLoading)
            Container(
              color: AppColors.backgroundDark.withValues(alpha: 0.3),
              child: Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
            ),
        ],
      ),
    );
  }

  // --- COMPONENTI INTERNI ---
  Widget _buildBody(
    BuildContext context,
    List<dynamic> expensesList,
    bool isSelectionMode,
    MultiSelectState multiSelectState,
    ExpenseState expenseState,
    bool isDark,
  ) {
    final loc = AppLocalizations.of(context)!;

    if (expensesList.isEmpty) {
      return buildWithFadeAnimation(
        ReportEmptyState(
          title: loc.noExpensesDayTitle,
          subtitle: loc.noExpensesSubtitle,
          icon: Icons.receipt_long_rounded,
          useCircleBackground: true,
        ),
      );
    }

    // Calcolo del valore aggregato convertito nella valuta corrente
    final totalDayAmount = expensesList.fold<double>(
      0.0,
      (sum, expense) => sum + expense.getValueIn(expenseState.appCurrency),
    );

    return buildWithFadeAnimation(
      Column(
        children: [
          ReportTotalCard(
            label: loc.totalDayLabel,
            totalAmount: totalDayAmount,
            icon: Icons.receipt_rounded,
            itemCount: expensesList.length,
            itemLabel: loc.expenseCountLabel(expensesList.length),
          ),

          ReportSectionHeader(title: loc.allExpenses),
          SizedBox(height: 12.h),

          Expanded(
            child: RefreshIndicator(
              backgroundColor: isDark
                  ? AppColors.backgroundDark
                  : AppColors.backgroundLight,
              color: AppColors.primary,
              onRefresh: () async {
                ref.read(multiSelectNotifierProvider.notifier).deselectAll();
                ref.invalidate(expenseNotifierProvider);
                await ref.read(expenseNotifierProvider.future);
              },
              child: ListView.separated(
                padding: EdgeInsets.fromLTRB(20.w, 0, 20.w, 20.h),
                itemCount: expensesList.length,
                separatorBuilder: (_, _) => SizedBox(height: 4.h),
                itemBuilder: (context, index) {
                  final expense = expensesList[index];
                  final isSelected = multiSelectState.selectedIds.contains(
                    expense.uuid,
                  );

                  return Dismissible(
                    key: Key(expense.uuid),
                    direction: isSelectionMode
                        ? DismissDirection.none
                        : DismissDirection.endToStart,
                    background: _buildDismissibleBackground(),
                    confirmDismiss: (_) async {
                      if (isSelectionMode) return false;

                      // Cache preventiva dei riferimenti asincroni
                      final expenseNotifier = ref.read(
                        expenseNotifierProvider.notifier,
                      );
                      final locCopy = loc;

                      final isConfirmed = await DialogUtils.showConfirmDialog(
                        context,
                        title: loc.deleteConfirmTitle,
                        content: loc.deleteConfirmMessageSwipe,
                        confirmText: loc.delete,
                        cancelText: loc.cancel,
                      );

                      if (isConfirmed != true) return false;

                      // Esecuzione eliminazione logica/fisica a database
                      await expenseNotifier.deleteExpenses([expense]);

                      // Annulla il dismiss se l'operazione ha riscontrato errori di persistenza
                      final currentState = ref.read(expenseNotifierProvider).value ?? ExpenseState();
                      if (currentState.errorMessage != null) return false;

                      if (context.mounted) {
                        SnackbarUtils.show(
                          context: context,
                          title: loc.deletedTitleSingle,
                          message: loc.deleteSuccessMessageSwipe,
                          undo: loc.undo,
                          deletedItem: expense,
                          onDelete: (_) {},
                          onRestore: (exp) =>
                              expenseNotifier.restoreExpenses([exp], locCopy),
                        );
                      }

                      return true;
                    },
                    child: ExpenseTile(
                      expense,
                      isSelectionMode: isSelectionMode,
                      isSelected: isSelected,
                      onLongPress: () => ref
                          .read(multiSelectNotifierProvider.notifier)
                          .onLongPress(expense),
                      onSelectToggle: () => ref
                          .read(multiSelectNotifierProvider.notifier)
                          .onToggleSelect(expense),
                      onReturn: () {},
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
      padding: EdgeInsets.only(right: 20.w),
      child: Icon(
        Icons.delete_rounded,
        color: AppColors.textLight,
        size: 28.sp,
      ),
    );
  }
}
