import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:expense_tracker/providers/multi_select_provider.dart';
import 'package:expense_tracker/providers/expense_provider.dart';
import 'package:expense_tracker/utils/dialogs/dialog_utils.dart';
import 'package:expense_tracker/utils/snackbar_utils.dart';
import 'package:expense_tracker/theme/app_colors.dart';
import 'package:expense_tracker/components/shared/expense_tile.dart';

/// FILE: home_content_list.dart
/// DESCRIZIONE: Componente principale per la visualizzazione della lista spese.
/// Gestisce il layout scrollabile (Slivers) includendo una barra di ricerca "sticky",
/// il filtraggio locale dei dati, la logica di swipe-to-delete e l'interazione
/// con il MultiSelectProvider per la selezione multipla.

class HomeContentList extends StatelessWidget {
  final bool isDark;
  final TextEditingController searchController;
  final String searchQuery;
  final String sortCriteria;
  final ValueChanged<String> onSortChanged;
  final Future<void> Function() onRefreshExpenses;

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
        // --- FILTRO DATI LOCALE ---
        // Filtra la lista proveniente dal provider in base alla query di ricerca corrente.
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

          // --- GESTIONE SCROLL & REFRESH ---
          // Struttura a Sliver per gestire header persistenti e liste performanti.
          child: RefreshIndicator(
            backgroundColor: isDark
                ? AppColors.backgroundDark
                : AppColors.backgroundLight,
            color: AppColors.primary,
            onRefresh: onRefreshExpenses,

            child: SafeArea(
              top: false,
              child: CustomScrollView(
                slivers: [
                  // --- HEADER DI RICERCA (STICKY) ---
                  // Mantiene la barra di ricerca visibile durante lo scroll.
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
                            // Campo di input per la ricerca testuale
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
                                  cursorColor: AppColors.primary,
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

                            // Pulsante per aprire il menu di ordinamento
                            GestureDetector(
                              onTap: () async {
                                final selected =
                                    await DialogUtils.showSortSheet(
                                      context,
                                      isDark: isDark,
                                      title: "Ordina spese",
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

                  // --- LISTA SPESE ---
                  // Genera la lista degli elementi filtrati. Ogni elemento è avvolto
                  // in un Dismissible per permettere l'eliminazione rapida.
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
                          direction: isSelectionMode
                              ? DismissDirection.none
                              : DismissDirection.endToStart,

                          // --- LOGICA DISMISS ---
                          // Gestisce il flusso di eliminazione: Conferma UI -> Chiamata Provider ->
                          // Check Errori -> Feedback Visivo. Blocca l'animazione se c'è errore.
                          confirmDismiss: (_) async {
                            if (isSelectionMode) return false;

                            // 1. Dialogo di conferma
                            final confirm = await DialogUtils.showConfirmDialog(
                              context,
                              title: "Conferma eliminazione",
                              content: "Vuoi eliminare la spesa selezionata?",
                              confirmText: "Elimina",
                              cancelText: "Annulla",
                            );

                            if (confirm != true) return false;

                            // 2. Operazione asincrona
                            await expenseProvider.deleteExpenses([expense]);

                            // 3. Verifica errori
                            if (expenseProvider.errorMessage != null) {
                              return false;
                            }

                            // 4. Feedback successo (Snackbar)
                            if (context.mounted) {
                              SnackbarUtils.show(
                                context: context,
                                title: "Eliminata!",
                                message: "Spesa eliminata con successo.",
                                deletedItem: expense,
                                onDelete: (_) {},
                                onRestore: (exp) =>
                                    expenseProvider.restoreExpenses([exp]),
                              );
                            }

                            return true;
                          },

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

                          onDismissed: (_) {},

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

// --- DELEGATE HEADER ---
// Classe di utilità per gestire il rendering dell'header persistente all'interno della CustomScrollView.
class SearchHeaderDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;
  const SearchHeaderDelegate({required this.child});

  @override
  double get minExtent => 86.h;
  @override
  double get maxExtent => 86.h;
  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) => child;
  @override
  bool shouldRebuild(covariant SearchHeaderDelegate oldDelegate) =>
      oldDelegate.child != child;
}
