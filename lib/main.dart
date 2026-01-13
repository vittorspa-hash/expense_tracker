import 'package:expense_tracker/app.dart';
import 'package:expense_tracker/providers/auth_provider.dart';
import 'package:expense_tracker/providers/currency_provider.dart';
import 'package:expense_tracker/providers/language_provider.dart';
import 'package:expense_tracker/providers/profile_provider.dart';
import 'package:expense_tracker/providers/notification_provider.dart';
import 'package:expense_tracker/providers/theme_provider.dart';
import 'package:expense_tracker/repositories/firebase_repository.dart';
import 'package:expense_tracker/services/auth_service.dart';
import 'package:expense_tracker/services/currency_service.dart';
import 'package:expense_tracker/services/expense_service.dart';
import 'package:expense_tracker/services/language_service.dart';
import 'package:expense_tracker/services/notification_service.dart';
import 'package:expense_tracker/services/profile_service.dart';
import 'package:expense_tracker/services/theme_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get_it/get_it.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'firebase_options.dart';
import 'package:expense_tracker/providers/expense_provider.dart';
import 'package:expense_tracker/providers/multi_select_provider.dart';

/// FILE: main.dart
/// DESCRIZIONE: Entry point dell'applicazione. Gestisce il setup dell'ambiente,
/// la Dependency Injection (GetIt), l'inizializzazione asincrona dei servizi
/// critici e l'avvio della UI con i relativi Provider.

void main() async {
  // --- CONFIGURAZIONE AMBIENTE E SISTEMA ---
  // Inizializza binding Flutter, Firebase, orientamento schermo e localizzazione (IT).
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // --- DEPENDENCY INJECTION (GETIT) ---
  // Registrazione di Repository e Servizi come Singleton (Lazy o immediati).
  final getIt = GetIt.instance;

  getIt.registerLazySingleton<FirebaseRepository>(() => FirebaseRepository());

  getIt.registerLazySingleton<AuthService>(() => AuthService());
  getIt.registerLazySingleton<ProfileService>(() => ProfileService());
  getIt.registerLazySingleton<ExpenseService>(
    () => ExpenseService(firebaseRepository: getIt<FirebaseRepository>()),
  );
  getIt.registerSingleton<NotificationService>(NotificationService());
  getIt.registerSingleton<ThemeService>(ThemeService());
  getIt.registerSingleton<CurrencyService>(CurrencyService());
  getIt.registerSingleton<LanguageService>(LanguageService());

  // --- INIZIALIZZAZIONE SERVIZI ASINCRONI ---
  // Setup di Notification Theme, Currency e Language che devono completarsi prima del rendering UI.
  final notificationProvider = NotificationProvider(
    notificationService: getIt<NotificationService>(),
  );
  await notificationProvider.initialize();

  final themeProvider = ThemeProvider(
    themeService: getIt<ThemeService>(),
  );
  await themeProvider.initialize();

  final currencyProvider = CurrencyProvider(
    currencyService: getIt<CurrencyService>(),
  );
  await currencyProvider.loadCurrency();

  final languageProvider = LanguageProvider(
    languageService: getIt<LanguageService>(),
  );
  await languageProvider.fetchLocale();

  Intl.defaultLocale = languageProvider.currentLocale.toString();
  await initializeDateFormatting(Intl.defaultLocale, null);

  // --- AVVIO APPLICAZIONE ---
  // Configurazione responsive (ScreenUtil) e iniezione dei Provider globali.
  runApp(
    ScreenUtilInit(
      designSize: const Size(375, 812),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return MultiProvider(
          providers: [
            // Provider pre-inizializzati
            ChangeNotifierProvider.value(value: notificationProvider),
            ChangeNotifierProvider.value(value: themeProvider),
            ChangeNotifierProvider.value(value: currencyProvider),
            ChangeNotifierProvider.value(value: languageProvider),

            // Provider dipendenti dai servizi GetIt
            ChangeNotifierProvider(
              create: (_) => AuthProvider(authService: getIt<AuthService>()),
            ),
            ChangeNotifierProvider(
              create: (_) => ProfileProvider(profileService: getIt<ProfileService>()),
            ),
            ChangeNotifierProvider(
              create: (_) => ExpenseProvider(
                expenseService: getIt<ExpenseService>(),
                currencyService: getIt<CurrencyService>(),
                notificationProvider: notificationProvider,
              ),
            ),
            ChangeNotifierProvider(
              create: (_) => MultiSelectProvider(),
            ),
          ],
          child: const App(),
        );
      },
    ),
  );
}