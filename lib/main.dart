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

/// FILE: main.dart
/// DESCRIZIONE: Entry point dell'applicazione. Gestisce il setup dell'ambiente,
/// l'inizializzazione di Firebase, la creazione del ProviderContainer di Riverpod
/// per il pre-caricamento dei servizi asincroni, la localizzazione dell'app
/// e l'avvio della UI tramite UncontrolledProviderScope.

void main() async {
  // --- CONFIGURAZIONE AMBIENTE E SISTEMA ---
  // Inizializza binding Flutter, Firebase e orientamento schermo in portrait.
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // --- INIZIALIZZAZIONE RIVERPOD CONTAINER ---
  // Crea il container globale per accedere ai provider prima del build della UI.
  final container = ProviderContainer();

  // --- PRE-CARICAMENTO SERVIZI ASINCRONI ---
  // Attende il caricamento iniziale dei futuri associati ai servizi core.
  await Future.wait([
    container.read(notificationServiceProvider.future),
    container.read(themeServiceProvider.future),
    container.read(currencyServiceProvider.future),
    container.read(languageServiceProvider.future),
  ]);

  // --- INIZIALIZZAZIONE NOTIFIER ---
  // Esegue il setup e il caricamento dei dati nei rispettivi Notifier dello stato.
  await container.read(notificationNotifierProvider.notifier).initialize();
  await container.read(themeNotifierProvider.notifier).initialize();
  await container.read(currencyNotifierProvider.notifier).loadCurrency();
  await container.read(languageNotifierProvider.notifier).fetchLocale();

  // --- CONFIGURAZIONE LOCALIZZAZIONE ---
  // Recupera la locale corrente dallo stato e configura la formattazione internazionale.
  final languageState = container.read(languageNotifierProvider);
  Intl.defaultLocale = languageState.currentLocale.toString();
  await initializeDateFormatting(Intl.defaultLocale, null);

  // --- AVVIO APPLICAZIONE ---
  // Condivide il container di Riverpod con l'albero dei widget e configura ScreenUtil per la UI responsive.
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