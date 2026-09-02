import 'package:expense_tracker/components/home/home_content_list.dart';
import 'package:expense_tracker/components/home/home_header.dart';
import 'package:expense_tracker/components/home/new_expense_fab.dart';
import 'package:expense_tracker/components/shared/custom_appbar.dart';
import 'package:expense_tracker/config/di/riverpod_providers.dart';
import 'package:expense_tracker/l10n/app_localizations.dart';
import 'package:expense_tracker/models/expense_model.dart';
import 'package:expense_tracker/utils/expense_action_handler.dart';
import 'package:expense_tracker/config/app_colors.dart';
import 'package:expense_tracker/utils/expense_calculator.dart';
import 'package:expense_tracker/utils/fade_animation_mixin.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// FILE: home_page.dart
/// DESCRIZIONE: Dashboard e schermata principale dell'applicazione.
/// Gestisce la visualizzazione dell'elenco delle spese, la ricerca testuale, l'ordinamento,
/// le animazioni di ingresso (Fade) e integra la logica di multi-selezione delegandola
/// a multiSelectNotifierProvider di Riverpod per la cancellazione di massa.

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage>
    with TickerProviderStateMixin, FadeAnimationMixin {
  // --- STATO LOCALE E CONTROLLER ---
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";
  String _sortCriteria = "date_desc";
  late AnimationController _listAnimationController;

  @override
  TickerProvider get vsync => this;

  // --- CICLO DI VITA E INIZIALIZZAZIONE ---
  @override
  void initState() {
    super.initState();

    // Sottoscrizione alla ricerca testuale per l'aggiornamento in tempo reale.
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text;
      });
    });

    // Caricamento dei dati utente asincroni locali e pianificazione notifiche post-build.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final l10n = AppLocalizations.of(context);
        if (l10n != null) {
          ref
              .read(notificationNotifierProvider.notifier)
              .rescheduleNotifications(l10n);
        }
      }
    });

    // Inizializzazione dei controller delle animazioni.
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

  // --- COSTRUZIONE INTERFACCIA ---
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isKeyboardOpen = MediaQuery.of(context).viewInsets.bottom > 0;

    // --- SIDE-EFFECT: GESTIONE ERRORI ---
    // ref.listen reagisce una sola volta al cambio di errorMessage, non ad ogni rebuild,
    // e Riverpod smette automaticamente di notificare se il widget viene smontato
    ref.listen(expenseNotifierProvider, (previous, next) {
      final message = next.value?.errorMessage;
      if (message != null) {
        _showErrorSnackBar(context, message);
        ref.read(expenseNotifierProvider.notifier).clearError();
      }
    });

    // ASCOLTO DEGLI STATI (RIVERPOD)
    // select mirato: HomePage si ricostruisce solo quando cambia isLoading,
    // non ad ogni modifica della lista spese
    final multiSelectState = ref.watch(multiSelectNotifierProvider);
    final isLoading = ref.watch(
      expenseNotifierProvider.select((s) => s.value?.isLoading ?? false),
    );

    // Estrazione delle proprietà utili dello stato
    final isSelectionMode = multiSelectState.isSelectionMode;
    final selectedCount = multiSelectState.selectedCount;

    // Calcolato solo quando serve (isSelectionMode true), serve ai callback/contatori dell'AppBar di selezione multipla
    final currentFiltered = isSelectionMode
        ? _currentFilteredExpenses()
        : const <ExpenseModel>[];

    return Scaffold(
      resizeToAvoidBottomInset: false,
      // APP BAR CONDIZIONALE (Attiva solo in modalità selezione di massa)
      appBar: isSelectionMode
          ? CustomAppBar(
              appBarBackgroundColor: AppColors.primary,
              appBarTextColor: isDark
                  ? AppColors.textDark
                  : AppColors.textLight,
              title: "",
              isDark: isDark,
              isSelectionMode: true,
              selectedCount: selectedCount,
              onCancelSelection: () =>
                  ref.read(multiSelectNotifierProvider.notifier).deselectAll(),
              onDeleteSelected: () =>
                  ExpenseActionHandler.handleDeleteSelected(context, ref),
              onSelectAll: () => ref
                  .read(multiSelectNotifierProvider.notifier)
                  .selectAll(currentFiltered),
              onDeselectAll: () =>
                  ref.read(multiSelectNotifierProvider.notifier).deselectAll(),
              totalCount: currentFiltered.length,
            )
          : null,

      // CORPO DELLA PAGINA (Dashboard, Header e Lista Spese)
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              color: isDark
                  ? AppColors.backgroundDark
                  : AppColors.backgroundLight,
            ),
            child: Column(
              children: [
                HomeHeader(
                  fadeAnimation: fadeAnimation,
                  isDark: isDark,
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
          // Indicatore di caricamento in overlay bloccante
          if (isLoading)
            Container(
              color: AppColors.backgroundDark.withValues(alpha: 0.3),
              child: Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
            ),
        ],
      ),

      // AZIONE INSERIMENTO NUOVA SPESA
      floatingActionButton: !isSelectionMode && !isLoading && !isKeyboardOpen
          ? NewExpenseFab(isDark: isDark, onReturn: _clearSearch)
          : null,
    );
  }

  // --- LOGICA E METODI DI SUPPORTO ---

  /// Recupera la lista filtrata corrente per select-all/count nell'AppBar
  /// di selezione multipla. Legge lo stato "on demand" (ref.read) perché
  /// invocata solo dentro i callback dell'AppBar, non durante il build.
  List<ExpenseModel> _currentFilteredExpenses() {
    final expenses =
        ref.read(expenseNotifierProvider).value?.expenses ?? const [];
    return ExpenseCalculator.filterByQuery(expenses, _searchQuery);
  }

  /// Pulisce il controller di ricerca e resetta lo stato della query locale.
  void _clearSearch() {
    _searchController.clear();
    setState(() => _searchQuery = "");
  }

  /// Mostra un banner informativo sul fondo dello schermo in caso di errore.
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

  /// Esegue il refresh manuale svuotando la multi-selezione e reinizializzando il provider delle spese.
  Future<void> _refreshExpenses() async {
    ref.read(multiSelectNotifierProvider.notifier).deselectAll();
    _clearSearch();
    ref.invalidate(expenseNotifierProvider);
    await ref.read(expenseNotifierProvider.future);
    if (_sortCriteria.isNotEmpty) {
      ref.read(expenseNotifierProvider.notifier).sortBy(_sortCriteria);
    }
  }
}
