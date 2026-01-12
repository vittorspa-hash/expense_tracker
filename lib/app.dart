import 'package:expense_tracker/l10n/app_localizations.dart';
import 'package:expense_tracker/pages/auth_wrapper.dart';
import 'package:expense_tracker/models/expense_model.dart';
import 'package:expense_tracker/pages/edit_expense_page.dart';
import 'package:expense_tracker/pages/home_page.dart';
import 'package:expense_tracker/pages/settings_page.dart';
import 'package:expense_tracker/pages/years_page.dart';
import 'package:expense_tracker/pages/new_expense_page.dart';
import 'package:expense_tracker/pages/profile_page.dart';
import 'package:expense_tracker/providers/language_provider.dart'; 
import 'package:expense_tracker/providers/theme_provider.dart';
import 'package:expense_tracker/services/notification_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:get_it/get_it.dart';
import 'package:provider/provider.dart';

/// FILE: app.dart
/// DESCRIZIONE: Widget radice (Root) dell'applicazione.
/// Si occupa della configurazione globale della MaterialApp, includendo:
/// - Gestione dei Temi (Chiaro/Scuro) tramite Provider.
/// - Configurazione della Localizzazione (Lingue supportate e delegati).
/// - Gestione del Routing (Navigazione tra pagine).
/// - Monitoraggio del ciclo di vita dell'app per la gestione delle notifiche.

class App extends StatefulWidget {
  const App({super.key});

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> with WidgetsBindingObserver {
  // --- DIPENDENZE ---
  final NotificationService _notificationService = GetIt.instance<NotificationService>();

  // --- CICLO DI VITA WIDGET ---
  // Registra l'observer per rilevare quando l'app va in background o torna attiva.
  // Pulisce il badge delle notifiche all'avvio.
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _notificationService.clearBadge();
  }

  // Rimuove l'observer quando il widget viene distrutto per evitare memory leak.
  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // --- CICLO DI VITA APP ---
  // Metodo triggerato dal sistema operativo al cambio di stato dell'applicazione.
  // Se l'app viene ripresa (Resumed), resetta il contatore delle notifiche sull'icona.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _notificationService.clearBadge();
    }
  }

  // --- BUILD UI ---
  @override
  Widget build(BuildContext context) {
    // Utilizza Consumer2 per ascoltare contemporaneamente i cambiamenti di Tema e Lingua
    // e ricostruire l'intera MaterialApp di conseguenza.
    return Consumer2<ThemeProvider, LanguageProvider>(
      builder: (context, themeProvider, languageProvider, child) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,

          // --- CONFIGURAZIONE LOCALIZZAZIONE ---
          // Imposta la lingua corrente basandosi sullo stato del LanguageProvider.
          locale: languageProvider.currentLocale, 
          
          // Definisce le lingue ufficialmente supportate dall'applicazione.
          supportedLocales: const [
            Locale('it'),
            Locale('en'),
            Locale('fr'),
            Locale('es'),
          ],

          // Configura i delegati necessari per la traduzione dei widget Material, Cupertino
          // e delle stringhe personalizzate (AppLocalizations).
          localizationsDelegates: const [
            AppLocalizations.delegate, 
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],

          // --- CONFIGURAZIONE TEMA ---
          themeMode: themeProvider.themeMode,
          theme: ThemeData.light(useMaterial3: true),
          darkTheme: ThemeData.dark(useMaterial3: true),

          // --- PUNTO D'INGRESSO ---
          home: const AuthWrapper(),

          // --- GESTIONE ROUTING ---
          // Gestisce la navigazione nominativa e il passaggio di argomenti complessi
          // (come ExpenseModel per la pagina di modifica).
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
      },
    );
  }
}