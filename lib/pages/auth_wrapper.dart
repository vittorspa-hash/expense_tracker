import 'package:expense_tracker/config/di/riverpod_providers.dart';
import 'package:expense_tracker/l10n/app_localizations.dart';
import 'package:expense_tracker/pages/auth_page.dart';
import 'package:expense_tracker/config/app_colors.dart';
import 'package:expense_tracker/notifiers/auth_notifier.dart';
import 'package:expense_tracker/utils/repository_failure.dart';
import 'package:flutter/material.dart';
import 'package:expense_tracker/pages/home_page.dart';
import 'package:expense_tracker/notifiers/expense_notifier.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// FILE: auth_wrapper.dart
/// DESCRIZIONE: Orchestratore della navigazione principale.
/// Gestisce il flusso di accesso basandosi su due stati:
/// 1. Lo stato di autenticazione dell'utente (Firebase Auth).
/// 2. Lo stato di inizializzazione dei dati (Firestore).
/// Utilizza una logica reattiva per mostrare la pagina di Login, lo spinner di caricamento,
/// la schermata di errore o l'applicazione vera e propria (HomePage).

class AuthWrapper extends ConsumerWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // --- STILE E TEMA ---
    // Rilevamento del tema corrente per l'adattamento dinamico dei colori UI.
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // --- RECOVERY STATI (RIVERPOD) ---
    // Ascolto reattivo degli stati di autenticazione e delle spese.
    final authState = ref.watch(authNotifierProvider);
    final expenseState = ref.watch(expenseNotifierProvider);

    // --- GESTIONE FLUSSO DI AUTENTICAZIONE ---
    // Determina la macro-area dell'app in base alla sessione utente.
    switch (authState.authStatus) {
      case AuthStatus.unknown:
        // Stato di transizione iniziale di Firebase Auth all'avvio dell'app.
        return _buildLoadingScreen();

      case AuthStatus.unauthenticated:
      case AuthStatus.unverified:
        // Utente non autenticato o non verificato: reset del notifier e redirect al login.
        WidgetsBinding.instance.addPostFrameCallback((_) {
          ref.read(expenseNotifierProvider.notifier).clear();
        });
        return const AuthPage();

      case AuthStatus.authenticated:
        // --- GESTIONE INIZIALIZZAZIONE DATI ---
        // Ad autenticazione avvenuta, orchestrerà il caricamento dei dati da Firestore.
        switch (expenseState.initStatus) {
          case ExpenseInitStatus.initial:
            // Avvia il fetch automatico dei dati utente al primo accesso valido.
            WidgetsBinding.instance.addPostFrameCallback(
              (_) => ref.read(expenseNotifierProvider.notifier).initialise(),
            );
            return _buildLoadingScreen();

          case ExpenseInitStatus.loading:
            // Schermata di attesa durante il caricamento di spese, tassi di cambio e categorie.
            return _buildLoadingScreen();

          case ExpenseInitStatus.error:
            // Intercettazione di fallimenti critici nel recupero dei dati.
            return _buildErrorScreen(
              context,
              ref,
              expenseState.initError,
              isDark,
            );

          case ExpenseInitStatus.initialized:
            // Inizializzazione completata con successo: sblocco della dashboard.
            return const HomePage();
        }
    }
  }

  // --- COMPONENTI UI PRIVATI ---

  /// Costruisce una schermata di caricamento a tutto schermo.
  Widget _buildLoadingScreen() {
    return Scaffold(
      body: Center(child: CircularProgressIndicator(color: AppColors.primary)),
    );
  }

  /// Costruisce la schermata di errore bloccante con pulsante di ripristino.
  Widget _buildErrorScreen(
    BuildContext context,
    WidgetRef ref,
    Object? error,
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
                (error is RepositoryFailure)
                    ? error.message
                    : loc.appInitErrorMessage,
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
                  foregroundColor: isDark
                      ? AppColors.textDark
                      : AppColors.textLight,
                  minimumSize: Size(double.infinity, 50.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16.r),
                  ),
                ),
                onPressed: () async {
                  // Tenta nuovamente l'inizializzazione del notifier dello stato delle spese.
                  await ref.read(expenseNotifierProvider.notifier).initialise();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}