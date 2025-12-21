// home_content_list.dart
// -----------------------------------------------------------------------------
// 📄 LISTA CONTENUTI HOME – RICERCA, ORDINAMENTO, LISTA SPESE, MULTISELECT
//
// Questo widget costruisce il corpo principale della Home Page:
// ✔️ Barra di ricerca flottante con SliverPersistentHeader
// ✔️ Ordinamento tramite bottom sheet (DialogUtils.showSortSheet)
// ✔️ Integrazione con RefreshIndicator per pull-to-refresh
// ✔️ Lista spese reattiva (Consumer) con filtro per descrizione
// ✔️ Supporto al MultiSelectProvider (selezione multipla)
// ✔️ Swipe-to-delete con snackbar di undo
//
// L'intera UI si adatta automaticamente a Dark Mode / Light Mode.
// -----------------------------------------------------------------------------

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

import 'package:expense_tracker/providers/multi_select_provider.dart';
import 'package:expense_tracker/providers/expense_provider.dart';
import 'package:expense_tracker/utils/dialogs/dialog_utils.dart';
import 'package:expense_tracker/utils/snackbar_utils.dart';
import 'package:expense_tracker/theme/app_colors.dart';
import 'package:expense_tracker/components/shared/expense_tile.dart';

class HomeContentList extends StatelessWidget {
  final bool isDark; // 🌙 Tema attuale (dark / light)
  final TextEditingController searchController; // 🔍 Controller barra di ricerca
  final String searchQuery; // 🔎 Testo filtraggio dinamico
  final String sortCriteria; // 🔽 Criterio di ordinamento selezionato
  final ValueChanged<String> onSortChanged; // 📊 Callback cambio ordinamento
  final Future<void> Function() onRefreshExpenses; // 🔄 Callback refresh spese

