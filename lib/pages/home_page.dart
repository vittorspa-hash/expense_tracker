import 'package:expense_tracker/components/home/home_content_list.dart';
import 'package:expense_tracker/components/home/home_header.dart';
import 'package:expense_tracker/components/shared/custom_appbar.dart';
import 'package:expense_tracker/config/di/riverpod_providers.dart';
import 'package:expense_tracker/l10n/app_localizations.dart';
import 'package:expense_tracker/models/expense_model.dart';
import 'package:expense_tracker/utils/dialogs/dialog_utils.dart';
import 'package:expense_tracker/utils/expense_action_handler.dart';
import 'package:expense_tracker/pages/new_expense_page.dart';
import 'package:expense_tracker/config/app_colors.dart';
import 'package:expense_tracker/utils/fade_animation_mixin.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage>
    with TickerProviderStateMixin, FadeAnimationMixin {

  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";
  String _sortCriteria = "date_desc";
  late AnimationController _listAnimationController;

  @override
  TickerProvider get vsync => this;

  @override
  void initState() {
    super.initState();

    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text;
      });
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        // ref è disponibile direttamente in ConsumerState
        ref.read(profileNotifierProvider.notifier).loadLocalData();
        final l10n = AppLocalizations.of(context);
        if (l10n != null) {
          ref.read(notificationNotifierProvider.notifier).rescheduleNotifications(l10n);
        }
      }
    });

    initFadeAnimation();
    _listAnimationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _listAnimationController.forward();
  }

  @override
  void dispose() {
    _searchController.dispose();
    disposeFadeAnimation();
    _listAnimationController.dispose();
    super.dispose();
  }

  List<ExpenseModel> _getFilteredExpenses(List<ExpenseModel> expenses) {
    final query = _searchQuery.toLowerCase();
    return expenses.where((expense) {
      final desc = expense.description?.toLowerCase() ?? "";
      return desc.contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final loc = AppLocalizations.of(context)!;

    // ref.watch nel build — sostituisce Consumer2
    final multiSelectState = ref.watch(multiSelectNotifierProvider);
    final expenseState = ref.watch(expenseNotifierProvider);

    // Gestione errori UI
    if (expenseState.errorMessage != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showErrorSnackBar(context, expenseState.errorMessage!);
        ref.read(expenseNotifierProvider.notifier).clearError();
      });
    }

    final isSelectionMode = multiSelectState.isSelectionMode;
    final selectedCount = multiSelectState.selectedCount;
    final filteredExpenses = _getFilteredExpenses(expenseState.expenses);
    final isLoading = expenseState.isLoading;

    return Scaffold(
      appBar: isSelectionMode
          ? CustomAppBar(
              appBarBackgroundColor: AppColors.primary,
              appBarTextColor: isDark ? AppColors.textDark : AppColors.textLight,
              title: "",
              isDark: isDark,
              isSelectionMode: true,
              selectedCount: selectedCount,
              onCancelSelection: () => ref.read(multiSelectNotifierProvider.notifier).deselectAll(),
              onDeleteSelected: () => ExpenseActionHandler.handleDeleteSelected(context, ref),
              onSelectAll: () => ref.read(multiSelectNotifierProvider.notifier).selectAll(filteredExpenses),
              onDeselectAll: () => ref.read(multiSelectNotifierProvider.notifier).deselectAll(),
              totalCount: filteredExpenses.length,
            )
          : null,

      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              color: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
            ),
            child: Column(
              children: [
                HomeHeader(
                  fadeAnimation: fadeAnimation,
                  isDark: isDark,
                  onTapProfile: () => _showProfileSheet(context),
                  onReturn: _clearSearch,
                ),
                SizedBox(height: 6.h),
                Expanded(
                  child: HomeContentList(
                    isDark: isDark,
                    searchController: _searchController,
                    searchQuery: _searchQuery,
                    sortCriteria: _sortCriteria,
                    onSortChanged: (newCriteria) {
                      setState(() => _sortCriteria = newCriteria);
                    },
                    onRefreshExpenses: _refreshExpenses,
                    onReturn: _clearSearch,
                  ),
                ),
              ],
            ),
          ),
          if (isLoading)
            Container(
              color: AppColors.backgroundDark.withValues(alpha: 0.3),
              child: Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
            ),
        ],
      ),

      floatingActionButton: !isSelectionMode && !isLoading
          ? Container(
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(20.r),
              ),
              child: FloatingActionButton.extended(
                heroTag: null,
                elevation: 0,
                backgroundColor: Colors.transparent,
                onPressed: () async {
                  await Navigator.pushNamed(context, NewExpensePage.route);
                  if (mounted) _clearSearch();
                },
                label: Text(
                  loc.newExpense,
                  style: TextStyle(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
                icon: Icon(Icons.add_rounded, size: 20.sp),
                foregroundColor: isDark ? AppColors.textDark : AppColors.textLight,
              ),
            )
          : null,
    );
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() => _searchQuery = "");
  }

  void _showErrorSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: TextStyle(color: AppColors.textLight)),
        backgroundColor: AppColors.snackBar,
        behavior: SnackBarBehavior.floating,
        action: SnackBarAction(
          label: AppLocalizations.of(context)!.ok,
          textColor: AppColors.textLight,
          onPressed: () => ScaffoldMessenger.of(context).hideCurrentSnackBar(),
        ),
      ),
    );
  }

  Future<void> _refreshExpenses() async {
    ref.read(multiSelectNotifierProvider.notifier).deselectAll();
    _clearSearch();
    await ref.read(expenseNotifierProvider.notifier).initialise();
    if (_sortCriteria.isNotEmpty) {
      ref.read(expenseNotifierProvider.notifier).sortBy(_sortCriteria);
    }
  }

  Future<void> _showProfileSheet(BuildContext context) async {
    await DialogUtils.showProfileSheet(context, ref);
    _clearSearch();
  }
}