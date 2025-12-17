// auth_wrapper.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:expense_tracker/pages/home_page.dart';
import '../../pages/auth_page.dart';
import 'package:expense_tracker/providers/expense_provider.dart';
// Aggiunto Provider
import 'package:provider/provider.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    // Recuperiamo lo store una volta per utilizzarlo nei builder sottostanti
    final expense = context.read<ExpenseProvider>();

    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.idTokenChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final user = snapshot.data;

        // Se non autenticato → reset dello store e reindirizzamento al login
        if (user == null) {
          Future.microtask(() => expense.clear());
          return const AuthPage();
        }

        // Se l’email non è ancora verificata → richiede login/verifica
        if (!user.emailVerified) {
          return const AuthPage();
        }

        // Inizializza i dati dell’app dallo store prima di caricare la HomePage
        return FutureBuilder(
          future: expense.initialise(),
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
              return const HomePage();
            }
          },
        );
      },
    );
  }
}
