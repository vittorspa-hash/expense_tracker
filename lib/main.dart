import 'package:expense_tracker/app.dart';
import 'package:expense_tracker/config/di/riverpod_providers.dart';
import 'package:expense_tracker/config/firebase_options.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  final container = ProviderContainer();

  await Future.wait([
    container.read(notificationServiceProvider.future),
    container.read(themeServiceProvider.future),
    container.read(currencyServiceProvider.future),
    container.read(languageServiceProvider.future),
  ]);

  await container.read(notificationNotifierProvider.notifier).initialize();
  await container.read(themeNotifierProvider.notifier).initialize();
  await container.read(currencyNotifierProvider.notifier).loadCurrency();
  await container.read(languageNotifierProvider.notifier).fetchLocale();

  final languageState = container.read(languageNotifierProvider);
  Intl.defaultLocale = languageState.currentLocale.toString();
  await initializeDateFormatting(Intl.defaultLocale, null);

  runApp(
    UncontrolledProviderScope(
      container: container,
      child: ScreenUtilInit(
        designSize: const Size(390, 844),
        minTextAdapt: true,
        splitScreenMode: true,
        builder: (context, child) => const App(),
      ),
    ),
  );
}