// days_page.dart
// -----------------------------------------------------------------------------
// 📆 PAGINA DETTAGLIO GIORNALIERO (DAYS PAGE)
// -----------------------------------------------------------------------------
// Mostra le spese di un singolo giorno con:
// - Card totale giornata
// - Lista di tutte le spese
// - Selezione multipla per eliminazioni
// - Refresh per aggiornare i dati
// -----------------------------------------------------------------------------

import 'package:expense_tracker/components/report/total_card_widget.dart';
import 'package:expense_tracker/controllers/multi_select_controller.dart';
import 'package:expense_tracker/utils/fade_animation_mixin.dart';
import 'package:expense_tracker/utils/snackbar_utils.dart';
import 'package:expense_tracker/models/dialog_model.dart';
import 'package:expense_tracker/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:expense_tracker/models/store_model.dart';
import 'package:expense_tracker/components/expense/expense_tile.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class DaysPage extends StatefulWidget {
  static const route = "/days";

  final int year; // 🔧 Anno selezionato
  final int month; // 🔧 Mese selezionato
  final int day; // 🔧 Giorno selezionato

  const DaysPage({
    super.key,
    required this.year,
    required this.month,
    required this.day,
  });

  @override
  State<DaysPage> createState() => _DaysPageState();
}

class _DaysPageState extends State<DaysPage>
    with SingleTickerProviderStateMixin, FadeAnimationMixin {
  // Getter per il vsync richiesto dal mixin
  @override
  TickerProvider get vsync => this;

  @override
  void initState() {
    super.initState();
    // 🔄 Animazione fade in della pagina
    initFadeAnimation();
  }

  @override
  void dispose() {
    disposeFadeAnimation();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // 📌 FUNZIONI DI FORMATTARE DATA
  // ---------------------------------------------------------------------------
  String formatDateItaliano(DateTime date) {
    final giorno = DateFormat("d", "it_IT").format(date);
    final mese = DateFormat("MMMM", "it_IT").format(date);
    final anno = DateFormat("y", "it_IT").format(date);
    final meseCapitalizzato = mese[0].toUpperCase() + mese.substring(1);
    return "$giorno $meseCapitalizzato $anno";
  }

  String getDayOfWeek(DateTime date) {
    final giornoSettimana = DateFormat("EEEE", "it_IT").format(date);
    return giornoSettimana[0].toUpperCase() + giornoSettimana.substring(1);
  }

  @override
  Widget build(BuildContext context) {
    // 🔹 Controller per gestione selezione multipla spese
    final multiSelect = Get.put(MultiSelectController());
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final date = DateTime(widget.year, widget.month, widget.day);
    final dateLabel = formatDateItaliano(date);
    final dayOfWeek = getDayOfWeek(date);

    return Obx(() {
      final isSelectionMode = multiSelect.isSelectionMode.value;
      final selectedCount = multiSelect.selectedIds.length;

      return Scaffold(
        // -----------------------------------------------------------------------
        // 🗂 APPBAR DINAMICA (SELEZIONE MULTIPLA / NORMALE)
        // -----------------------------------------------------------------------
        appBar: isSelectionMode
            ? AppBar(
                elevation: 0,
                flexibleSpace: Container(
                  decoration: BoxDecoration(color: AppColors.primary),
                ),
                leading: IconButton(
                  icon: Icon(
                    Icons.close_rounded,
                    color: isDark ? AppColors.textDark : AppColors.textLight,
                    size: 26.sp,
                  ),
                  onPressed: multiSelect.cancelSelection,
                ),
                title: Text(
                  "$selectedCount ${selectedCount == 1 ? "selezionata" : "selezionate"}",
                  style: TextStyle(
                    color: isDark ? AppColors.textDark : AppColors.textLight,
                    fontWeight: FontWeight.w700,
                    fontSize: 20.sp,
                    letterSpacing: 0.5,
                  ),
                ),
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
            : AppBar(
                elevation: 0,
                iconTheme: IconThemeData(color: isDark ? AppColors.textDark : AppColors.textLight),
                title: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      dayOfWeek,
                      style: TextStyle(
                        color: isDark ? AppColors.textDark : AppColors.textLight,
                        fontSize: 20.sp,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                      ),
                    ),
                    Text(
                      dateLabel,
                      style: TextStyle(
                        color: isDark ? AppColors.textDark.withValues(alpha: 0.85) : AppColors.textLight.withValues(alpha: 0.85),
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
                ),
                flexibleSpace: Container(
                  decoration: BoxDecoration(color: AppColors.primary),
                ),
              ),

        // -----------------------------------------------------------------------
        // 🗂 BODY PRINCIPALE
        // -----------------------------------------------------------------------
        body: Container(
          decoration: BoxDecoration(
            color: isDark
                ? AppColors.backgroundDark
                : AppColors.backgroundLight,
          ),
          child: SafeArea(
            child: Obx(() {
              // 🔹 Lista spese del giorno
              final expensesList = storeModel.value.expensesOfDay(
                widget.year,
                widget.month,
                widget.day,
              );

              // -------------------------------------------------------------------
              // ⚠️ Nessuna spesa registrata
              // -------------------------------------------------------------------
              if (expensesList.isEmpty) {
                return buildWithFadeAnimation(
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: EdgeInsets.all(24.w),
                          decoration: BoxDecoration(
                            color: isDark ? AppColors.secondaryDark : AppColors.secondaryLight,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.receipt_long_rounded,
                            size: 64.sp,
                            color: isDark
                                ? AppColors.greyLight
                                : AppColors.greyDark,
                          ),
                        ),
                        SizedBox(height: 24.h),
                        Text(
                          "Nessuna spesa in questo giorno",
                          style: TextStyle(
                            fontSize: 16.sp,
                            color: isDark
                                ? AppColors.textLight
                                : AppColors.textDark2,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(height: 8.h),
                        Text(
                          "Aggiungi una spesa per iniziare",
                          style: TextStyle(
                            fontSize: 14.sp,
                            color: isDark
                                ? AppColors.greyDark
                                : AppColors.greyLight,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }

              // 🔹 Totale spese giorno
              final totalDay = expensesList.fold<double>(
                0.0,
                (sum, expense) => sum + expense.value,
              );

              return buildWithFadeAnimation(
                Column(
                  children: [
                    // -----------------------------------------------------------------
                    // 💰 TOTAL CARD WIDGET GIORNALIERO
                    // -----------------------------------------------------------------
                    TotalCardWidget(
                      label: "Totale giornata",
                      totalAmount: totalDay,
                      icon: Icons.receipt_rounded,
                      itemCount: expensesList.length,
                      itemLabel: expensesList.length == 1 ? "spesa" : "spese",
                    ),

                    // -----------------------------------------------------------------
                    // 📝 TITOLO "TUTTE LE SPESE"
                    // -----------------------------------------------------------------
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 20.w),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          "Tutte le spese",
                          style: TextStyle(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w700,
                            color: isDark
                                ? AppColors.greyDark
                                : AppColors.greyLight,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ),
                    ),

                    SizedBox(height: 12.h),

                    // -----------------------------------------------------------------
                    // 📋 LISTA DELLE SPESE CON SELEZIONE E ELIMINAZIONE
                    // -----------------------------------------------------------------
                    Expanded(
                      child: RefreshIndicator(
                        color: AppColors.primary,
                        onRefresh: () async {
                          multiSelect.cancelSelection();
                          await storeModel.value.initialise();
                        },
                        child: ListView.separated(
                          padding: EdgeInsets.fromLTRB(20.w, 0, 20.w, 20.h),
                          itemCount: expensesList.length,
                          separatorBuilder: (_, _) => SizedBox(height: 4.h),
                          itemBuilder: (context, index) {
                            final expense = expensesList[index];
                            final isSelected = multiSelect.selectedIds.contains(
                              expense.uuid,
                            );

                            return Dismissible(
                              key: Key(expense.uuid),
                              direction: isSelectionMode
                                  ? DismissDirection.none
                                  : DismissDirection.endToStart,
                              confirmDismiss: (_) async {
                                if (isSelectionMode) return false;
                                final confirm =
                                    await DialogModel.showConfirmDialog(
                                      context,
                                      title: "Conferma eliminazione",
                                      content:
                                          "Vuoi eliminare la spesa selezionata?",
                                      confirmText: "Elimina",
                                      cancelText: "Annulla",
                                    );
                                return confirm ?? false;
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
                              onDismissed: (_) {
                                SnackbarUtils.show(
                                  context: context,
                                  title: "Eliminata!",
                                  message: "Spesa eliminata con successo.",
                                  deletedItem: expense,
                                  onDelete: (exp) =>
                                      storeModel.value.deleteExpense(exp),
                                  onRestore: (exp) =>
                                      storeModel.value.createExpense(
                                        value: exp.value,
                                        description: exp.description,
                                        date: exp.createdOn,
                                      ),
                                );
                              },

                              // 🔹 Tile della spesa con selezione multipla
                              child: ExpenseTile(
                                expense,
                                isSelectionMode: isSelectionMode,
                                isSelected: isSelected,
                                onLongPress: () =>
                                    multiSelect.onLongPress(expense),
                                onSelectToggle: () =>
                                    multiSelect.onToggleSelect(expense),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ),
        ),
      );
    });
  }
}
