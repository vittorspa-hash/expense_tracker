import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:expense_tracker/pages/home_page.dart';
import '../../pages/auth_page.dart';
import 'package:expense_tracker/providers/expense_provider.dart';
import 'package:provider/provider.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.idTokenChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final user = snapshot.data;

        if (user == null) {
          final expenseProvider = context.read<ExpenseProvider>();
          Future.microtask(() => expenseProvider.clear());
          return const AuthPage();
        }

        if (!user.emailVerified) {
          return const AuthPage();
        }

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
              return const HomePage();
            }
          },
        );
      },
    );
  }
}
