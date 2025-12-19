// home_page.dart
import 'package:expense_tracker/components/home/home_content_list.dart';
import 'package:expense_tracker/components/home/home_header.dart';
import 'package:expense_tracker/components/shared/custom_appbar.dart';
import 'package:expense_tracker/providers/multi_select_provider.dart';
import 'package:expense_tracker/models/expense_model.dart';
import 'package:expense_tracker/utils/dialog_utils.dart';
import 'package:expense_tracker/providers/expense_provider.dart';
// 👇 Aggiungi questo import se vuoi caricare i dati profilo all'avvio della home
import 'package:expense_tracker/providers/profile_provider.dart';
import 'package:expense_tracker/pages/new_expense_page.dart';
import 'package:expense_tracker/theme/app_colors.dart';
import 'package:expense_tracker/utils/fade_animation_mixin.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

class HomePage extends StatefulWidget {
  static const route = "/home/page";
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with TickerProviderStateMixin, FadeAnimationMixin {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";
  String _sortCriteria = "date_desc";

  // ✂️ Rimosso: File? _localAvatar; (Gestito da ProfileProvider)

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

    // ✂️ Rimosso: _loadLocalAvatar();

    // Opzionale: Se non carichi il profilo nel main, caricalo qui.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProfileProvider>().loadLocalData();
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

  List<ExpenseModel> _getFilteredExpenses(ExpenseProvider expenseProvider) {
    final query = _searchQuery.toLowerCase();
    return expenseProvider.expenses.where((expense) {
      final desc = expense.description?.toLowerCase() ?? "";
      return desc.contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    // ✂️ Rimosso: final user = FirebaseAuth.instance.currentUser;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Consumer2<MultiSelectProvider, ExpenseProvider>(
      builder: (context, multiSelect, expenseProvider, child) {
        final isSelectionMode = multiSelect.isSelectionMode;
        final selectedCount = multiSelect.selectedCount;
        final filteredExpenses = _getFilteredExpenses(expenseProvider);

        return Scaffold(
          // ---------------------------------------------------------------------
          // 🟥 APPBAR
          // ---------------------------------------------------------------------
          appBar: isSelectionMode
              ? CustomAppBar(
                  title: "",
                  isDark: isDark,
                  isSelectionMode: true,
                  selectedCount: selectedCount,
                  onCancelSelection: multiSelect.cancelSelection,
                  onDeleteSelected: () => multiSelect.deleteSelected(context),
                  onSelectAll: () => multiSelect.selectAll(filteredExpenses),
                  onDeselectAll: () => multiSelect.deselectAll(),
                  totalCount: filteredExpenses.length,
                )
              : null,

          body: Column(
            children: [
              // ---------------------------------------------------------------
              // 👤 HEADER
              // ---------------------------------------------------------------
              // 👇 Header semplificato: legge tutto dai Provider interni
              HomeHeader(
                fadeAnimation: fadeAnimation,
                isDark: isDark,
                onTapProfile: () => _showProfileSheet(context),
              ),

              // ---------------------------------------------------------------
              // 📃 LISTA SPESE
              // ---------------------------------------------------------------
              Expanded(
                child: HomeContentList(
                  isDark: isDark,
                  searchController: _searchController,
                  searchQuery: _searchQuery,
                  sortCriteria: _sortCriteria,
                  onSortChanged: (newCriteria) {
                    setState(() {
                      _sortCriteria = newCriteria;
                    });
                  },
                  onRefreshExpenses: _refreshExpenses,
                ),
              ),
            ],
          ),

          // ---------------------------------------------------------------------
          // ➕ FAB
          // ---------------------------------------------------------------------
          floatingActionButton: !isSelectionMode
              ? Container(
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(20.r),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.4),
                        blurRadius: 15,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: FloatingActionButton.extended(
                    heroTag: null,
                    elevation: 0,
                    backgroundColor: Colors.transparent,
                    onPressed: () =>
                        Navigator.pushNamed(context, NewExpensePage.route),
                    label: Text(
                      "Nuova spesa",
                      style: TextStyle(
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                    ),
                    icon: Icon(Icons.add_rounded, size: 20.sp),
                    foregroundColor: isDark
                        ? AppColors.textDark
                        : AppColors.textLight,
                  ),
                )
              : null,
        );
      },
    );
  }

  // ✂️ Rimosso: _loadLocalAvatar (Logica spostata nel Provider)

  Future<void> _refreshExpenses() async {
    final multiSelect = context.read<MultiSelectProvider>();
    final expenseProvider = context.read<ExpenseProvider>();

    multiSelect.cancelSelection();
    await expenseProvider.initialise();
    if (_sortCriteria.isNotEmpty) {
      expenseProvider.sortBy(_sortCriteria);
    }
  }

  // -----------------------------------------------------------------------------
  // 👤 MOSTRA MODALE PROFILO
  // -----------------------------------------------------------------------------
  Future<void> _showProfileSheet(BuildContext context) async {
    // 👇 Ora chiamiamo il dialog senza passare parametri,
    // perché DialogProfile userà i context.read/watch sui provider.
    await DialogUtils.showProfileSheet(context);
  }
}
