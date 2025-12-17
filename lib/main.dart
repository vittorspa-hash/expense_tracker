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
import 'package:expense_tracker/providers/expense_provider.dart'; // Importa lo store
import 'package:expense_tracker/providers/multi_select_provider.dart'; // Importa il provider selezione

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  Intl.defaultLocale = "it_IT";
  await initializeDateFormatting("it_IT", null);

  final getIt = GetIt.instance;

  // Repository Firebase
  final database = FirebaseRepository();
  getIt.registerSingleton<FirebaseRepository>(database);

  // REGISTRAZIONE EXPENSE STORE in GetIt
  final expenseProvider = ExpenseProvider();
  getIt.registerSingleton<ExpenseProvider>(expenseProvider);

  // Settings Provider
  final settingsProvider = SettingsProvider();
  getIt.registerSingleton<SettingsProvider>(settingsProvider);
  await settingsProvider.initialize();

  runApp(
    ScreenUtilInit(
      designSize: const Size(375, 812),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => ThemeProvider()),
            ChangeNotifierProvider.value(value: settingsProvider),

            // AGGIUNTA EXPENSE STORE
            ChangeNotifierProvider.value(value: expenseProvider),

            // AGGIUNTA MULTI SELECT PROVIDER
            ChangeNotifierProvider(create: (_) => MultiSelectProvider()),
          ],
          child: const App(),
        );
      },
    ),
  );
}
