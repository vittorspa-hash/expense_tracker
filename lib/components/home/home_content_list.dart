import 'package:expense_tracker/components/home/expenses_empty_state.dart';
import 'package:expense_tracker/components/home/search_and_sort_bar.dart';
import 'package:expense_tracker/components/shared/swipe_to_delete_expense_tile.dart';
import 'package:expense_tracker/config/di/riverpod_providers.dart';
import 'package:expense_tracker/utils/expense_calculator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:expense_tracker/config/app_colors.dart';

/// FILE: home_content_list.dart
/// DESCRIZIONE: Componente principale per la visualizzazione della lista spese.
/// Gestisce il layout scrollabile (Slivers) includendo una barra di ricerca "sticky",
/// il filtraggio locale dei dati, la logica di swipe-to-delete e l'interazione
/// con il MultiSelectProvider per la selezione multipla.

class HomeContentList extends ConsumerWidget {
  final bool isDark;
  final TextEditingController searchController;
  final String searchQuery;
  final String sortCriteria;
  final ValueChanged<String> onSortChanged;
  final Future<void> Function() onRefreshExpenses;
  final VoidCallback onReturn;

  const HomeContentList({
    super.key,
    required this.isDark,
    required this.searchController,
    required this.searchQuery,
    required this.sortCriteria,
    required this.onSortChanged,
    required this.onRefreshExpenses,
    required this.onReturn,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {

    // --- ASCOLTO STATI GLOBALI ---
    // select mirato: si ricostruisce solo quando cambia la lista spese,
    // non quando cambiano isLoading/errorMessage (già gestiti altrove).
    final expenses = ref.watch(
      expenseNotifierProvider.select((s) => s.value?.expenses ?? const []),
    );
    final multiSelectState = ref.watch(multiSelectNotifierProvider);

    // --- FILTRO DATI LOCALE ---
    // Logica condivisa con HomePage (selectAll/totalCount nell'AppBar).
    final filteredExpenses = ExpenseCalculator.filterByQuery(
      expenses,
      searchQuery,
    );

    final isSelectionMode = multiSelectState.isSelectionMode;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      ),

      // --- GESTIONE SCROLL & REFRESH ---
      // Struttura a Sliver per gestire header persistenti e liste performanti.
      child: RefreshIndicator(
        backgroundColor: isDark
            ? AppColors.backgroundDark
            : AppColors.backgroundLight,
        color: AppColors.primary,
        onRefresh: onRefreshExpenses,
        child: CustomScrollView(
          slivers: [
            // --- HEADER DI RICERCA (STICKY) ---
            SliverPersistentHeader(
              floating: true,
              delegate: SearchHeaderDelegate(
                child: SearchAndSortBar(
                  isDark: isDark,
                  searchController: searchController,
                  onSortSelected: (criteria) {
                    onSortChanged(criteria);
                    ref.read(expenseNotifierProvider.notifier).sortBy(criteria);
                  },
                ),
              ),
            ),

            // --- LISTA SPESE / STATO VUOTO ---
            if (filteredExpenses.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: ExpensesEmptyState(
                  isDark: isDark,
                  isSearching: searchQuery.isNotEmpty,
                ),
              )
            else
              SliverPadding(
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                sliver: SliverList.separated(
                  itemCount: filteredExpenses.length,
                  separatorBuilder: (_, _) => SizedBox(height: 4.h),
                  itemBuilder: (context, index) {
                    final expense = filteredExpenses[index];
                    final isSelected = multiSelectState.isSelected(
                      expense.uuid,
                    );

                    return SwipeToDeleteExpenseTile(
                      expense: expense,
                      isSelectionMode: isSelectionMode,
                      isSelected: isSelected,
                      onLongPress: () => ref
                          .read(multiSelectNotifierProvider.notifier)
                          .onLongPress(expense),
                      onSelectToggle: () => ref
                          .read(multiSelectNotifierProvider.notifier)
                          .onToggleSelect(expense),
                      onReturn: onReturn,
                    );
                  },
                ),
              ),
            SliverToBoxAdapter(child: SizedBox(height: 180.h)),
          ],
        ),
      ),
    );
  }
}

// --- DELEGATE HEADER ---
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
  bool shouldRebuild(covariant SearchHeaderDelegate oldDelegate) => true;
}
