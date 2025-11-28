// auth_wrapper.dart
// Gestisce il flusso di autenticazione dell’app.
// Determina se mostrare la schermata di login oppure la HomePage,
// in base allo stato dell’utente e alla verifica dell’email.
// Esegue inoltre l’inizializzazione dei dati locali al primo accesso.

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:expense_tracker/pages/home_page.dart';
import '../../../pages/auth_page.dart';
import 'package:expense_tracker/models/store_model.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      // Ascolta i cambiamenti nel token dell’utente
      // (login, logout, refresh del token)
      stream: FirebaseAuth.instance.idTokenChanges(),
      builder: (context, snapshot) {
        // Mostra un loader mentre la connessione allo stream è in corso
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // Utente autenticato (se presente)
        final user = snapshot.data;

        // Se non autenticato → reindirizza alla pagina di login
        if (user == null) {
          storeModel.value.clear(); // Reset dati locali all’uscita
          return const AuthPage();
        }

        // Se l’email non è ancora verificata → richiede login/verifica
        if (!user.emailVerified) {
          return const AuthPage();
        }

        // Inizializza i dati dell’app prima di caricare la HomePage
        return FutureBuilder(
          future: storeModel.value.initialise(),
          builder: (context, initSnapshot) {
            // Loader durante l’inizializzazione locale
            if (initSnapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }
            // Gestione errori durante l’inizializzazione
            else if (initSnapshot.hasError) {
              return Scaffold(
                body: Center(
                  child: Text('Errore caricamento dati: ${initSnapshot.error}'),
                ),
              );
            }
            // Se tutto ok → accesso alla HomePage
            else {
              return const HomePage();
            }
          },
        );
      },
    );
  }
}
