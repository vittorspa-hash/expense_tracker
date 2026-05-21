import 'package:expense_tracker/models/expense_category.dart';
import 'package:expense_tracker/models/expense_model.dart';
import 'package:expense_tracker/notifiers/auth_notifier.dart';
import 'package:expense_tracker/notifiers/currency_notifier.dart';
import 'package:expense_tracker/notifiers/expense_notifier.dart';
import 'package:expense_tracker/notifiers/language_notifier.dart';
import 'package:expense_tracker/notifiers/multi_select_notifier.dart';
import 'package:expense_tracker/notifiers/notification_notifier.dart';
import 'package:expense_tracker/notifiers/profile_notifier.dart';
import 'package:expense_tracker/notifiers/theme_notifier.dart';
import 'package:expense_tracker/repositories/firebase_repository.dart';
import 'package:expense_tracker/services/auth_service.dart';
import 'package:expense_tracker/services/currency_service.dart';
import 'package:expense_tracker/services/expense_service.dart';
import 'package:expense_tracker/services/language_service.dart';
import 'package:expense_tracker/services/notification_service.dart';
import 'package:expense_tracker/services/profile_service.dart';
import 'package:expense_tracker/services/theme_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// FILE: riverpod_providers.dart
/// DESCRIZIONE: Hub centrale della Dependency Injection dell'applicazione tramite Riverpod.
/// Organizza i componenti in 5 layer architetturali (Infrastructure, Repository, Services,
/// Notifier Providers e Provider Derivati) gestendo le dipendenze in modo reattivo e sicuro.

// --- LAYER 1: INFRASTRUCTURE ---
// Fornisce le istanze delle librerie esterne e dei servizi di sistema core.

/// Carica in modo asincrono le SharedPreferences per la persistenza locale.
final sharedPreferencesProvider = FutureProvider<SharedPreferences>((ref) async {
  return await SharedPreferences.getInstance();
});

/// Fornisce e gestisce il ciclo di vita del client HTTP.
final httpClientProvider = Provider<http.Client>((ref) {
  final client = http.Client();
  ref.onDispose(() => client.close());
  return client;
});

/// Espone l'istanza core di FirebaseAuth.
final firebaseAuthProvider = Provider<FirebaseAuth>((ref) {
  return FirebaseAuth.instance;
});

// --- LAYER 2: REPOSITORY ---
// Gestisce l'interfacciamento diretto e l'accesso ai dati della sorgente remota.

/// Fornisce l'istanza del repository Firebase.
final firebaseRepositoryProvider = Provider<FirebaseRepository>((ref) {
  return FirebaseRepository();
});

// --- LAYER 3: SERVICES ---
// Logica di business dell'applicazione che consuma i dati del Layer 1 e 2.

/// Servizio asincrono per la gestione delle notifiche locali e push.
final notificationServiceProvider = FutureProvider<NotificationService>((ref) async {
  final prefs = await ref.watch(sharedPreferencesProvider.future);
  return NotificationService(sharedPreferences: prefs);
});

/// Servizio asincrono per il salvataggio e recupero delle preferenze del tema grafico.
final themeServiceProvider = FutureProvider<ThemeService>((ref) async {
  final prefs = await ref.watch(sharedPreferencesProvider.future);
  return ThemeService(sharedPreferences: prefs);
});

/// Servizio asincrono per la conversione e gestione dei tassi di cambio.
final currencyServiceProvider = FutureProvider<CurrencyService>((ref) async {
  final prefs = await ref.watch(sharedPreferencesProvider.future);
  final client = ref.watch(httpClientProvider);
  return CurrencyService(sharedPreferences: prefs, httpClient: client);
});

/// Servizio asincrono per il cambio lingua e la persistenza della locale.
final languageServiceProvider = FutureProvider<LanguageService>((ref) async {
  final prefs = await ref.watch(sharedPreferencesProvider.future);
  return LanguageService(sharedPreferences: prefs);
});

