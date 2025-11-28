// main.dart
// Punto di ingresso dell'app Expense Tracker.
// Inizializza Firebase, imposta la localizzazione italiana e configura
// i servizi principali (repository, preferenze, notifiche).

import 'package:expense_tracker/app.dart';
import 'package:expense_tracker/providers/settings_provider.dart';
import 'package:expense_tracker/providers/theme_provider.dart';
import 'package:expense_tracker/repositories/firebase_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get_it/get_it.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'firebase_options.dart';

/// Funzione principale dell'applicazione.
/// - Assicura l'inizializzazione dei binding Flutter.
/// - Blocca l'orientamento in verticale.
/// - Avvia Firebase e la localizzazione.
/// - Registra il repository dati e settings provider tramite GetIt.
/// - Prepara la struttura base dell'app tramite `ScreenUtilInit` e i provider.
void main() async {
  // Garantisce che i binding di Flutter siano inizializzati prima del codice asincrono
  WidgetsFlutterBinding.ensureInitialized();

  // 🔒 Limita l'app all'orientamento verticale (portrait)
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  // 🔥 Inizializza Firebase con la configurazione generata automaticamente
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // 🇮🇹 Imposta l'italiano come lingua di default e carica la formattazione delle date
  Intl.defaultLocale = "it_IT";
  await initializeDateFormatting("it_IT", null);

  // 🔹 SERVICE LOCATOR (GetIt)
  final getIt = GetIt.instance;

  // Registra il repository Firebase
  final database = FirebaseRepository();
  getIt.registerSingleton<FirebaseRepository>(database);

  // 🔔 Registra e inizializza SettingsProvider
  final settingsProvider = SettingsProvider();
  getIt.registerSingleton<SettingsProvider>(settingsProvider);

  // Inizializza le notifiche e carica le preferenze
  await settingsProvider.initialize();

  // 🚀 Avvia l'app usando ScreenUtil per la responsività del layout
  runApp(
    ScreenUtilInit(
      designSize: const Size(375, 812),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return MultiProvider(
          providers: [
            // ✅ ThemeProvider con caricamento tema
            ChangeNotifierProvider(create: (_) => ThemeProvider()),
            // ✅ SettingsProvider già inizializzato
            ChangeNotifierProvider.value(value: settingsProvider),
          ],
          child: const App(),
        );
      },
    ),
  );
}
