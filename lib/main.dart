import 'package:expense_tracker/app.dart';
import 'package:expense_tracker/providers/auth_provider.dart';
import 'package:expense_tracker/providers/profile_provider.dart';
import 'package:expense_tracker/providers/settings_provider.dart';
import 'package:expense_tracker/providers/theme_provider.dart';
import 'package:expense_tracker/repositories/firebase_repository.dart';
import 'package:expense_tracker/services/auth_service.dart';
import 'package:expense_tracker/services/expense_service.dart';
import 'package:expense_tracker/services/notification_service.dart';
import 'package:expense_tracker/services/profile_service.dart';
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

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  Intl.defaultLocale = "it_IT";
  await initializeDateFormatting("it_IT", null);

  // Registrazione in GetIt di repository e servizi
  final getIt = GetIt.instance;

  // Repository (singleton perché gestisce connessione Firebase)
  getIt.registerLazySingleton<FirebaseRepository>(() => FirebaseRepository());

  // Services (lazy singleton - istanziati solo quando necessari)
  getIt.registerLazySingleton<AuthService>(() => AuthService());
  getIt.registerLazySingleton<ProfileService>(() => ProfileService());
  getIt.registerLazySingleton<ExpenseService>(
    () => ExpenseService(firebaseRepository: getIt<FirebaseRepository>()),
  );

  // NotificationService come singleton normale (deve essere inizializzato subito)
  getIt.registerSingleton<NotificationService>(NotificationService());

  // Inizializzazione SettingsProvider (DEVE essere fuori perché ha await)
  final settingsProvider = SettingsProvider(
    notificationService: getIt<NotificationService>(),
  );
  await settingsProvider.initialize();

  // Inizializzazione ThemeProvider (DEVE essere fuori perché ha await)
  final themeProvider = ThemeProvider();
  await themeProvider.initialize();

  runApp(
    ScreenUtilInit(
      designSize: const Size(375, 812),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return MultiProvider(
          providers: [
            // SettingsProvider usa .value() perché già inizializzato fuori
            ChangeNotifierProvider.value(value: settingsProvider),

            // ThemeProvider usa .value() perché già inizializzato fuori
            ChangeNotifierProvider.value(value: themeProvider),

            // AuthProvider
            ChangeNotifierProvider(
              create: (_) => AuthProvider(authService: getIt<AuthService>()),
            ),

            // ProfileProvider
            ChangeNotifierProvider(
              create: (_) =>
                  ProfileProvider(profileService: getIt<ProfileService>()),
            ),

            // ExpenseProvider (dipende da SettingsProvider)
            ChangeNotifierProvider(
              create: (_) => ExpenseProvider(
                settingsProvider: settingsProvider,
                expenseService: getIt<ExpenseService>(),
              ),
            ),

            // MultiSelectProvider (dipende da ExpenseProvider)
            ChangeNotifierProvider(
              create: (context) => MultiSelectProvider(
                expenseProvider: context.read<ExpenseProvider>(),
              ),
            ),
          ],
          child: const App(),
        );
      },
    ),
  );
}
