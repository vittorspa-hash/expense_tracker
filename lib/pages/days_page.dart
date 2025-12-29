import 'package:expense_tracker/components/report/total_card_widget.dart';
import 'package:expense_tracker/components/shared/custom_appbar.dart';
import 'package:expense_tracker/providers/multi_select_provider.dart';
import 'package:expense_tracker/utils/expense_action_handler.dart';
import 'package:expense_tracker/utils/fade_animation_mixin.dart';
import 'package:expense_tracker/utils/snackbar_utils.dart';
import 'package:expense_tracker/utils/dialogs/dialog_utils.dart';
import 'package:expense_tracker/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:expense_tracker/providers/expense_provider.dart';
import 'package:expense_tracker/components/shared/expense_tile.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// FILE: days_page.dart
/// DESCRIZIONE: Schermata di dettaglio giornaliero.
/// Mostra la lista delle spese di un giorno specifico.
/// Supporta due modalità di interazione:
/// 1. Navigazione/Swipe: Visualizzazione standard e swipe-to-delete.
/// 2. Selezione Multipla: Attivata da long-press per eliminazioni di gruppo.

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

  // --- LIFECYCLE ---
  // Inizializza l'animazione e resetta lo stato di selezione multipla
  // per evitare che selezioni precedenti rimangano attive entrando in questa pagina.
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

  // --- FORMATTAZIONE DATE ---
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

    // --- GESTIONE STATO COMBINATA ---
    // Utilizza Consumer2 per reagire sia ai cambiamenti delle spese (ExpenseProvider)
    // sia allo stato della selezione (MultiSelectProvider).
    return Consumer2<ExpenseProvider, MultiSelectProvider>(
      builder: (context, expenseProvider, multiSelect, child) {
        final expensesList = expenseProvider.expensesOfDay(
          widget.year,
          widget.month,
          widget.day,
        );

        final isSelectionMode = multiSelect.isSelectionMode;
        final selectedCount = multiSelect.selectedCount;

        return Scaffold(
          // --- APPBAR DINAMICA ---
          // Cambia aspetto e azioni in base alla modalità corrente (Normale vs Selezione).
          //
          appBar: isSelectionMode
              ? CustomAppBar(
                  title: "",
                  isDark: isDark,
                  isSelectionMode: true,
                  selectedCount: selectedCount,
                  totalCount: expensesList.length,
                  onCancelSelection: multiSelect.cancelSelection,
                  onDeleteSelected: () => ExpenseActionHandler.handleDeleteSelected(context),
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

  // --- COSTRUZIONE CORPO PAGINA ---
  Widget _buildBody(
    BuildContext context,
    List<dynamic> expensesList,
    bool isSelectionMode,
    MultiSelectProvider multiSelect,
    ExpenseProvider expenseprovider,
    bool isDark,
  ) {
    // Stato Vuoto
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
          // Card Totale Giorno
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

          // --- LISTA SPESE ---
          // Supporta RefreshIndicator e Swipe-to-delete.
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

                  // --- DISMISSIBLE (SWIPE) ---
                  // Abilitato solo se NON siamo in modalità selezione.
                  //
                  return Dismissible(
                    key: Key(expense.uuid),
                    direction: isSelectionMode
                        ? DismissDirection.none
                        : DismissDirection.endToStart,

                    // Conferma eliminazione singola
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

                    // Esecuzione eliminazione e SnackBar Undo
                    onDismissed: (_) {
                      SnackbarUtils.show(
                        context: context,
                        title: "Eliminata!",
                        message: "Spesa eliminata con successo.",
                        deletedItem: expense,
                        onDelete: (exp) => expenseprovider.deleteExpenses([exp]),
                        onRestore: (exp) => expenseprovider.restoreExpenses([exp]),
                      );
                    },

                    // Tile Spesa (Gestisce LongPress e Tap)
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

  // --- HELPER UI ---
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
}