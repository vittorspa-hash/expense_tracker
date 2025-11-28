// app.dart
// Configurazione principale dell'applicazione Expense Tracker.
// Gestisce tema, localizzazione, routing e la struttura generale dell'app.

import 'package:expense_tracker/components/auth/auth_wrapper.dart';
import 'package:expense_tracker/models/expense_model.dart';
import 'package:expense_tracker/pages/edit_expense_page.dart';
import 'package:expense_tracker/pages/home_page.dart';
import 'package:expense_tracker/pages/settings_page.dart';
import 'package:expense_tracker/pages/years_page.dart';
import 'package:expense_tracker/pages/new_expense_page.dart';
import 'package:expense_tracker/pages/profile_page.dart';
import 'package:expense_tracker/providers/theme_provider.dart';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';

/// Widget principale dell'app.
/// Configura tema, localizzazione, routing e la pagina iniziale.
/// Utilizza GetMaterialApp per integrare la gestione semplificata dello stato e l'utilizzo delle snackbar.
class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(
      context,
    ); // ottiene il tema corrente

    return GetMaterialApp(
      // Rimuove il banner "debug"
      debugShowCheckedModeBanner: false,

      // Imposta la locale italiana come predefinita
      locale: const Locale('it', 'IT'),

      // Lingue supportate dall'app
      supportedLocales: const [Locale('it', 'IT'), Locale('en', 'US')],

      // Delegati di localizzazione per Material, Cupertino e Widgets
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],

      // Tema chiaro e scuro (con supporto Material 3)
      themeMode: themeProvider.themeMode,
      theme: ThemeData.light(useMaterial3: true),
      darkTheme: ThemeData.dark(useMaterial3: true),

      // Pagina iniziale che gestisce login e flussi di navigazione
      home: const AuthWrapper(),

      // Sistema di routing centralizzato
      onGenerateRoute: (RouteSettings settings) {
        final pageBuilder = <String, WidgetBuilder>{
          HomePage.route: (_) => const HomePage(),
          ProfilePage.route: (_) => const ProfilePage(),
          SettingsPage.route: (_) => const SettingsPage(),
          NewExpensePage.route: (_) => const NewExpensePage(),
          EditExpensePage.route: (_) =>
              EditExpensePage(settings.arguments as ExpenseModel),
          YearsPage.route: (_) => const YearsPage(),
        }[settings.name];

        // Crea e restituisce la route per la schermata richiesta
        return MaterialPageRoute(builder: pageBuilder!);
      },
    );
  }
}