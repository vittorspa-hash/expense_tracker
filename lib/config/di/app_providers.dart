import 'package:expense_tracker/providers/auth_provider.dart';
import 'package:expense_tracker/providers/currency_provider.dart';
import 'package:expense_tracker/providers/expense_provider.dart';
import 'package:expense_tracker/providers/language_provider.dart';
import 'package:expense_tracker/providers/multi_select_provider.dart';
import 'package:expense_tracker/providers/notification_provider.dart';
import 'package:expense_tracker/providers/profile_provider.dart';
import 'package:expense_tracker/providers/theme_provider.dart';
import 'package:expense_tracker/services/auth_service.dart';
import 'package:expense_tracker/services/currency_service.dart';
import 'package:expense_tracker/services/expense_service.dart';
import 'package:expense_tracker/services/language_service.dart';
import 'package:expense_tracker/services/notification_service.dart';
import 'package:expense_tracker/services/profile_service.dart';
import 'package:expense_tracker/services/theme_service.dart';
import 'package:get_it/get_it.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

/// FILE: config/di/app_providers.dart
/// DESCRIZIONE: Gestione centralizzata dell'inizializzazione e dell'iniezione dei Provider.
/// Espone tre elementi principali:
/// - [InitializedProviders]: Data class che raggruppa i Provider pre-inizializzati.
/// - [initProviders]: Inizializza asincronamente i Provider che richiedono setup prima della UI.
/// - [buildProviders]: Costruisce la lista completa dei Provider da iniettare nel MultiProvider.

// --- DATA CLASS ---
// Contenitore per i Provider che richiedono inizializzazione asincrona prima dell'avvio
// della UI. Viene istanziato da initProviders() e passato a buildProviders().
class InitializedProviders {
  final NotificationProvider notificationProvider;
  final ThemeProvider themeProvider;
  final CurrencyProvider currencyProvider;
  final LanguageProvider languageProvider;

  const InitializedProviders({
    required this.notificationProvider,
    required this.themeProvider,
    required this.currencyProvider,
    required this.languageProvider,
  });
}

// --- INIZIALIZZAZIONE PROVIDER ASINCRONI ---
// Istanzia e inizializza i Provider che dipendono da operazioni async
// prima che la UI venga renderizzata. Configura inoltre il locale
// globale per la formattazione di date e numeri tramite il pacchetto intl.
Future<InitializedProviders> initProviders() async {
  final getIt = GetIt.instance;

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

  // Sincronizza il locale globale di intl con la preferenza salvata dall'utente,
  // garantendo formattazione coerente di date e numeri in tutta l'app.
  Intl.defaultLocale = languageProvider.currentLocale.toString();
  await initializeDateFormatting(Intl.defaultLocale, null);

  return InitializedProviders(
    notificationProvider: notificationProvider,
    themeProvider: themeProvider,
    currencyProvider: currencyProvider,
    languageProvider: languageProvider,
  );
}

// --- COSTRUZIONE LISTA PROVIDER ---
// Assembla la lista completa dei ChangeNotifierProvider da passare al MultiProvider in main.dart.
// I Provider pre-inizializzati vengono iniettati tramite .value() per preservare le istanze
// già configurate. I Provider lazy vengono invece creati direttamente tramite GetIt.
List<SingleChildWidget> buildProviders(InitializedProviders initialized) {
  final getIt = GetIt.instance;

  return [
    // Provider pre-inizializzati: istanze già pronte, passate direttamente.
    ChangeNotifierProvider.value(value: initialized.notificationProvider),
    ChangeNotifierProvider.value(value: initialized.themeProvider),
    ChangeNotifierProvider.value(value: initialized.currencyProvider),
    ChangeNotifierProvider.value(value: initialized.languageProvider),

    // Provider lazy: istanziati al primo accesso tramite GetIt.
    ChangeNotifierProvider(
      create: (_) => AuthProvider(authService: getIt<AuthService>()),
    ),
    ChangeNotifierProvider(
      create: (_) => ProfileProvider(profileService: getIt<ProfileService>()),
    ),
    ChangeNotifierProvider(
      create: (_) => ExpenseProvider(
        expenseService: getIt<ExpenseService>(),
        notificationProvider: initialized.notificationProvider,
      ),
    ),
    ChangeNotifierProvider(create: (_) => MultiSelectProvider()),
  ];
}