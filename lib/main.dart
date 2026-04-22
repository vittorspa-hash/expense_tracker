import 'package:expense_tracker/app.dart';
import 'package:expense_tracker/config/di/app_providers.dart';
import 'package:expense_tracker/config/di/service_locator.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'config/firebase_options.dart';

/// FILE: main.dart
/// DESCRIZIONE: Entry point dell'applicazione. Gestisce il setup dell'ambiente,
/// l'inizializzazione di Firebase, la Dependency Injection (GetIt) tramite
/// service_locator.dart, i Provider tramite app_providers.dart e l'avvio dell'app.

void main() async {
  // --- CONFIGURAZIONE AMBIENTE E SISTEMA ---
  // Inizializza binding Flutter, Firebase e orientamento schermo.
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // --- DEPENDENCY INJECTION E PROVIDER ---
  // Registra tutti i servizi e repository su GetIt, poi inizializza i Provider
  // che richiedono setup asincrono prima del rendering della UI.
  await setupGetIt();
  final initialized = await initProviders();

  // --- AVVIO APPLICAZIONE ---
  // Configurazione responsive (ScreenUtil) e iniezione dei Provider globali.
  runApp(
    ScreenUtilInit(
      designSize: const Size(390, 844),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return MultiProvider(
          providers: buildProviders(initialized),
          child: const App(),
        );
      },
    ),
  );
}