import 'package:expense_tracker/config/app_router.dart';
import 'package:expense_tracker/config/di/riverpod_providers.dart';
import 'package:expense_tracker/config/supported_locales.dart';
import 'package:expense_tracker/l10n/app_localizations.dart';
import 'package:expense_tracker/pages/auth_wrapper.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

/// FILE: app.dart
/// DESCRIZIONE: Root widget dell'applicazione (App). Configura il MaterialApp
/// con tema (Light/Dark), localizzazione e rotte. Utilizza ConsumerStatefulWidget
/// per osservare reattivamente themeNotifierProvider e languageNotifierProvider,
/// entrambi sincroni grazie all'iniezione di SharedPreferences in main.dart.
/// Monitora il ciclo di vita tramite WidgetsBindingObserver per azzerare
/// i badge delle notifiche al ritorno in primo piano.
class App extends ConsumerStatefulWidget {
  const App({super.key});

  @override
  ConsumerState<App> createState() => _AppState();
}

class _AppState extends ConsumerState<App> with WidgetsBindingObserver {
  // --- CICLO DI VITA E OBSERVER ---
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _clearBadge();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// Azzera i badge delle notifiche ogni volta che l'app torna in primo piano.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _clearBadge();
    }
  }

  // --- LOGICA DI NOTIFICA ---
  /// Delega la pulizia del badge a NotificationService tramite ref.read,
  /// in quanto è un'azione puntuale non legata al ciclo di build.
  void _clearBadge() async {
    final service = ref.read(notificationServiceProvider);
    service.clearBadge();
  }

  // --- COSTRUZIONE INTERFACCIA ---
  @override
  Widget build(BuildContext context) {
    // Osserva reattivamente tema e lingua: entrambi sincroni, nessun AsyncValue da gestire.
    final themeState = ref.watch(themeNotifierProvider);
    final languageState = ref.watch(languageNotifierProvider);
    final themeMode = themeState.themeMode;
    final locale = languageState.currentLocale;

    return MaterialApp(
      debugShowCheckedModeBanner: false,

      // CONFIGURAZIONE LOCALIZZAZIONE
      locale: locale,
      supportedLocales: AppLocales.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],

      // CONFIGURAZIONE TEMI E FONT
      themeMode: themeMode,
      theme: ThemeData.light(useMaterial3: true).copyWith(
        textTheme: GoogleFonts.plusJakartaSansTextTheme(
          ThemeData.light(useMaterial3: true).textTheme,
        ),
      ),
      darkTheme: ThemeData.dark(useMaterial3: true).copyWith(
        textTheme: GoogleFonts.plusJakartaSansTextTheme(
          ThemeData.dark(useMaterial3: true).textTheme,
        ),
      ),

      // CONFIGURAZIONE ROTTE E NAVIGAZIONE
      home: const AuthWrapper(),
      onGenerateRoute: AppRouter.onGenerateRoute,
    );
  }
}