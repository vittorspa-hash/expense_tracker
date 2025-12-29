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
/// DESCRIZIONE: Widget principale per il contenuto della Home Page.
/// Gestisce la visualizzazione della lista delle spese utilizzando un approccio a "Slivers"
/// per supportare header flottanti. Include la logica di ricerca locale,
/// l'ordinamento, il pull-to-refresh e le interazioni sulle singole tile (swipe, selezione).

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
    // --- GESTIONE STATO E FILTRAGGIO ---
    // Utilizza Consumer2 per accedere sia alle spese che allo stato della selezione multipla.
    // Esegue un filtro locale sulla lista in base alla query di ricerca inserita.
    // 
    return Consumer2<MultiSelectProvider, ExpenseProvider>(
      builder: (context, multiSelect, expenseProvider, child) {
        
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

          // --- PULL TO REFRESH ---
          // Widget che avvolge la scroll view per permettere l'aggiornamento manuale dei dati.
          child: RefreshIndicator(
            color: AppColors.primary,
            onRefresh: onRefreshExpenses,

            child: SafeArea(
              top: false,
              child: CustomScrollView(
                slivers: [
                  // --- HEADER PERSISTENTE (RICERCA & ORDINAMENTO) ---
                  // Un header che rimane visibile o si nasconde parzialmente durante lo scroll.
                  // Contiene la barra di ricerca e il pulsante per il sorting.
                  // 
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
                            // Input Ricerca
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

                            // Pulsante Ordinamento (Apre BottomSheet)
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

                  // --- LISTA SPESE (SLIVER) ---
                  // Renderizza dinamicamente le card delle spese.
                  // Utilizza SliverList per performance ottimizzate su lunghe liste.
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

                        // --- INTERAZIONE SWIPE-TO-DELETE ---
                        // Gestisce l'eliminazione tramite trascinamento laterale.
                        // Disabilitato se è attiva la modalità selezione multipla.
                        // 
                        return Dismissible(
                          key: Key(expense.uuid),

                          direction: isSelectionMode
                              ? DismissDirection.none
                              : DismissDirection.endToStart,

                          // Dialogo di conferma pre-eliminazione
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

                          // Background visivo durante lo swipe (Rosso + Icona)
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

                          // Esecuzione eliminazione e SnackBar per Undo
                          onDismissed: (_) {
                            SnackbarUtils.show(
                              context: context,
                              title: "Eliminata!",
                              message: "Spesa eliminata con successo.",
                              deletedItem: expense,
                              onDelete: (exp) =>
                                  expenseProvider.deleteExpenses([exp]),
                              onRestore: (exp) => expenseProvider.restoreExpenses([exp]),
                            );
                          },

                          // Componente visuale della singola spesa
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

// --- DELEGATE PER HEADER ---
// Classe di utilità necessaria per SliverPersistentHeader.
// Definisce le dimensioni minime e massime del componente flottante.
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
  bool shouldRebuild(covariant SearchHeaderDelegate oldDelegate) {
    return oldDelegate.child != child; 
  }
}