/// Servizio per la gestione dei flussi di autenticazione dell'utente.
final authServiceProvider = Provider<AuthService>((ref) {
  final auth = ref.watch(firebaseAuthProvider);
  return AuthService(firebaseAuth: auth);
});

/// Servizio per la lettura e aggiornamento dei dati del profilo utente.
final profileServiceProvider = Provider<ProfileService>((ref) {
  final auth = ref.watch(firebaseAuthProvider);
  return ProfileService(firebaseAuth: auth);
});

/// Servizio per la manipolazione, calcolo e sincronizzazione delle spese.
final expenseServiceProvider = Provider<ExpenseService>((ref) {
  final currencyService = ref.watch(currencyServiceProvider).requireValue;
  final repository = ref.watch(firebaseRepositoryProvider);
  return ExpenseService(
    currencyService: currencyService,
    firebaseRepository: repository,
  );
});

// --- LAYER 4: NOTIFIER PROVIDERS (UI STATE) ---
// Gestiscono lo stato dell'interfaccia utente tramite l'architettura Notifier di Riverpod.

final notificationNotifierProvider = NotifierProvider<NotificationNotifier, NotificationState>(
  () => NotificationNotifier(),
);

final themeNotifierProvider = NotifierProvider<ThemeNotifier, ThemeState>(
  () => ThemeNotifier(),
);

final currencyNotifierProvider = NotifierProvider<CurrencyNotifier, CurrencyState>(
  () => CurrencyNotifier(),
);

final languageNotifierProvider = NotifierProvider<LanguageNotifier, LanguageState>(
  () => LanguageNotifier(),
);

final profileNotifierProvider = NotifierProvider<ProfileNotifier, ProfileState>(
  () => ProfileNotifier(),
);

final authNotifierProvider = NotifierProvider<AuthNotifier, AuthState>(
  () => AuthNotifier(),
);

final expenseNotifierProvider = NotifierProvider<ExpenseNotifier, ExpenseState>(
  () => ExpenseNotifier(),
);

final multiSelectNotifierProvider = NotifierProvider<MultiSelectNotifier, MultiSelectState>(
  () => MultiSelectNotifier(),
);

// --- LAYER 5: PROVIDER DERIVATI ---
// Provider in sola lettura dedicati al filtraggio e calcolo dei dati per i grafici e le statistiche.

/// Calcola automaticamente il totale delle spese raggruppate per mese.
final expensesByMonthProvider = Provider<Map<String, double>>((ref) {
  final state = ref.watch(expenseNotifierProvider);
  final service = ref.read(expenseServiceProvider);
  return service.getExpensesByMonth(state.expenses, state.appCurrency);
});

/// Restituisce una funzione parametrica per ottenere le spese raggruppate per giorno di un determinato mese/anno.
final expensesByDayProvider = Provider<Map<String, double> Function(int, int)>((ref) {
  final state = ref.watch(expenseNotifierProvider);
  final service = ref.read(expenseServiceProvider);
  return (year, month) =>
      service.getExpensesByDay(state.expenses, year, month, state.appCurrency);
});

/// Restituisce una funzione parametrica per filtrare la lista delle spese effettuate in un giorno specifico.
final expensesOfDayProvider = Provider<List<ExpenseModel> Function(int, int, int)>((ref) {
  final state = ref.watch(expenseNotifierProvider);
  final service = ref.read(expenseServiceProvider);
  return (year, month, day) =>
      service.getExpensesOfDay(state.expenses, year, month, day);
});

/// Restituisce una funzione parametrica per aggregare i totali delle spese suddivisi per categoria in un dato anno.
final expensesByCategoryForYearProvider = Provider<Map<ExpenseCategory, double> Function(String)>((ref) {
  final state = ref.watch(expenseNotifierProvider);
  final service = ref.read(expenseServiceProvider);
  return (year) => service.getExpensesByCategoryForYear(
    state.expenses,
    year,
    state.appCurrency,
  );
});