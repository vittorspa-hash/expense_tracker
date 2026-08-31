import 'package:expense_tracker/config/di/riverpod_providers.dart';
import 'package:expense_tracker/l10n/app_localizations.dart';
import 'package:expense_tracker/notifiers/expense_notifier.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:expense_tracker/utils/dialogs/dialog_utils.dart';
import 'package:expense_tracker/utils/snackbar_utils.dart';
import 'package:expense_tracker/config/app_colors.dart';
import 'package:expense_tracker/components/shared/expense_tile.dart';

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
    final loc = AppLocalizations.of(context)!;

    // --- ASCOLTO STATI GLOBALI ---
    final expenseState =
        ref.watch(expenseNotifierProvider).value ?? ExpenseState();
    final multiSelectState = ref.watch(multiSelectNotifierProvider);

    // --- FILTRO DATI LOCALE ---
    // Filtra la lista proveniente dal provider in base alla query di ricerca corrente.
    final filteredExpenses = expenseState.expenses.where((expense) {
      final desc = expense.description?.toLowerCase() ?? "";
      return desc.contains(searchQuery.toLowerCase());
    }).toList();

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
            // Mantiene la barra di ricerca visibile durante lo scroll.
            SliverPersistentHeader(
              floating: true,
              delegate: SearchHeaderDelegate(
                child: Container(
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppColors.backgroundDark
                        : AppColors.backgroundLight,
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
                              hintText: loc.searchHint,
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
                          final selected = await DialogUtils.showSortSheet(
                            context,
                            isDark: isDark,
                            title: loc.sortTitle,
                            options: [
                              {
                                "title": loc.sortDateNewest,
                                "criteria": "date_desc",
                              },
                              {
                                "title": loc.sortDateOldest,
                                "criteria": "date_asc",
                              },
                              {
                                "title": loc.sortAmountHighest,
                                "criteria": "amount_desc",
                              },
                              {
                                "title": loc.sortAmountLowest,
                                "criteria": "amount_asc",
                              },
                            ],
                          );

                          if (selected != null) {
                            onSortChanged(selected);
                            ref
                                .read(expenseNotifierProvider.notifier)
                                .sortBy(selected);
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

            // --- LISTA SPESE / STATO VUOTO ---
            // Se la lista filtrata è vuota, mostra uno stato vuoto contestuale
            if (filteredExpenses.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 40.w),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        SizedBox(height: 30.h),
                        Icon(
                          searchQuery.isNotEmpty
                              ? Icons.search_off_rounded
                              : Icons.receipt_long_outlined,
                          size: 56.sp,
                          color: isDark
                              ? AppColors.greyDark
                              : AppColors.greyLight,
                        ),
                        SizedBox(height: 16.h),
                        Text(
                          searchQuery.isNotEmpty
                              ? loc.emptySearchTitle
                              : loc.emptyExpensesTitle,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w600,
                            color: isDark
                                ? AppColors.greyDark
                                : AppColors.greyLight,
                          ),
                        ),
                        SizedBox(height: 8.h),
                        Text(
                          searchQuery.isNotEmpty
                              ? loc.emptySearchSubtitle
                              : loc.emptyExpensesSubtitle,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 13.sp,
                            color:
                                (isDark
                                        ? AppColors.greyDark
                                        : AppColors.greyLight)
                                    .withValues(alpha: 0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
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

                    return Dismissible(
                      key: Key(expense.uuid),
                      direction: isSelectionMode
                          ? DismissDirection.none
                          : DismissDirection.endToStart,

                      // --- LOGICA DISMISS (SWIPE TO DELETE) ---
                      // Gestisce il flusso: Conferma UI -> Chiamata Provider -> Check Errori -> Feedback Visivo.
                      confirmDismiss: (_) async {
                        if (isSelectionMode) return false;

                        // 1. Dialogo di conferma rimozione
                        final confirm = await DialogUtils.showConfirmDialog(
                          context,
                          title: loc.deleteDialogTitleSingle,
                          content: loc.deleteConfirmMessageSwipe,
                          confirmText: loc.delete,
                          cancelText: loc.cancel,
                        );

                        if (confirm != true) return false;

                        // 2. Operazione asincrona di cancellazione
                        await ref
                            .read(expenseNotifierProvider.notifier)
                            .deleteExpenses([expense]);

                        // 3. Verifica fallimenti nello stato globale
                        final currentState =
                            ref.read(expenseNotifierProvider).value ??
                            ExpenseState();
                        if (currentState.errorMessage != null) return false;

                        // 4. Feedback di successo con opzione Undo
                        if (context.mounted) {
                          SnackbarUtils.show(
                            context: context,
                            title: loc.deletedTitleSingle,
                            message: loc.deleteSuccessMessageSwipe,
                            undo: loc.undo,
                            deletedItem: expense,
                            navBar: true,
                            onDelete: (_) {},
                            onRestore: (exp) => ref
                                .read(expenseNotifierProvider.notifier)
                                .restoreExpenses([exp], loc),
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
                        onLongPress: () => ref
                            .read(multiSelectNotifierProvider.notifier)
                            .onLongPress(expense),
                        onSelectToggle: () => ref
                            .read(multiSelectNotifierProvider.notifier)
                            .onToggleSelect(expense),
                        onReturn: onReturn,
                      ),
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
/// Classe di utilità per gestire il rendering e le dimensioni dell'header persistente (barra di ricerca)
/// all'interno del flusso CustomScrollView.
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
