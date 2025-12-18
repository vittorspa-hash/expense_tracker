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
import 'package:expense_tracker/providers/expense_provider.dart';
import 'package:expense_tracker/providers/multi_select_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  Intl.defaultLocale = "it_IT";
  await initializeDateFormatting("it_IT", null);

  final getIt = GetIt.instance;

  final database = FirebaseRepository();
  getIt.registerSingleton<FirebaseRepository>(database);

  final expenseProvider = ExpenseProvider();
  getIt.registerSingleton<ExpenseProvider>(expenseProvider);

  final settingsProvider = SettingsProvider();
  getIt.registerSingleton<SettingsProvider>(settingsProvider);
  await settingsProvider.initialize();

  final themeProvider = ThemeProvider();
  getIt.registerSingleton<ThemeProvider>(themeProvider);

  final multiSelectProvider = MultiSelectProvider();
  getIt.registerSingleton<MultiSelectProvider>(multiSelectProvider);

  runApp(
    ScreenUtilInit(
      designSize: const Size(375, 812),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: themeProvider),
            ChangeNotifierProvider.value(value: settingsProvider),
            ChangeNotifierProvider.value(value: expenseProvider),
            ChangeNotifierProvider.value(value: multiSelectProvider),
          ],
          child: const App(),
        );
      },
    ),
  );
}
