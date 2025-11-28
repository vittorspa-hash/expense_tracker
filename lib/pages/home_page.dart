// home_page.dart
// -----------------------------------------------------------------------------
// 🏠 HOME PAGE PRINCIPALE DELL’APPLICAZIONE
//
// Include:
//  • Header animato con avatar, nome utente e pulsanti scorciatoia
//  • Lista delle spese con ricerca, filtro e ordinamento
//  • Selezione multipla con eliminazione
//  • FAB per aggiungere una nuova spesa
//  • Gestione avatar locale
//
// La pagina usa GetX per reattività (Obx) e animazioni fluide.
// -----------------------------------------------------------------------------

import 'dart:io';
import 'package:expense_tracker/components/home/home_content_list.dart';
import 'package:expense_tracker/components/home/home_header.dart';
import 'package:expense_tracker/controllers/multi_select_controller.dart';
import 'package:expense_tracker/models/dialog_model.dart';
import 'package:expense_tracker/models/store_model.dart';
import 'package:expense_tracker/pages/new_expense_page.dart';
import 'package:expense_tracker/theme/app_colors.dart';
import 'package:expense_tracker/utils/fade_animation_mixin.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class HomePage extends StatefulWidget {
  static const route = "/home/page";
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

// -----------------------------------------------------------------------------
// 🔧 STATE DELLA HOME – Gestione animazioni, avatar, ricerca, selezione multipla
// -----------------------------------------------------------------------------
class _HomePageState extends State<HomePage>
    with TickerProviderStateMixin, FadeAnimationMixin {
  // 🔍 Controller per ricerca
  final TextEditingController _searchController = TextEditingController();
  final RxString _searchQuery = "".obs;

  // ↕️ Ordinamento spese
  final RxString _sortCriteria = "date_desc".obs;

  // 🖼️ Avatar salvato localmente
  File? _localAvatar;

  // 🟦 Controller selezione multipla (GetX)
  final MultiSelectController multiSelect = Get.put(MultiSelectController());

  // 🎬 Controller animazione lista
  late AnimationController _listAnimationController;

  // Getter per il vsync richiesto dal mixin
  @override
  TickerProvider get vsync => this;

  @override
  void initState() {
    super.initState();

    // 🔎 Aggiornamento query ricerca in tempo reale
    _searchController.addListener(() {
      _searchQuery.value = _searchController.text;
    });

    // 📸 Caricamento avatar locale (se esiste)
    _loadLocalAvatar();

    // Animazione fade con mixin
    initFadeAnimation();

    // 🎞️ Animazione lista
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

    // 🔥 Rimozione controller GetX al dispose
    Get.delete<MultiSelectController>();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // -------------------------------------------------------------------------
    // 🟣 Obx → aggiorna l’interfaccia al cambio dello stato di selezione multipla
    // -------------------------------------------------------------------------
    return Obx(() {
      final isSelectionMode = multiSelect.isSelectionMode.value;
      final selectedCount = multiSelect.selectedIds.length;

      return Scaffold(
        // ---------------------------------------------------------------------
        // 🟥 APPBAR MODE SELEZIONE MULTIPLA
        // ---------------------------------------------------------------------
        appBar: isSelectionMode
            ? AppBar(
                elevation: 0,
                flexibleSpace: Container(
                  decoration: BoxDecoration(color: AppColors.primary),
                ),

                // ❌ Pulsante annulla selezione
                leading: IconButton(
                  icon: Icon(
                    Icons.close_rounded,
                    color: isDark ? AppColors.textDark : AppColors.textLight,
                    size: 26.sp,
                  ),
                  onPressed: multiSelect.cancelSelection,
                ),

                // 📌 Conteggio elementi selezionati
                title: Text(
                  "$selectedCount ${selectedCount == 1 ? "selezionata" : "selezionate"}",
                  style: TextStyle(
                    color: isDark ? AppColors.textDark : AppColors.textLight,
                    fontWeight: FontWeight.w700,
                    fontSize: 20.sp,
                    letterSpacing: 0.5,
                  ),
                ),

                // 🗑️ Pulsante elimina selezionati
                actions: [
                  Container(
                    margin: EdgeInsets.only(right: 8.w),
                    decoration: BoxDecoration(
                      color: AppColors.delete.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    child: IconButton(
                      icon: Icon(Icons.delete_rounded, size: 24.sp),
                      color: AppColors.delete,
                      onPressed: () => multiSelect.deleteSelected(context),
                    ),
                  ),
                ],
              )
            : null,

        // ---------------------------------------------------------------------
        // 📄 CONTENUTO PRINCIPALE
        // ---------------------------------------------------------------------
        body: Column(
          children: [
            // ---------------------------------------------------------------
            // 👤 HEADER ANIMATO (avatar, benvenuto, saldo, scorciatoie)
            // ---------------------------------------------------------------
            HomeHeader(
              fadeAnimation: fadeAnimation,
              localAvatar: _localAvatar,
              user: user,
              isDark: isDark,
              onTapProfile: () => _showProfileSheet(context, user),
            ),

            // ---------------------------------------------------------------
            // 📃 LISTA DELLE SPESE (con ricerca, sort, refresh)
            // ---------------------------------------------------------------
            Expanded(
              child: HomeContentList(
                isDark: isDark,
                searchController: _searchController,
                searchQuery: _searchQuery,
                sortCriteria: _sortCriteria,
                onRefreshExpenses: _refreshExpenses,
              ),
            ),
          ],
        ),

        // ---------------------------------------------------------------------
        // ➕ FLOATING ACTION BUTTON – Aggiungi nuova spesa
        // (nascosto quando è attiva la selezione multipla)
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

                  // 📝 Testo + icona
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
    });
  }

  // -----------------------------------------------------------------------------
  // 🖼️ LOAD AVATAR LOCALE (se salvato nel dispositivo)
  // -----------------------------------------------------------------------------
  Future<void> _loadLocalAvatar() async {
    final appDir = await getApplicationDocumentsDirectory();
    final file = File('${appDir.path}/profile_picture.jpg');
    setState(() {
      _localAvatar = file.existsSync() ? file : null;
    });
  }

  // -----------------------------------------------------------------------------
  // 🔄 REFRESH COMPLETO DELLE SPESE (reload + ordinamento)
  // -----------------------------------------------------------------------------
  Future<void> _refreshExpenses() async {
    multiSelect.cancelSelection();
    await storeModel.value.initialise();
    if (_sortCriteria.value.isNotEmpty) {
      storeModel.value.sortBy(_sortCriteria.value);
    }
  }

  // -----------------------------------------------------------------------------
  // 👤 MOSTRA MODALE PROFILO UTENTE
  // -----------------------------------------------------------------------------
  Future<void> _showProfileSheet(BuildContext context, User? user) async {
    await DialogModel.showProfileSheet(
      context,
      user: user,
      localAvatar: _localAvatar,
      reloadAvatar: _loadLocalAvatar,
    );
  }
}
