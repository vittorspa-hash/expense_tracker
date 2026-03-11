// FILE: report_charts_carousel.dart
// DESCRIZIONE: Mostra ReportBarChart e ReportPieChart uno alla volta,
// navigabili tramite swipe orizzontale. Usa AnimatedSwitcher invece di
// PageView per evitare il vincolo dell'altezza fissa, permettendo a ogni
// grafico di occupare esattamente lo spazio che gli serve.

import 'package:expense_tracker/components/report/report_bar_chart.dart';
import 'package:expense_tracker/components/report/report_pie_chart.dart';
import 'package:expense_tracker/components/report/report_section_header.dart';
import 'package:expense_tracker/config/theme/app_colors.dart';
import 'package:expense_tracker/l10n/app_localizations.dart';
import 'package:expense_tracker/models/expense_category.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class ReportChartsCarousel extends StatefulWidget {
  final List<double> barValues;
  final List<String> monthNames;
  final Map<ExpenseCategory, double> categoryData;

  const ReportChartsCarousel({
    super.key,
    required this.barValues,
    required this.monthNames,
    required this.categoryData,
  });

  @override
  State<ReportChartsCarousel> createState() => _ReportChartsCarouselState();
}

class _ReportChartsCarouselState extends State<ReportChartsCarousel> {
  int _currentPage = 0;

  // Direzione dello swipe: usata per animare l'entrata/uscita
  // nella direzione corretta (sinistra o destra).
  bool _swipeLeftToRight = false;

  void _goToPage(int index) {
    if (index == _currentPage) return;
    setState(() {
      _swipeLeftToRight = index < _currentPage;
      _currentPage = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final loc = AppLocalizations.of(context)!;

    final bool hasCategoryData = widget.categoryData.values.any((v) => v > 0);

    // Senza dati categoria non serve il carousel.
    if (!hasCategoryData) {
      return ReportBarChart(
        values: widget.barValues,
        monthNames: widget.monthNames,
      );
    }

    final charts = [
      ReportBarChart(
        key: const ValueKey('bar'),
        values: widget.barValues,
        monthNames: widget.monthNames,
      ),
      ReportPieChart(key: const ValueKey('pie'), data: widget.categoryData),
    ];

    return Column(
      children: [
        // --- HEADER ANIMATO ---
        // ValueKey(_currentPage) forza la ricostruzione al cambio pagina,
        // producendo un crossfade fluido tra i due titoli.
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: ReportSectionHeader(
            key: ValueKey(_currentPage),
            title: _currentPage == 0 ? loc.monthlyTrend : loc.categoryBreakdown,
          ),
        ),

        SizedBox(height: 12.h),

        // --- SWIPE DETECTOR + ANIMATED SWITCHER ---
        // GestureDetector rileva lo swipe orizzontale e cambia pagina.
        // AnimatedSwitcher gestisce la transizione con slide nella direzione
        // corretta, adattando l'altezza al grafico corrente senza vincoli fissi.
        GestureDetector(
          onHorizontalDragEnd: (details) {
            // Soglia minima di velocità per distinguere swipe da scroll accidentale.
            const double threshold = 200;
            final velocity = details.primaryVelocity ?? 0;

            if (velocity < -threshold && _currentPage < charts.length - 1) {
              // Swipe sinistra → pagina successiva
              _goToPage(_currentPage + 1);
            } else if (velocity > threshold && _currentPage > 0) {
              // Swipe destra → pagina precedente
              _goToPage(_currentPage - 1);
            }
          },
          // Behavior opaque per catturare il drag anche su aree trasparenti.
          behavior: HitTestBehavior.opaque,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 350),
            // Transizione slide: entra dal lato opposto alla direzione dello swipe.
            transitionBuilder: (child, animation) {
              final isIncoming =
                  child.key == ValueKey(_currentPage == 0 ? 'bar' : 'pie');

              // Il widget entrante slide da destra (o sinistra se swipe inverso).
              // Il widget uscente slide verso sinistra (o destra).
              final offsetIn = _swipeLeftToRight
                  ? const Offset(-1.0, 0)
                  : const Offset(1.0, 0);
              final offsetOut = _swipeLeftToRight
                  ? const Offset(1.0, 0)
                  : const Offset(-1.0, 0);

              return SlideTransition(
                position:
                    Tween<Offset>(
                      begin: isIncoming ? offsetIn : offsetOut,
                      end: Offset.zero,
                    ).animate(
                      CurvedAnimation(
                        parent: animation,
                        curve: Curves.easeOutCubic,
                      ),
                    ),
                child: FadeTransition(opacity: animation, child: child),
              );
            },
            child: charts[_currentPage],
          ),
        ),

        SizedBox(height: 12.h),

        // --- INDICATORE A PUNTI ---
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(charts.length, (index) {
            final bool isActive = index == _currentPage;
            return GestureDetector(
              onTap: () => _goToPage(index),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                margin: EdgeInsets.symmetric(horizontal: 4.w),
                width: isActive ? 20.w : 8.w,
                height: 8.w,
                decoration: BoxDecoration(
                  color: isActive
                      ? AppColors.primary
                      : (isDark ? AppColors.greyDark : AppColors.greyLight),
                  borderRadius: BorderRadius.circular(4.r),
                ),
              ),
            );
          }),
        ),
      ],
    );
  }
}
