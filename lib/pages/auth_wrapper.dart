import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:expense_tracker/pages/home_page.dart';
import '../../pages/auth_page.dart';
import 'package:expense_tracker/providers/expense_provider.dart';
import 'package:provider/provider.dart';

/// FILE: auth_wrapper.dart
/// DESCRIZIONE: Widget "Gatekeeper" che gestisce il routing iniziale basato sullo stato
/// di autenticazione di Firebase. Ascolta lo stream dell'utente, gestisce l'inizializzazione
/// dei dati se loggato, o reindirizza alla pagina di login se disconnesso.

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    // --- GESTIONE STREAM AUTENTICAZIONE ---
    // Monitora in tempo reale i cambiamenti dello stato di auth (login/logout/token).
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.idTokenChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final user = snapshot.data;

        // --- UTENTE NON AUTENTICATO ---
        // Se l'utente è null, pulisce i dati della sessione precedente (sicurezza)
        // e reindirizza alla pagina di Login/Registrazione.
        if (user == null) {
          final expenseProvider = context.read<ExpenseProvider>();
          // Microtask evita conflitti di stato durante il rendering
          Future.microtask(() => expenseProvider.clear());
          return const AuthPage();
        }

        // --- VERIFICA EMAIL ---
        // Blocca l'accesso alla home se l'email non è verificata.
        if (!user.emailVerified) {
          return const AuthPage();
        }

        // --- INIZIALIZZAZIONE DATI ---
        // Se autenticato e verificato, avvia il caricamento delle spese dal provider.
        // Un FutureBuilder gestisce l'attesa del fetch dei dati prima di mostrare la Home.
        final initFuture = context.read<ExpenseProvider>().initialise();

        return FutureBuilder(
          future: initFuture,
          builder: (context, initSnapshot) {
            if (initSnapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            } else if (initSnapshot.hasError) {
              return Scaffold(
                body: Center(
                  child: Text('Errore caricamento dati: ${initSnapshot.error}'),
                ),
              );
            } else {
              // Caricamento completato con successo
              return const HomePage();
            }
          },
        );
      },
    );
  }
}