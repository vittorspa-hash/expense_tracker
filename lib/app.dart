import 'package:expense_tracker/config/app_router.dart';
import 'package:expense_tracker/config/di/riverpod_providers.dart';
import 'package:expense_tracker/config/supported_locales.dart';
import 'package:expense_tracker/l10n/app_localizations.dart';
import 'package:expense_tracker/pages/auth_wrapper.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

class App extends ConsumerStatefulWidget {
  const App({super.key});

  @override
  ConsumerState<App> createState() => _AppState();
}

class _AppState extends ConsumerState<App> with WidgetsBindingObserver {

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
    if (state == AppLifecycleState.resumed) {
      _clearBadge();
    }
  }

  // Legge il service direttamente dal provider Riverpod.
  // Usiamo .requireValue perché il FutureProvider è già risolto
  // prima del runApp in main.dart.
  void _clearBadge() {
    ref.read(notificationServiceProvider).requireValue.clearBadge();
  }

  @override
  Widget build(BuildContext context) {
    // ref.watch al posto di Consumer2 — più semplice e leggibile.
    final themeState = ref.watch(themeNotifierProvider);
    final languageState = ref.watch(languageNotifierProvider);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      locale: languageState.currentLocale,
      supportedLocales: AppLocales.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
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
      home: const AuthWrapper(),
      onGenerateRoute: AppRouter.onGenerateRoute,
    );
  }
}