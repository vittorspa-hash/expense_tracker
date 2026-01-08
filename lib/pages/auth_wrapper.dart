import 'package:expense_tracker/pages/auth_page.dart';
import 'package:expense_tracker/theme/app_colors.dart';
import 'package:expense_tracker/utils/repository_failure.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:expense_tracker/pages/home_page.dart';
import 'package:expense_tracker/providers/expense_provider.dart';
import 'package:provider/provider.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart'; 

/// FILE: auth_wrapper.dart
/// DESCRIZIONE: Widget "Gatekeeper" principale dell'applicazione.
/// Ascolta lo stream di autenticazione di Firebase per decidere se mostrare la Login o la Home.
/// Gestisce inoltre l'inizializzazione asincrona dei dati utente (spese) gestendo stati di
/// caricamento ed errori critici (es. connessione assente) con possibilità di retry.

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  // --- STATO ---
  // Cache del Future di inizializzazione. È necessario usare uno StatefulWidget
  // per mantenere il riferimento al Future ed evitare che venga ricreato ad ogni
  // rebuild del widget (loop infinito), permettendo anche la logica di "Riprova".
  Future<void>? _initFuture;

  @override
  void initState() {
    super.initState();
    // L'inizializzazione dei dati (initialise) è differita nel metodo build
    // perché dipende dall'oggetto User che otteniamo dallo StreamBuilder.
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.idTokenChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            body: Center(child: CircularProgressIndicator(color: AppColors.primary)),
          );
        }

        final user = snapshot.data;

        // --- 1. UTENTE NON AUTENTICATO ---
        // Se non c'è un utente, puliamo lo stato del provider per sicurezza
        // e mostriamo la pagina di Autenticazione.
        if (user == null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              context.read<ExpenseProvider>().clear();
            }
          });
          _initFuture = null; 
          return const AuthPage();
        }

        // --- 2. UTENTE NON VERIFICATO ---
        // Blocca l'accesso se l'email non è stata verificata.
        if (!user.emailVerified) {
          _initFuture = null;
          return const AuthPage();
        }

        // --- 3. UTENTE LOGGATO: INIZIALIZZAZIONE DATI ---
        // Se l'utente è valido, avviamo il caricamento dei dati.
        // Usiamo l'operatore ??= per assicurarci che venga chiamato una volta sola.
        _initFuture ??= context.read<ExpenseProvider>().initialise();

        return FutureBuilder(
          future: _initFuture,
          builder: (context, initSnapshot) {
            // A. CARICAMENTO DATI
            if (initSnapshot.connectionState == ConnectionState.waiting) {
              return Scaffold(
                body: Center(child: CircularProgressIndicator(color: AppColors.primary)),
              );
            }

            // B. ERRORE CRITICO DI INIZIALIZZAZIONE
            // Se il caricamento iniziale fallisce (es. server down), mostriamo una schermata
            // di errore bloccante con un pulsante per riprovare.
            if (initSnapshot.hasError) {
              return Scaffold(
                body: Center(
                  child: Padding(
                    padding: EdgeInsets.all(24.r),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 48.sp,
                          color: AppColors.delete,
                        ),
                        SizedBox(height: 16.h),
                        Text(
                          "Ops! Impossibile avviare l'app.",
                          style: TextStyle(
                            fontSize: 20.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 8.h),
                        Text(
                          (initSnapshot.error is RepositoryFailure)
                              ? (initSnapshot.error as RepositoryFailure)
                                    .message
                              : "Controlla la tua connessione e riprova.",
                          textAlign: TextAlign.center,
                          style: TextStyle(color: AppColors.textDark2),
                        ),
                        SizedBox(height: 24.h),
                        ElevatedButton.icon(
                          onPressed: () {
                            setState(() {
                              _initFuture = context
                                  .read<ExpenseProvider>()
                                  .initialise();
                            });
                          },
                          icon: const Icon(Icons.refresh),
                          label: const Text("Riprova"),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }

            // C. SUCCESSO: ACCESSO ALLA HOME
            return const HomePage();
          },
        );
      },
    );
  }
}