import 'package:expense_tracker/l10n/app_localizations.dart';
import 'package:expense_tracker/pages/auth_page.dart';
import 'package:expense_tracker/config/app_colors.dart';
import 'package:expense_tracker/providers/auth_provider.dart';
import 'package:expense_tracker/utils/repository_failure.dart';
import 'package:flutter/material.dart';
import 'package:expense_tracker/pages/home_page.dart';
import 'package:expense_tracker/providers/expense_provider.dart';
import 'package:provider/provider.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final authStatus = context.watch<AuthProvider>().authStatus;
    final expenseProvider = context.watch<ExpenseProvider>();

    switch (authStatus) {
      case AuthStatus.unknown:
        return _buildLoadingScreen();

      case AuthStatus.unauthenticated:
      case AuthStatus.unverified:
        WidgetsBinding.instance.addPostFrameCallback((_) {
          context.read<ExpenseProvider>().clear();
        });
        return const AuthPage();

      case AuthStatus.authenticated:
        switch (expenseProvider.initStatus) {
          case ExpenseInitStatus.initial:
            WidgetsBinding.instance.addPostFrameCallback(
              (_) => expenseProvider.initialise(),
            );
            return _buildLoadingScreen();

          case ExpenseInitStatus.loading:
            return _buildLoadingScreen();

          case ExpenseInitStatus.error:
            return _buildErrorScreen(
              context,
              expenseProvider.initError,
              expenseProvider,
              isDark,
            );

          case ExpenseInitStatus.initialized:
            return const HomePage();
        }
    }
  }

  Widget _buildLoadingScreen() {
    return Scaffold(
      body: Center(child: CircularProgressIndicator(color: AppColors.primary)),
    );
  }

  Widget _buildErrorScreen(
    BuildContext context,
    Object? error,
    ExpenseProvider expenseProvider,
    bool isDark,
  ) {
    final loc = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: isDark
          ? AppColors.backgroundDark
          : AppColors.backgroundLight,
      body: Center(
        child: Padding(
          padding: EdgeInsets.all(24.r),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 48.sp, color: AppColors.delete),
              SizedBox(height: 16.h),
              Text(
                loc.appInitErrorTitle,
                style: TextStyle(
                  fontSize: 20.sp,
                  fontWeight: FontWeight.bold,
                  color: isDark ? AppColors.textLight : AppColors.textDark,
                ),
              ),
              SizedBox(height: 8.h),
              Text(
                (error is RepositoryFailure)
                    ? error.message
                    : loc.appInitErrorMessage,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: isDark ? AppColors.greyDark : AppColors.greyLight,
                ),
              ),
              SizedBox(height: 24.h),
              ElevatedButton.icon(
                icon: Icon(
                  Icons.refresh,
                  size: 20.sp,
                  color: isDark ? AppColors.textDark : AppColors.textLight,
                ),
                label: Text(loc.retry, style: TextStyle(fontSize: 16.sp)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: isDark
                      ? AppColors.textDark
                      : AppColors.textLight,

                  minimumSize: Size(double.infinity, 50.h),

                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16.r),
                  ),
                ),
                onPressed: () async {
                  // Chiamiamo l'inizializzazione
                  await expenseProvider.initialise();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
