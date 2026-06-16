import 'package:expense_tracker/app.dart';
import 'package:expense_tracker/config/di/riverpod_providers.dart';
import 'package:expense_tracker/config/firebase_options.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// FILE: main.dart
/// DESCRIZIONE: Entry point dell'applicazione. Inizializza Firebase, risolve
/// SharedPreferences una sola volta e la inietta nel ProviderContainer tramite
/// override, rendendo sincroni tutti i provider dipendenti (tema, lingua, valuta,
/// notifiche). Configura la localizzazione in base alla lingua salvata e avvia
/// la UI tramite UncontrolledProviderScope con ScreenUtil per il layout responsive.

void main() async {
  // --- CONFIGURAZIONE AMBIENTE E SISTEMA ---
  // Inizializza binding Flutter, Firebase e blocca l'orientamento in portrait.
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // SharedPreferences viene risolto una sola volta qui e iniettato tramite override:
  // tutti i provider che dipendono da sharedPreferencesProvider diventano sincroni.
  final prefs = await SharedPreferences.getInstance();
  final container = ProviderContainer(
    overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
  );

  // --- CONFIGURAZIONE LOCALIZZAZIONE ---
  // Legge la lingua salvata dal provider (già sincrono) e inizializza
  // la formattazione internazionale di date e numeri per la locale attiva.
  final languageState = container.read(languageNotifierProvider);
  Intl.defaultLocale = languageState.currentLocale.toString();
  await initializeDateFormatting(Intl.defaultLocale, null);

  // --- AVVIO APPLICAZIONE ---
  // Condivide il container con l'albero dei widget tramite UncontrolledProviderScope
  // e configura ScreenUtil con il design size di riferimento (390x844, iPhone 14).
  runApp(
    UncontrolledProviderScope(
      container: container,
      child: ScreenUtilInit(
        designSize: const Size(390, 844),
        minTextAdapt: true,
        splitScreenMode: true,
        builder: (context, child) => const App(),
      ),
    ),
  );
}