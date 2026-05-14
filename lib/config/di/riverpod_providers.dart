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

// =============================================================================
// LAYER 1 — INFRASTRUCTURE
// =============================================================================

final sharedPreferencesProvider = FutureProvider<SharedPreferences>((
  ref,
) async {
  return await SharedPreferences.getInstance();
});

final httpClientProvider = Provider<http.Client>((ref) {
  final client = http.Client();
  ref.onDispose(() => client.close());
  return client;
});

final firebaseAuthProvider = Provider<FirebaseAuth>((ref) {
  return FirebaseAuth.instance;
});

// =============================================================================
// LAYER 2 — REPOSITORY
// =============================================================================

final firebaseRepositoryProvider = Provider<FirebaseRepository>((ref) {
  return FirebaseRepository();
});

// =============================================================================
// LAYER 3 — SERVICES
// =============================================================================

final notificationServiceProvider = FutureProvider<NotificationService>((
  ref,
) async {
  final prefs = await ref.watch(sharedPreferencesProvider.future);
  return NotificationService(sharedPreferences: prefs);
});

final themeServiceProvider = FutureProvider<ThemeService>((ref) async {
  final prefs = await ref.watch(sharedPreferencesProvider.future);
  return ThemeService(sharedPreferences: prefs);
});

final currencyServiceProvider = FutureProvider<CurrencyService>((ref) async {
  final prefs = await ref.watch(sharedPreferencesProvider.future);
  final client = ref.watch(httpClientProvider);
  return CurrencyService(sharedPreferences: prefs, httpClient: client);
});

final languageServiceProvider = FutureProvider<LanguageService>((ref) async {
  final prefs = await ref.watch(sharedPreferencesProvider.future);
  return LanguageService(sharedPreferences: prefs);
});

final authServiceProvider = Provider<AuthService>((ref) {
  final auth = ref.watch(firebaseAuthProvider);
  return AuthService(firebaseAuth: auth);
});

final profileServiceProvider = Provider<ProfileService>((ref) {
  final auth = ref.watch(firebaseAuthProvider);
  return ProfileService(firebaseAuth: auth);
});

final expenseServiceProvider = Provider<ExpenseService>((ref) {
  final currencyService = ref.watch(currencyServiceProvider).requireValue;
  final repository = ref.watch(firebaseRepositoryProvider);
  return ExpenseService(
    currencyService: currencyService,
    firebaseRepository: repository,
  );
});

// =============================================================================
// LAYER 4 — NOTIFIER PROVIDERS (UI State)
// NotifierProvider<Notifier, State> sostituisce ChangeNotifierProvider.
// La sintassi è: NotifierProvider<NomeNotifier, NomeSato>(() => NomeNotifier())
// =============================================================================

final notificationNotifierProvider =
    NotifierProvider<NotificationNotifier, NotificationState>(
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

final multiSelectNotifierProvider =
    NotifierProvider<MultiSelectNotifier, MultiSelectState>(
      () => MultiSelectNotifier(),
    );

// =============================================================================
// LAYER 5 — PROVIDER DERIVATI PER GRAFICI
// Si aggiornano automaticamente ogni volta che expenseProvider cambia,
// garantendo rebuild reattivi nelle pagine dei grafici.
// =============================================================================

final expensesByMonthProvider = Provider<Map<String, double>>((ref) {
  final state = ref.watch(expenseNotifierProvider);
  final service = ref.read(expenseServiceProvider);
  return service.getExpensesByMonth(state.expenses, state.appCurrency);
});

// Questo è un provider che restituisce una funzione, perché richiede parametri.
// Il widget chiama: ref.watch(expensesByDayProvider)(year, month)
final expensesByDayProvider = Provider<Map<String, double> Function(int, int)>((
  ref,
) {
  final state = ref.watch(expenseNotifierProvider);
  final service = ref.read(expenseServiceProvider);
  return (year, month) =>
      service.getExpensesByDay(state.expenses, year, month, state.appCurrency);
});

final expensesOfDayProvider =
    Provider<List<ExpenseModel> Function(int, int, int)>((ref) {
      final state = ref.watch(expenseNotifierProvider);
      final service = ref.read(expenseServiceProvider);
      return (year, month, day) =>
          service.getExpensesOfDay(state.expenses, year, month, day);
    });

final expensesByCategoryForYearProvider =
    Provider<Map<ExpenseCategory, double> Function(String)>((ref) {
      final state = ref.watch(expenseNotifierProvider);
      final service = ref.read(expenseServiceProvider);
      return (year) => service.getExpensesByCategoryForYear(
        state.expenses,
        year,
        state.appCurrency,
      );
    });
