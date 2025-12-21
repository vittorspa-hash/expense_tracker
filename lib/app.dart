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
import 'package:get_it/get_it.dart';
import 'package:provider/provider.dart';

/// FILE: app.dart
/// DESCRIZIONE: Widget radice dell'applicazione. Configura la struttura base di Flutter (MaterialApp),
/// gestisce i provider globali (Tema), la localizzazione (Italiano), il routing centralizzato
/// e il monitoraggio del ciclo di vita dell'app per la gestione dei badge di notifica.

class App extends StatefulWidget {
  const App({super.key});

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> with WidgetsBindingObserver {
  final NotificationService _notificationService = GetIt.instance<NotificationService>();

  // --- 1. GESTIONE CICLO DI VITA & NOTIFICHE ---
  // Monitora lo stato dell'app (background/foreground) per resettare il badge
  // delle notifiche quando l'utente apre o riprende l'applicazione.

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _notificationService.clearBadge();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _notificationService.clearBadge();
    }
  }

  // --- 2. BUILD E CONFIGURAZIONE GENERALE ---
  // Configurazione di MaterialApp con localizzazione italiana, temi dinamici
  // e gestione della navigazione.

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return MaterialApp(
      debugShowCheckedModeBanner: false,

      // Configurazione Localizzazione (Italiano predefinito)
      locale: const Locale('it', 'IT'),
      supportedLocales: const [Locale('it', 'IT'), Locale('en', 'US')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],

      // Configurazione Tema (gestito da ThemeProvider)
      themeMode: themeProvider.themeMode,
      theme: ThemeData.light(useMaterial3: true),
      darkTheme: ThemeData.dark(useMaterial3: true),

      // AuthWrapper decide se mostrare la Login o la Home
      home: const AuthWrapper(),

      // --- 3. ROUTING MANAGER ---
      // Gestione centralizzata delle rotte. Mappa i nomi delle rotte ai widget
      // e gestisce il passaggio di argomenti (es. per EditExpensePage).
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

        if (builder != null) {
          return MaterialPageRoute(
            builder: builder,
            settings: settings,
          );
        }

        return null;
      },
    );
  }
}