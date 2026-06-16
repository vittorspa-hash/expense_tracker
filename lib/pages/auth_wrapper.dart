import 'package:expense_tracker/config/di/riverpod_providers.dart';
import 'package:expense_tracker/l10n/app_localizations.dart';
import 'package:expense_tracker/notifiers/auth_notifier.dart';
import 'package:expense_tracker/pages/auth_page.dart';
import 'package:expense_tracker/config/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:expense_tracker/pages/home_page.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// FILE: auth_wrapper.dart
/// DESCRIZIONE: Orchestratore della navigazione principale basato sullo stato reattivo
/// di Riverpod. Osserva authNotifierProvider (StreamNotifier su Firebase) e, una volta
/// autenticato, espande il watch su expenseNotifierProvider per attendere il caricamento
/// dei dati. Gestisce esplicitamente i casi loading, error e data di entrambi i provider,
/// mostrando spinner, schermata di errore con retry, o HomePage a seconda dello stato.

class AuthWrapper extends ConsumerWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // --- STILE E TEMA ---
    // Rilevamento del tema corrente per l'adattamento dinamico dei colori UI.
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // --- STATO DI AUTENTICAZIONE ---
    // authNotifierProvider è uno StreamNotifier: riflette direttamente lo stream
    // Firebase senza essere inquinato dagli stati dei form di autenticazione.
    final authState = ref.watch(authNotifierProvider);

    // --- ROUTING REATTIVO ---
    // Determina la macro-area dell'app in base allo stato di autenticazione,
    // espandendo il watch sulle spese solo dopo l'autenticazione avvenuta.
    return authState.when(
      loading: () => _buildLoadingScreen(),
      error: (e, _) => _buildErrorScreen(
        context: context,
        isDark: isDark,
        onRetry: () => ref.invalidate(authNotifierProvider),
      ),
      data: (auth) {
        switch (auth.authStatus) {
          case AuthStatus.unauthenticated:
          case AuthStatus.unverified:
            return const AuthPage();
          case AuthStatus.authenticated:
            final expenseState = ref.watch(expenseNotifierProvider);
            return expenseState.when(
              loading: () => _buildLoadingScreen(),
              error: (error, _) => _buildErrorScreen(
                context: context,
                isDark: isDark,
                // Invalida il provider per rieseguire build() e ritentare il caricamento
                onRetry: () => ref.invalidate(expenseNotifierProvider),
              ),
              data: (state) {
                // Dati pronti: mostra la HomePage
                return const HomePage();
              },
            );
        }
      },
    );
  }

  // --- COMPONENTI UI PRIVATI ---

  /// Costruisce una schermata di caricamento a tutto schermo.
  Widget _buildLoadingScreen() {
    return Scaffold(
      body: Center(child: CircularProgressIndicator(color: AppColors.primary)),
    );
  }

  /// Costruisce la schermata di errore bloccante con pulsante di ripristino.
  /// Il callback onRetry invalida il provider fallito per rieseguirne la build().
  Widget _buildErrorScreen({
    required BuildContext context,
    required bool isDark,
    required VoidCallback onRetry,
  }) {
    final loc = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      body: Center(
        child: Padding(
          padding: EdgeInsets.all(24.r),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // ICONA DI ERRORE
              Icon(Icons.error_outline, size: 48.sp, color: AppColors.delete),
              SizedBox(height: 16.h),

              // TESTI E MESSAGGI LOCALIZZATI
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
                loc.appInitErrorMessage,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: isDark ? AppColors.greyDark : AppColors.greyLight,
                ),
              ),
              SizedBox(height: 24.h),

              // AZIONE DI RETRY
              ElevatedButton.icon(
                icon: Icon(
                  Icons.refresh,
                  size: 20.sp,
                  color: isDark ? AppColors.textDark : AppColors.textLight,
                ),
                label: Text(loc.retry, style: TextStyle(fontSize: 16.sp)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: isDark ? AppColors.textDark : AppColors.textLight,
                  minimumSize: Size(double.infinity, 50.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16.r),
                  ),
                ),
                onPressed: onRetry,
              ),
            ],
          ),
        ),
      ),
    );
  }
}