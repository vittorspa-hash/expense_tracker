import 'package:expense_tracker/app.dart';
import 'package:expense_tracker/providers/settings_provider.dart';
import 'package:expense_tracker/providers/theme_provider.dart';
import 'package:expense_tracker/repositories/firebase_repository.dart';
import 'package:expense_tracker/services/auth_service.dart';
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

  // Registrazione in GetIt solo dei repository/servizi
  final getIt = GetIt.instance;

  getIt.registerLazySingleton<FirebaseRepository>(() => FirebaseRepository());
  getIt.registerLazySingleton<AuthService>(() => AuthService());
  getIt.registerLazySingleton<ProfileService>(() => ProfileService());
  getIt.registerSingleton<NotificationService>(NotificationService());

  // Inizializzazione dei provider che aggiornano la UI
  final settingsProvider = SettingsProvider();
  await settingsProvider.initialize();

  runApp(
    ScreenUtilInit(
      designSize: const Size(375, 812),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: settingsProvider),
            ChangeNotifierProvider(create: (_) => ThemeProvider()),
            ChangeNotifierProvider(create: (_) => ExpenseProvider()),
            ChangeNotifierProvider(create: (_) => MultiSelectProvider()),
          ],
          child: const App(),
        );
      },
    ),
  );
}
