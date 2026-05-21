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
/// DESCRIZIONE: Root widget dell'applicazione (App). Configura il MaterialApp,
/// la gestione dei temi (Light/Dark), la localizzazione delle lingue e le rotte.
/// Monitora inoltre il ciclo di vita dell'applicazione tramite WidgetsBindingObserver.

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

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Azzera i badge delle notifiche ogni volta che l'app torna in primo piano.
    if (state == AppLifecycleState.resumed) {
      _clearBadge();
    }
  }

  // --- LOGICA DI NOTIFICA ---
  /// Accede al servizio di notifica per azzerare il contatore dei badge.
  /// Sfrutta .requireValue poiché il FutureProvider è stato pre-caricato nel main.dart.
  void _clearBadge() {
    ref.read(notificationServiceProvider).requireValue.clearBadge();
  }

  // --- COSTRUZIONE INTERFACCIA ---
  @override
  Widget build(BuildContext context) {
    // Ascolta reattivamente i cambiamenti di tema e lingua.
    final themeState = ref.watch(themeNotifierProvider);
    final languageState = ref.watch(languageNotifierProvider);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      
      // CONFIGURAZIONE LOCALIZZAZIONE
      locale: languageState.currentLocale,
      supportedLocales: AppLocales.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      
      // CONFIGURAZIONE TEMI E FONT
      themeMode: themeState.themeMode,
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