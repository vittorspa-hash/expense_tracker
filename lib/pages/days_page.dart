import 'package:expense_tracker/components/report/report_empty_state.dart';
import 'package:expense_tracker/components/report/report_section_header.dart';
import 'package:expense_tracker/components/report/report_total_card.dart';
import 'package:expense_tracker/components/shared/custom_appbar.dart';
import 'package:expense_tracker/providers/multi_select_provider.dart';
import 'package:expense_tracker/utils/expense_action_handler.dart';
import 'package:expense_tracker/utils/fade_animation_mixin.dart';
import 'package:expense_tracker/utils/report_date_utils.dart';
import 'package:expense_tracker/utils/snackbar_utils.dart';
import 'package:expense_tracker/utils/dialogs/dialog_utils.dart';
import 'package:expense_tracker/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:expense_tracker/providers/expense_provider.dart';
import 'package:expense_tracker/components/shared/expense_tile.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// FILE: days_page.dart
/// DESCRIZIONE: Pagina di dettaglio giornaliero (View).
/// Mostra l'elenco delle spese per un giorno specifico. Permette di selezionare
/// elementi multipli (MultiSelect) per l'eliminazione batch o di eliminare
/// singole spese tramite swipe (Dismissible).

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

  // --- UTILITY UI ---
  // Mostra una SnackBar di errore generica in caso di problemi (es. backend offline).
  void _showErrorSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: TextStyle(color: AppColors.textLight)),
        backgroundColor: AppColors.snackBar,
        behavior: SnackBarBehavior.floating,
        action: SnackBarAction(
          label: 'OK',
          textColor: AppColors.textLight,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final date = DateTime(widget.year, widget.month, widget.day);
    final dateLabel = ReportDateUtils.formatDateItaliano(date);
    final dayOfWeek = ReportDateUtils.getDayOfWeek(date);

    return Consumer2<ExpenseProvider, MultiSelectProvider>(
      builder: (context, expenseProvider, multiSelect, child) {
        // --- GESTIONE ERRORI ---
        // Ascolta cambiamenti nello stato degli errori del provider e notifica l'utente.
        // Pulisce l'errore subito dopo per evitare loop di visualizzazione.
        if (expenseProvider.errorMessage != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _showErrorSnackBar(context, expenseProvider.errorMessage!);
            expenseProvider.clearError();
          });
        }

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
                  onDeleteSelected: () =>
                      ExpenseActionHandler.handleDeleteSelected(context),
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

  // --- CORPO PAGINA ---
  // Costruisce la lista o lo stato vuoto se non ci sono spese.
  // Integra animazioni di fade-in per un'esperienza utente più fluida.
  Widget _buildBody(
    BuildContext context,
    List<dynamic> expensesList,
    bool isSelectionMode,
    MultiSelectProvider multiSelect,
    ExpenseProvider expenseprovider,
    bool isDark,
  ) {
    if (expensesList.isEmpty) {
      return buildWithFadeAnimation(
        const ReportEmptyState(
          title: "Nessuna spesa in questo giorno",
          subtitle: "Le spese che aggiungi appariranno qui",
          icon: Icons.receipt_long_rounded,
          useCircleBackground: true,
        ),
      );
    }

    final totalDay = expensesList.fold<double>(
      0.0,
      (sum, expense) => sum + expense.value,
    );

    return buildWithFadeAnimation(
      Column(
        children: [
          ReportTotalCard(
            label: "Totale giornata",
            totalAmount: totalDay,
            icon: Icons.receipt_rounded,
            itemCount: expensesList.length,
            itemLabel: expensesList.length == 1 ? "spesa" : "spese",
          ),

          const ReportSectionHeader(title: "Tutte le spese"),

          SizedBox(height: 12.h),

          Expanded(
            child: RefreshIndicator(
              backgroundColor: isDark
                  ? AppColors.backgroundDark
                  : AppColors.backgroundLight,
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

                    // --- LOGICA DISMISS ---
                    // Gestisce l'eliminazione via swipe. Richiede conferma, esegue l'azione
                    // sul Provider e mostra una Snackbar con opzione Undo.
                    // Se l'eliminazione fallisce, l'elemento torna al suo posto.
                    confirmDismiss: (_) async {
                      if (isSelectionMode) return false;

                      // 1. Dialogo conferma
                      final confirm = await DialogUtils.showConfirmDialog(
                        context,
                        title: "Conferma eliminazione",
                        content: "Vuoi eliminare la spesa selezionata?",
                        confirmText: "Elimina",
                        cancelText: "Annulla",
                      );

                      if (confirm != true) return false;

                      // 2. Esecuzione DB
                      await expenseprovider.deleteExpenses([expense]);

                      // 3. Controllo Esito
                      if (expenseprovider.errorMessage != null) {
                        return false;
                      }

                      // 4. Feedback Utente
                      if (context.mounted) {
                        SnackbarUtils.show(
                          context: context,
                          title: "Eliminata!",
                          message: "Spesa eliminata con successo.",
                          deletedItem: expense,
                          onDelete: (_) {},
                          onRestore: (exp) =>
                              expenseprovider.restoreExpenses([exp]),
                        );
                      }

                      return true;
                    },

                    background: _buildDismissibleBackground(),

                    onDismissed: (_) {},

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
}
