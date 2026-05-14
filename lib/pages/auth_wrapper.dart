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
    // Rilevamento del tema corrente per l'adattamento dinamico dei colori UI.
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Ascolto degli stati dai provider tramite context.watch.
    final authState = ref.watch(authNotifierProvider);
    final expenseState = ref.watch(expenseNotifierProvider);

    // --- LOGICA DI AUTENTICAZIONE ---
    // Determina la macro-area dell'app in base alla sessione utente.
    switch (authState.authStatus) {
      case AuthStatus.unknown:
        // Stato di transizione di Firebase Auth all'avvio.
        return _buildLoadingScreen();

      case AuthStatus.unauthenticated:
      case AuthStatus.unverified:
        // Utente non loggato: pulizia del provider e reindirizzamento al login.
        WidgetsBinding.instance.addPostFrameCallback((_) {
          ref.read(expenseNotifierProvider.notifier).clear();
        });
        return const AuthPage();

      case AuthStatus.authenticated:
        // --- LOGICA DI INIZIALIZZAZIONE DATI ---
        // Una volta autenticato, gestisce il caricamento dei dati utente.
        switch (expenseState.initStatus) {
          case ExpenseInitStatus.initial:
            // Trigger automatico del caricamento dati al primo accesso autenticato.
            WidgetsBinding.instance.addPostFrameCallback(
              (_) => ref.read(expenseNotifierProvider.notifier).initialise(),
            );
            return _buildLoadingScreen();

          case ExpenseInitStatus.loading:
            // Visualizzazione progresso durante il fetch dei dati (Firestore/Cambi).
            return _buildLoadingScreen();

          case ExpenseInitStatus.error:
            // Gestione dei fallimenti critici durante l'avvio.
            return _buildErrorScreen(
              context,
              ref,
              expenseState.initError,
              isDark,
            );

          case ExpenseInitStatus.initialized:
            // Successo: accesso garantito alla dashboard principale.
            return const HomePage();
        }
    }
  }

  // --- COMPONENTI UI PRIVATI ---

  // Schermata di caricamento standardizzata per le fasi di transizione.
  Widget _buildLoadingScreen() {
    return Scaffold(
      body: Center(child: CircularProgressIndicator(color: AppColors.primary)),
    );
  }

  // Schermata di errore persistente con opzione di ripristino manuale.
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
              // Feedback visivo dell'errore.
              Icon(Icons.error_outline, size: 48.sp, color: AppColors.delete),
              SizedBox(height: 16.h),

              // Titolo dell'errore localizzato.
              Text(
                loc.appInitErrorTitle,
                style: TextStyle(
                  fontSize: 20.sp,
                  fontWeight: FontWeight.bold,
                  color: isDark ? AppColors.textLight : AppColors.textDark,
                ),
              ),
              SizedBox(height: 8.h),

              // Descrizione dettagliata: estrae il messaggio se l'errore è un RepositoryFailure.
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

              // Azione di Retry: tenta nuovamente l'inizializzazione del provider.
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
                  minimumSize: Size(
                    double.infinity,
                    50.h,
                  ), // Layout full-width per accessibilità.
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16.r),
                  ),
                ),
                onPressed: () async {
                  // Esegue nuovamente la logica di inizializzazione definita nel Provider.
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
