// home_page.dart
import 'package:expense_tracker/components/home/home_content_list.dart';
import 'package:expense_tracker/components/home/home_header.dart';
import 'package:expense_tracker/components/shared/custom_appbar.dart';
import 'package:expense_tracker/providers/multi_select_provider.dart';
import 'package:expense_tracker/models/expense_model.dart';
import 'package:expense_tracker/utils/dialogs/dialog_utils.dart';
import 'package:expense_tracker/utils/snackbar_utils.dart'; 
import 'package:expense_tracker/providers/expense_provider.dart';
import 'package:expense_tracker/providers/profile_provider.dart';
import 'package:expense_tracker/pages/new_expense_page.dart';
import 'package:expense_tracker/theme/app_colors.dart';
import 'package:expense_tracker/utils/fade_animation_mixin.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

/// FILE: home_page.dart
/// DESCRIZIONE: Dashboard principale dell'applicazione.
/// Questa pagina orchestra la visualizzazione delle spese, la ricerca locale,
/// e la gestione dello stato di selezione multipla (per eliminazioni di gruppo).
/// Collega i Provider (Expense, Profile, MultiSelect) ai componenti UI (Header, Lista, AppBar).

class HomePage extends StatefulWidget {
  static const route = "/home/page";
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with TickerProviderStateMixin, FadeAnimationMixin {
  
  // --- STATO E CONTROLLER ---
  // Gestione dei controller per input di ricerca, animazioni della lista
  // e criteri di ordinamento locali.
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";
  String _sortCriteria = "date_desc";

  late AnimationController _listAnimationController;

  @override
  TickerProvider get vsync => this;

  // --- CICLO DI VITA ---
  // Inizializzazione dei listener per la ricerca, caricamento asincrono
  // dei dati del profilo e setup delle animazioni di fade-in.
  @override
  void initState() {
    super.initState();

    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text;
      });
    });

    // Caricamento profilo all'avvio
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

  // --- LOGICA DI FILTRAGGIO ---
  // Filtra la lista delle spese in memoria basandosi sulla query di ricerca.
  // 
  List<ExpenseModel> _getFilteredExpenses(ExpenseProvider expenseProvider) {
    final query = _searchQuery.toLowerCase();
    return expenseProvider.expenses.where((expense) {
      final desc = expense.description?.toLowerCase() ?? "";
      return desc.contains(query);
    }).toList();
  }

  // --- BUILD UI ---
  // Costruzione della struttura Scaffold. Utilizza un Consumer2 per reagire
  // ai cambiamenti sia della selezione multipla che dei dati delle spese.
  // 
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Consumer2<MultiSelectProvider, ExpenseProvider>(
      builder: (context, multiSelect, expenseProvider, child) {
        final isSelectionMode = multiSelect.isSelectionMode;
        final selectedCount = multiSelect.selectedCount;
        final filteredExpenses = _getFilteredExpenses(expenseProvider);

        return Scaffold(
          // --- APPBAR CONTESTUALE ---
          // Mostra una AppBar personalizzata solo quando è attiva la modalità selezione,
          // permettendo azioni di gruppo (es. elimina tutto, seleziona tutto).
          // 
          appBar: isSelectionMode
              ? CustomAppBar(
                  title: "",
                  isDark: isDark,
                  isSelectionMode: true,
                  selectedCount: selectedCount,
                  onCancelSelection: multiSelect.cancelSelection,
                  // 👇 Qui colleghiamo la funzione locale
                  onDeleteSelected: _handleDeleteSelected,
                  onSelectAll: () => multiSelect.selectAll(filteredExpenses),
                  onDeselectAll: () => multiSelect.deselectAll(),
                  totalCount: filteredExpenses.length,
                )
              : null,

          // --- CORPO PAGINA ---
          // Divide la UI in due macro-sezioni: Header (Profilo) e Lista contenuti.
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

          // --- FLOATING ACTION BUTTON ---
          // Tasto per aggiungere nuove spese. Viene nascosto durante la selezione multipla
          // per evitare conflitti visivi con le azioni di modifica.
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

  // --- GESTIONE ELIMINAZIONE ---
  // Gestisce il flusso completo di cancellazione: 
  // 1. Dialogo di conferma.
  // 2. Chiamata al Provider per rimozione logica.
  // 3. Feedback SnackBar con opzione "Annulla" (Undo).
  // 
  Future<void> _handleDeleteSelected() async {
    final multiSelect = context.read<MultiSelectProvider>();
    final expenseProvider = context.read<ExpenseProvider>();
    final count = multiSelect.selectedCount;

    if (count == 0) return;

    // 1. Dialogo di conferma
    final confirm = await DialogUtils.showConfirmDialog(
      context,
      title: "Eliminazione ${count == 1 ? 'singola' : 'multipla'}",
      content:
          "Vuoi eliminare $count ${count == 1 ? 'spesa selezionata' : 'spese selezionate'}?",
      confirmText: "Elimina",
      cancelText: "Annulla",
    );

    if (confirm != true) return;
    if (!mounted) return;

    // 2. Chiamata al Provider (che ritorna gli oggetti eliminati)
    final deletedItems = await multiSelect.deleteSelectedExpenses(expenseProvider.expenses);

    if (!mounted) return;

    // 3. Feedback SnackBar con Undo
    SnackbarUtils.show(
      context: context,
      title: count == 1 ? "Eliminata!" : "Eliminate!",
      message:
          "$count ${count == 1 ? 'spesa eliminata' : 'spese eliminate'} con successo.",
      deletedItem: deletedItems,
      // La cancellazione reale è già avvenuta nel provider, qui gestiamo solo UI
      onDelete: (_) {},
      // Ripristino
      onRestore: (_) async {
        await multiSelect.restoreExpenses(deletedItems);
      },
    );
  }

  // --- UTILS ---
  // Funzioni ausiliarie per aggiornare i dati (pull-to-refresh) 
  // e mostrare il modale del profilo utente.
  Future<void> _refreshExpenses() async {
    // Usiamo read per evitare rebuild inutili all'interno di funzioni asincrone
    final multiSelect = context.read<MultiSelectProvider>();
    final expenseProvider = context.read<ExpenseProvider>();

    multiSelect.cancelSelection();
    await expenseProvider.initialise();
    if (_sortCriteria.isNotEmpty) {
      expenseProvider.sortBy(_sortCriteria);
    }
  }

  Future<void> _showProfileSheet(BuildContext context) async {
    await DialogUtils.showProfileSheet(context);
  }
}
