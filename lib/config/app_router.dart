import 'package:expense_tracker/models/expense_model.dart';
import 'package:expense_tracker/pages/days_page.dart';
import 'package:expense_tracker/pages/edit_expense_page.dart';
import 'package:expense_tracker/pages/months_page.dart';
import 'package:expense_tracker/pages/new_expense_page.dart';
import 'package:expense_tracker/pages/profile_page.dart';
import 'package:expense_tracker/pages/settings_page.dart';
import 'package:expense_tracker/pages/years_page.dart';
import 'package:flutter/material.dart';

/// FILE: app_router.dart
/// DESCRIZIONE: Routes di navigazione dell'applicazione.
/// Definisce la gestione delle route principali dell'applicazione.

class AppRouter {
  static Route<dynamic>? onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case ProfilePage.route:
        return MaterialPageRoute(builder: (_) => const ProfilePage());
      case SettingsPage.route:
        return MaterialPageRoute(builder: (_) => const SettingsPage());
      case NewExpensePage.route:
        return MaterialPageRoute(builder: (_) => const NewExpensePage());
      case YearsPage.route:
        return MaterialPageRoute(builder: (_) => const YearsPage());
      case MonthsPage.route:
        final args = settings.arguments as Map<String, int>;
        return MaterialPageRoute(
          builder: (_) => MonthsPage(year: args['year']!, month: args['month']!),
        );
      case DaysPage.route:
        final args = settings.arguments as Map<String, int>;
        return MaterialPageRoute(
          builder: (_) => DaysPage(year: args['year']!, month: args['month']!, day: args['day']!),
        );
      case EditExpensePage.route:
        final expense = settings.arguments as ExpenseModel;
        return MaterialPageRoute(builder: (_) => EditExpensePage(expense));
      default:
        return null;
    }
  }
}