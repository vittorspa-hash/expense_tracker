import 'package:expense_tracker/components/home/home_content_list.dart';
import 'package:expense_tracker/components/home/home_header.dart';
import 'package:expense_tracker/components/shared/custom_appbar.dart';
import 'package:expense_tracker/l10n/app_localizations.dart';
import 'package:expense_tracker/providers/multi_select_provider.dart';
import 'package:expense_tracker/models/expense_model.dart';
import 'package:expense_tracker/utils/dialogs/dialog_utils.dart';
import 'package:expense_tracker/utils/expense_action_handler.dart';
import 'package:expense_tracker/providers/expense_provider.dart';
import 'package:expense_tracker/providers/profile_provider.dart';
import 'package:expense_tracker/pages/new_expense_page.dart';
import 'package:expense_tracker/theme/app_colors.dart';
import 'package:expense_tracker/utils/fade_animation_mixin.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

/// FILE: home_page.dart
/// DESCRIZIONE: Schermata principale (Dashboard) dell'applicazione.
/// Orchestra la visualizzazione del riepilogo (Header) e della lista spese.
/// Funge da "Hub" per la gestione degli errori globali provenienti dal Provider
/// e gestisce la navigazione verso la creazione di nuove spese o il profilo.

class HomePage extends StatefulWidget {
  static const route = "/home/page";
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with TickerProviderStateMixin, FadeAnimationMixin {
  
  // --- STATO E ANIMAZIONI ---
  // Controller per la barra di ricerca, per l'animazione della lista
  // e variabili di stato locale per filtri e ordinamento.
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";
  String _sortCriteria = "date_desc";

  late AnimationController _listAnimationController;

  @override
  TickerProvider get vsync => this;

  // --- INIZIALIZZAZIONE ---
  // Configura i listener, avvia le animazioni e richiede i dati del profilo
  // dopo il primo frame di rendering.
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
        context.read<ProfileProvider>().loadLocalData();
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

  // --- LOGICA FILTRO ---
  // Filtra localmente la lista delle spese in base alla query di ricerca inserita.
  List<ExpenseModel> _getFilteredExpenses(ExpenseProvider expenseProvider) {
    final query = _searchQuery.toLowerCase();
    return expenseProvider.expenses.where((expense) {
      final desc = expense.description?.toLowerCase() ?? "";
      return desc.contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final loc = AppLocalizations.of(context)!;

    return Consumer2<MultiSelectProvider, ExpenseProvider>(
      builder: (context, multiSelect, expenseProvider, child) {
        
        // --- GESTIONE ERRORI UI ---
        // Ascolta lo stato degli errori del Provider. Se presente, mostra una SnackBar
        // e resetta immediatamente l'errore per evitare loop di visualizzazione.
        // Utilizza addPostFrameCallback per non interferire con il ciclo di build corrente.
        if (expenseProvider.errorMessage != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _showErrorSnackBar(context, expenseProvider.errorMessage!);
            expenseProvider.clearError();
          });
        }

        final isSelectionMode = multiSelect.isSelectionMode;
        final selectedCount = multiSelect.selectedCount;
        final filteredExpenses = _getFilteredExpenses(expenseProvider);

        return Scaffold(
          appBar: isSelectionMode
              ? CustomAppBar(
                  title: "",
                  isDark: isDark,
                  isSelectionMode: true,
                  selectedCount: selectedCount,
                  onCancelSelection: multiSelect.cancelSelection,
                  onDeleteSelected: () => ExpenseActionHandler.handleDeleteSelected(context),
                  onSelectAll: () => multiSelect.selectAll(filteredExpenses),
                  onDeselectAll: () => multiSelect.deselectAll(),
                  totalCount: filteredExpenses.length,
                )
              : null,

          body: Column(
            children: [
              HomeHeader(
                fadeAnimation: fadeAnimation,
                isDark: isDark,
                onTapProfile: () => _showProfileSheet(context),
              ),

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
                      loc.newExpense,
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

  // --- HELPER INTERNI ---
  
  // Mostra feedback visivo in caso di errori critici (es. fallimento eliminazione).
  void _showErrorSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message, 
          style: TextStyle(color: AppColors.textLight,)
        ),
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

  // Ricarica i dati dal backend e riapplica l'ordinamento selezionato.
  Future<void> _refreshExpenses() async {
    final multiSelect = context.read<MultiSelectProvider>();
    final expenseProvider = context.read<ExpenseProvider>();

    multiSelect.cancelSelection();
    
    await expenseProvider.initialise();
    
    if (_sortCriteria.isNotEmpty) {
      expenseProvider.sortBy(_sortCriteria);
    }
  }

  // Apre il bottom sheet per la gestione del profilo utente.
  Future<void> _showProfileSheet(BuildContext context) async {
    await DialogUtils.showProfileSheet(context);
  }
}