  const HomeContentList({
    super.key,
    required this.isDark,
    required this.searchController,
    required this.searchQuery,
    required this.sortCriteria,
    required this.onSortChanged,
    required this.onRefreshExpenses,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer2<MultiSelectProvider, ExpenseProvider>(
      builder: (context, multiSelect, expenseProvider, child) {
        // -----------------------------------------------------------------------
        // 🔍 FILTRAGGIO LISTA SPESE
        // -----------------------------------------------------------------------
        final filteredExpenses = expenseProvider.expenses.where((expense) {
          final desc = expense.description?.toLowerCase() ?? "";
          return desc.contains(searchQuery.toLowerCase());
        }).toList();

        final isSelectionMode = multiSelect.isSelectionMode;

        return Container(
          decoration: BoxDecoration(
            color: isDark
                ? AppColors.backgroundDark
                : AppColors.backgroundLight,
          ),

          // ---------------------------------------------------------------------
          // 🔄 REFRESH INDICATOR (Pull to refresh)
          // ---------------------------------------------------------------------
          child: RefreshIndicator(
            color: AppColors.primary,
            onRefresh: onRefreshExpenses,

            child: SafeArea(
              top: false,
              child: CustomScrollView(
                slivers: [
                  // -----------------------------------------------------------------
                  // 🔍 HEADER DI RICERCA FLOTANTE (SliverPersistentHeader)
                  // -----------------------------------------------------------------
                  SliverPersistentHeader(
                    floating: true,
                    delegate: SearchHeaderDelegate(
                      child: Container(
                        decoration: BoxDecoration(
                          color: isDark
                              ? AppColors.backgroundDark
                              : AppColors.backgroundLight,
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.shadow.withValues(alpha: 0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        padding: EdgeInsets.fromLTRB(20.w, 20.h, 20.w, 16.h),

                        child: Row(
                          children: [
                            // -----------------------------------------------------
                            // 🔍 BARRA DI RICERCA
                            // -----------------------------------------------------
                            Expanded(
                              child: Container(
                                height: 50.h,
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? AppColors.cardDark
                                      : AppColors.cardLight,
                                  borderRadius: BorderRadius.circular(16.r),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.shadow.withValues(
                                        alpha: isDark ? 0.3 : 0.08,
                                      ),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: TextField(
                                  controller: searchController,
                                  style: TextStyle(fontSize: 14.sp),
                                  decoration: InputDecoration(
                                    hintText: "Cerca per descrizione...",
                                    hintStyle: TextStyle(
                                      fontSize: 14.sp,
                                      color: isDark
                                          ? AppColors.greyDark
                                          : AppColors.greyLight,
                                    ),
                                    prefixIcon: Icon(
                                      Icons.search_rounded,
                                      size: 22.sp,
                                      color: isDark
                                          ? AppColors.greyDark
                                          : AppColors.greyLight,
                                    ),
                                    filled: false,
                                    border: InputBorder.none,
                                    contentPadding: EdgeInsets.symmetric(
                                      horizontal: 16.w,
                                      vertical: 14.h,
                                    ),
                                  ),
                                ),
                              ),
                            ),

                            SizedBox(width: 12.w),

                            // -----------------------------------------------------
                            // 🔽 BOTTONE ORDINAMENTO (Sheet Opzioni)
                            // -----------------------------------------------------
                            GestureDetector(
                              onTap: () async {
                                final selected =
                                    await DialogUtils.showSortSheet(
                                      context,
                                      isDark: isDark,
                                      options: [
                                        {
                                          "title": "Data: più recente prima",
                                          "criteria": "date_desc",
                                        },
                                        {
                                          "title": "Data: più vecchia prima",
                                          "criteria": "date_asc",
                                        },
                                        {
                                          "title": "Importo: più alto prima",
                                          "criteria": "amount_desc",
                                        },
                                        {
                                          "title": "Importo: più basso prima",
                                          "criteria": "amount_asc",
                                        },
                                      ],
                                    );

                                // Aggiorna sorting e riordina lista
                                if (selected != null) {
                                  onSortChanged(selected);
                                  expenseProvider.sortBy(selected);
                                }
                              },
                              child: Container(
                                width: 50.w,
                                height: 50.h,
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? AppColors.cardDark
                                      : AppColors.cardLight,
                                  borderRadius: BorderRadius.circular(16.r),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.shadow.withValues(
                                        alpha: isDark ? 0.3 : 0.08,
                                      ),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Icon(
                                  Icons.sort_rounded,
                                  size: 24.sp,
                                  color: isDark
                                      ? AppColors.greyDark
                                      : AppColors.greyLight,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // -----------------------------------------------------------------
                  // 📋 LISTA SPESE
                  // -----------------------------------------------------------------
                  SliverPadding(
                    padding: EdgeInsets.symmetric(
                      horizontal: 16.w,
                      vertical: 8.h,
                    ),
                    sliver: SliverList.separated(
                      itemCount: filteredExpenses.length,
                      separatorBuilder: (_, _) => SizedBox(height: 4.h),

                      itemBuilder: (context, index) {
                        final expense = filteredExpenses[index];
                        final isSelected = multiSelect.isSelected(expense.uuid);

                        return Dismissible(
                          key: Key(expense.uuid),

                          // Swipe-to-delete disabilitato in selection mode
                          direction: isSelectionMode
                              ? DismissDirection.none
                              : DismissDirection.endToStart,

                          // Conferma eliminazione
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

                          // Background swipe rosso con icona
                          background: Container(
                            margin: EdgeInsets.symmetric(vertical: 4.h),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  AppColors.delete.withValues(alpha: 0.8),
                                  AppColors.delete,
                                ],
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
                          ),

                          // Eliminazione con snackbar undo
                          onDismissed: (_) {
                            SnackbarUtils.show(
                              context: context,
                              title: "Eliminata!",
                              message: "Spesa eliminata con successo.",
                              deletedItem: expense,
                              onDelete: (exp) =>
                                  expenseProvider.deleteExpense(exp),
                              onRestore: (exp) => expenseProvider.createExpense(
                                value: exp.value,
                                description: exp.description,
                                date: exp.createdOn,
                              ),
                            );
                          },

                          // Tile spesa
                          child: ExpenseTile(
                            expense,
                            isSelectionMode: isSelectionMode,
                            isSelected: isSelected,
                            onLongPress: () => multiSelect.onLongPress(expense),
                            onSelectToggle: () =>
                                multiSelect.onToggleSelect(expense),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

// -----------------------------------------------------------------------------
// 📌 DELEGATE: HEADER RICERCA FISSATO (SliverPersistentHeader)
// -----------------------------------------------------------------------------
class SearchHeaderDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;
  const SearchHeaderDelegate({required this.child});

  @override
  double get minExtent => 86.h; // Altezza minima header

  @override
  double get maxExtent => 86.h; // Altezza massima header (fissa)

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) => child;

  @override
  bool shouldRebuild(covariant SearchHeaderDelegate oldDelegate) {
    return oldDelegate.child != child; // Ricostruisci solo se cambia widget
  }
}
