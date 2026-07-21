import 'package:expense_tracker/models/expense_category.dart';
import 'package:expense_tracker/models/expense_model.dart';
import 'package:expense_tracker/notifiers/auth_notifier.dart';
import 'package:expense_tracker/notifiers/currency_notifier.dart';
import 'package:expense_tracker/notifiers/expense_notifier.dart';
import 'package:expense_tracker/notifiers/language_notifier.dart';
import 'package:expense_tracker/notifiers/multi_select_notifier.dart';
import 'package:expense_tracker/notifiers/navigation_notifier.dart';
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
import 'package:expense_tracker/utils/expense_calculator.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// FILE: riverpod_providers.dart
/// DESCRIZIONE: Hub centrale della Dependency Injection dell'applicazione tramite Riverpod.
/// Organizza i componenti in 5 layer architetturali: Infrastructure, Repository, Services,
/// Notifier Providers e Provider Derivati. sharedPreferencesProvider viene risolto una sola
/// volta in main.dart tramite override sul ProviderContainer, rendendo sincroni tutti i
/// provider dei layer superiori che vi dipendono.

// --- LAYER 1: INFRASTRUCTURE ---
// Fornisce le istanze delle librerie esterne e dei servizi di sistema core.

/// Placeholder che deve essere obbligatoriamente sovrascritto in main.dart tramite
/// ProviderContainer override; lancia UnimplementedError se usato senza override.
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('Must be overridden in main()');
});

/// Fornisce e gestisce il ciclo di vita del client HTTP; chiude la connessione al dispose.
final httpClientProvider = Provider<http.Client>((ref) {
  final client = http.Client();
  ref.onDispose(() => client.close());
  return client;
});

/// Espone l'istanza singleton di FirebaseAuth.
final firebaseAuthProvider = Provider<FirebaseAuth>((ref) {
  return FirebaseAuth.instance;
});

// --- LAYER 2: REPOSITORY ---
// Gestisce l'interfacciamento diretto e l'accesso ai dati della sorgente remota (Firestore).

/// Fornisce l'istanza del repository Firebase per le operazioni CRUD sulle spese.
final firebaseRepositoryProvider = Provider<FirebaseRepository>((ref) {
  return FirebaseRepository();
});

// --- LAYER 3: SERVICES ---
// Logica di business dell'applicazione; consuma le dipendenze dei Layer 1 e 2.

/// Servizio per la gestione delle notifiche locali, badge e preferenze di promemoria.
final notificationServiceProvider = Provider<NotificationService>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return NotificationService(sharedPreferences: prefs);
});

/// Servizio per il salvataggio e recupero della preferenza del tema grafico (Light/Dark).
final themeServiceProvider = Provider<ThemeService>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return ThemeService(sharedPreferences: prefs);
});

/// Servizio per la conversione degli importi e la gestione dei tassi di cambio via HTTP.
final currencyServiceProvider = Provider<CurrencyService>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  final client = ref.watch(httpClientProvider);
  return CurrencyService(sharedPreferences: prefs, httpClient: client);
});

/// Servizio per il cambio lingua e la persistenza della locale selezionata.
final languageServiceProvider = Provider<LanguageService>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return LanguageService(sharedPreferences: prefs);
});

/// Servizio che incapsula la logica di autenticazione Firebase (signIn, signUp, signOut, ecc.).
final authServiceProvider = Provider<AuthService>((ref) {
  final auth = ref.watch(firebaseAuthProvider);
  return AuthService(firebaseAuth: auth);
});

/// Servizio per la lettura e aggiornamento dei dati del profilo utente su Firebase.
final profileServiceProvider = Provider<ProfileService>((ref) {
  final auth = ref.watch(firebaseAuthProvider);
  return ProfileService(firebaseAuth: auth);
});

/// Servizio per la manipolazione, calcolo dei totali e sincronizzazione delle spese con Firestore.
final expenseServiceProvider = Provider<ExpenseService>((ref) {
  final currencyService = ref.watch(currencyServiceProvider);
  final repository = ref.watch(firebaseRepositoryProvider);
  return ExpenseService(
    currencyService: currencyService,
    firebaseRepository: repository,
  );
});

