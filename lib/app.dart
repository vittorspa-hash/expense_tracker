// app.dart
// Configurazione principale dell'applicazione Expense Tracker.
// Gestisce tema, localizzazione, routing e la struttura generale dell'app.

import 'package:expense_tracker/pages/auth_wrapper.dart';
import 'package:expense_tracker/models/expense_model.dart';
import 'package:expense_tracker/pages/edit_expense_page.dart';
import 'package:expense_tracker/pages/home_page.dart';
import 'package:expense_tracker/pages/settings_page.dart';
import 'package:expense_tracker/pages/years_page.dart';
import 'package:expense_tracker/pages/new_expense_page.dart';
import 'package:expense_tracker/pages/profile_page.dart';
import 'package:expense_tracker/providers/theme_provider.dart';
import 'package:expense_tracker/services/notification_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

/// Widget principale dell'app.
/// Configura tema, localizzazione, routing e la pagina iniziale tramite Provider.
class App extends StatefulWidget {
  const App({super.key});

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> with WidgetsBindingObserver {
  final NotificationService _notificationService = NotificationService();

  @override
  void initState() {
    super.initState();
    // Aggiungi observer per monitorare il ciclo di vita dell'app
    WidgetsBinding.instance.addObserver(this);
    // Resetta il badge delle notifiche all'avvio
    _notificationService.clearBadge();
  }

  @override
  void dispose() {
    // Rimuovi observer per evitare memory leak
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Quando l'app torna in primo piano, resetta il badge
    if (state == AppLifecycleState.resumed) {
      _notificationService.clearBadge();
    }
  }

  @override
  Widget build(BuildContext context) {
    // Ascolta i cambiamenti del tema tramite Provider
    final themeProvider = Provider.of<ThemeProvider>(context);

    return MaterialApp(
      debugShowCheckedModeBanner: false,

      // Configurazione Localizzazione Italiana
      locale: const Locale('it', 'IT'),
      supportedLocales: const [Locale('it', 'IT'), Locale('en', 'US')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],

      // Gestione dinamica del tema
      themeMode: themeProvider.themeMode,
      theme: ThemeData.light(useMaterial3: true),
      darkTheme: ThemeData.dark(useMaterial3: true),

      // Punto di ingresso che gestisce lo stato dell'autenticazione
      home: const AuthWrapper(),

      // Navigazione centralizzata con gestione sicura degli errori
      onGenerateRoute: (RouteSettings settings) {
        final Map<String, WidgetBuilder> routes = {
          HomePage.route: (_) => const HomePage(),
          ProfilePage.route: (_) => const ProfilePage(),
          SettingsPage.route: (_) => const SettingsPage(),
          NewExpensePage.route: (_) => const NewExpensePage(),
          EditExpensePage.route: (_) =>
              EditExpensePage(settings.arguments as ExpenseModel),
          YearsPage.route: (_) => const YearsPage(),
        };

        final WidgetBuilder? builder = routes[settings.name];

        // Se la rotta esiste, restituisce la pagina, altrimenti ritorna null
        // permettendo a Flutter di gestire rotte sconosciute
        if (builder != null) {
          return MaterialPageRoute(
            builder: builder,
            settings:
                settings, // Passa i settings per mantenere traccia dei nomi rotta
          );
        }

        return null;
      },
    );
  }
}
