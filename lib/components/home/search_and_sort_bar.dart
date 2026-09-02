import 'package:expense_tracker/config/app_colors.dart';
import 'package:expense_tracker/l10n/app_localizations.dart';
import 'package:expense_tracker/utils/dialogs/dialog_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// FILE: search_and_sort_bar.dart
/// DESCRIZIONE: Barra sticky con campo di ricerca testuale e pulsante per
/// aprire il menu di ordinamento delle spese. Estratto da HomeContentList
/// per isolare la UI di ricerca/ordinamento dal resto della lista.

class SearchAndSortBar extends ConsumerWidget {
  final bool isDark;
  final TextEditingController searchController;
  final ValueChanged<String> onSortSelected;

  const SearchAndSortBar({
    super.key,
    required this.isDark,
    required this.searchController,
    required this.onSortSelected,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loc = AppLocalizations.of(context)!;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      ),
      padding: EdgeInsets.fromLTRB(20.w, 20.h, 20.w, 16.h),
      child: Row(
        children: [
          // Campo di input per la ricerca testuale
          Expanded(
            child: Container(
              height: 50.h,
              decoration: BoxDecoration(
                color: isDark ? AppColors.cardDark : AppColors.cardLight,
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
                    color: isDark ? AppColors.greyDark : AppColors.greyLight,
                  ),
                  prefixIcon: Icon(
                    Icons.search_rounded,
                    size: 22.sp,
                    color: isDark ? AppColors.greyDark : AppColors.greyLight,
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
                  {"title": loc.sortDateNewest, "criteria": "date_desc"},
                  {"title": loc.sortDateOldest, "criteria": "date_asc"},
                  {"title": loc.sortAmountHighest, "criteria": "amount_desc"},
                  {"title": loc.sortAmountLowest, "criteria": "amount_asc"},
                ],
              );

              if (selected != null) onSortSelected(selected);
            },
            child: Container(
              width: 50.w,
              height: 50.h,
              decoration: BoxDecoration(
                color: isDark ? AppColors.cardDark : AppColors.cardLight,
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
                color: isDark ? AppColors.greyDark : AppColors.greyLight,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
