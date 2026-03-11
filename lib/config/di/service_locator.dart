import 'package:expense_tracker/repositories/firebase_repository.dart';
import 'package:expense_tracker/services/auth_service.dart';
import 'package:expense_tracker/services/currency_service.dart';
import 'package:expense_tracker/services/expense_service.dart';
import 'package:expense_tracker/services/language_service.dart';
import 'package:expense_tracker/services/notification_service.dart';
import 'package:expense_tracker/services/profile_service.dart';
import 'package:expense_tracker/services/theme_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get_it/get_it.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// FILE: config/di/service_locator.dart
/// DESCRIZIONE: Configurazione della Dependency Injection tramite GetIt.
/// Registra tutti i Repository e i Service come Singleton o LazySingleton,
/// garantendo un'unica istanza condivisa per l'intero ciclo di vita dell'app.

Future<void> setupGetIt() async {
  final getIt = GetIt.instance;

  // --- DIPENDENZE DI BASE ---
  // SharedPreferences e HttpClient sono registrati per primi poiché rappresentano
  // le dipendenze fondamentali richieste dai Service al momento della loro registrazione.
  final sharedPreferences = await SharedPreferences.getInstance();
  getIt.registerSingleton<SharedPreferences>(sharedPreferences);
  getIt.registerSingleton<http.Client>(http.Client());

  // --- SERVICE SINGLETON ---
  // Servizi che richiedono inizializzazione immediata e dipendono da SharedPreferences.
  // Registrati come Singleton (non lazy) perché necessari prima dell'avvio della UI.
  getIt.registerSingleton<NotificationService>(
    NotificationService(sharedPreferences: getIt<SharedPreferences>()),
  );
  getIt.registerSingleton<ThemeService>(
    ThemeService(sharedPreferences: getIt<SharedPreferences>()),
  );
  getIt.registerSingleton<CurrencyService>(
    CurrencyService(
      sharedPreferences: getIt<SharedPreferences>(),
      httpClient: getIt<http.Client>(),
    ),
  );
  getIt.registerSingleton<LanguageService>(
    LanguageService(sharedPreferences: getIt<SharedPreferences>()),
  );

  // --- SERVICE LAZY SINGLETON ---
  // Repository e Service legati a Firebase registrati come LazySingleton:
  // vengono istanziati solo al primo utilizzo, ottimizzando il tempo di avvio.
  getIt.registerLazySingleton<FirebaseRepository>(() => FirebaseRepository());
  getIt.registerLazySingleton<FirebaseAuth>(() => FirebaseAuth.instance);

  getIt.registerLazySingleton<AuthService>(
    () => AuthService(firebaseAuth: getIt<FirebaseAuth>()),
  );
  getIt.registerLazySingleton<ProfileService>(
    () => ProfileService(firebaseAuth: getIt<FirebaseAuth>()),
  );
  getIt.registerLazySingleton<ExpenseService>(
    () => ExpenseService(
      currencyService: getIt<CurrencyService>(),
      firebaseRepository: getIt<FirebaseRepository>(),
      firebaseAuth: getIt<FirebaseAuth>(),
    ),
  );
}