// --- LAYER 4: NOTIFIER PROVIDERS (UI STATE) ---
// Gestiscono lo stato dell'interfaccia utente tramite l'architettura Notifier di Riverpod.
// I Notifier sincroni (Notifier) dipendono indirettamente da SharedPreferences già risolto;
// i Notifier asincroni (AsyncNotifier, StreamNotifier) gestiscono operazioni I/O o stream.

final notificationNotifierProvider =
    NotifierProvider<NotificationNotifier, NotificationState>(
      () => NotificationNotifier(),
    );

final themeNotifierProvider = NotifierProvider<ThemeNotifier, ThemeState>(
  () => ThemeNotifier(),
);

final currencyNotifierProvider =
    NotifierProvider<CurrencyNotifier, CurrencyState>(() => CurrencyNotifier());

final languageNotifierProvider =
    NotifierProvider<LanguageNotifier, LanguageState>(() => LanguageNotifier());

final profileNotifierProvider =
    AsyncNotifierProvider<ProfileNotifier, ProfileState>(
      () => ProfileNotifier(),
    );

final authNotifierProvider = StreamNotifierProvider<AuthNotifier, AuthState>(
  () => AuthNotifier(),
);

/// Flag "di flusso UI" per l'autenticazione: true dal tap del bottone
/// fino al termine dell'intera interazione (incluso l'eventuale dialog finale).
/// Distinto da AuthState.isLoading, che copre solo la chiamata di rete.
final authFlowBusyProvider = StateProvider<bool>((ref) => false);

final expenseNotifierProvider =
    AsyncNotifierProvider<ExpenseNotifier, ExpenseState>(
      () => ExpenseNotifier(),
    );

final multiSelectNotifierProvider =
    NotifierProvider<MultiSelectNotifier, MultiSelectState>(
      () => MultiSelectNotifier(),
    );

final navigationNotifierProvider = NotifierProvider<NavigationNotifier, int>(
  () => NavigationNotifier(),
);

// --- LAYER 5: PROVIDER DERIVATI ---
// Provider in sola lettura che derivano dati filtrati o aggregati da expenseNotifierProvider
// per alimentare grafici e statistiche, senza duplicare la logica nei widget.

/// Calcola il totale delle spese raggruppate per mese nella valuta corrente dell'app.
final expensesByMonthProvider = Provider<Map<String, double>>((ref) {
  final state = ref.watch(expenseNotifierProvider).value ?? ExpenseState();
  return ExpenseCalculator.expensesByMonth(state.expenses, state.appCurrency);
});

/// Restituisce una funzione parametrica per aggregare le spese per giorno
/// dato un anno e un mese specifici.
final expensesByDayProvider = Provider<Map<String, double> Function(int, int)>((
  ref,
) {
  final state = ref.watch(expenseNotifierProvider).value ?? ExpenseState();
  return (year, month) => ExpenseCalculator.expensesByDay(
    state.expenses,
    year,
    month,
    state.appCurrency,
  );
});

/// Restituisce una funzione parametrica per filtrare le spese effettuate
/// in un giorno specifico (anno, mese, giorno).
final expensesOfDayProvider =
    Provider<List<ExpenseModel> Function(int, int, int)>((ref) {
      final state = ref.watch(expenseNotifierProvider).value ?? ExpenseState();
      return (year, month, day) =>
          ExpenseCalculator.expensesOfDay(state.expenses, year, month, day);
    });

/// Restituisce una funzione parametrica per aggregare i totali per categoria
/// in un anno specifico, nella valuta corrente dell'app.
final expensesByCategoryForYearProvider =
    Provider<Map<ExpenseCategory, double> Function(String)>((ref) {
      final state = ref.watch(expenseNotifierProvider).value ?? ExpenseState();
      return (year) => ExpenseCalculator.expensesByCategoryForYear(
        state.expenses,
        year,
        state.appCurrency,
      );
    });
