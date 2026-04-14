// FILE: expense_provider_test.dart
// DESCRIZIONE: Test suite per ExpenseProvider
// Testa la gestione dello stato UI, l'orchestrazione verso il service
// e la corretta propagazione di errori e warning.

import 'package:expense_tracker/l10n/app_localizations.dart';
import 'package:expense_tracker/models/expense_category.dart';
import 'package:expense_tracker/models/expense_currency.dart';
import 'package:expense_tracker/models/expense_model.dart';
import 'package:expense_tracker/providers/auth_provider.dart';
import 'package:expense_tracker/providers/expense_provider.dart';
import 'package:expense_tracker/providers/notification_provider.dart';
import 'package:expense_tracker/services/expense_service.dart';
import 'package:expense_tracker/utils/repository_failure.dart';
import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

// Genera i mock per le 3 dipendenze del provider
@GenerateMocks([
  AuthProvider,
  NotificationProvider,
  ExpenseService,
  AppLocalizations,
])
import 'expense_provider_test.mocks.dart';

// --- FAKE USER ---
// User di Firebase non è mockabile direttamente con mockito.
// Creiamo un fake minimale con solo i campi usati dal provider (uid).
class FakeUser extends Fake implements User {
  @override
  final String uid;
  FakeUser(this.uid);
}

void main() {
  group('ExpenseProvider Tests', () {
    // --- DIPENDENZE MOCKATE ---
    late MockAuthProvider mockAuthProvider;
    late MockNotificationProvider mockNotificationProvider;
    late MockExpenseService mockExpenseService;
    late MockAppLocalizations mockL10n;

    // --- OGGETTO DA TESTARE ---
    late ExpenseProvider provider;

    // --- DATI DI TEST RIUTILIZZABILI ---
    late FakeUser fakeUser;
    late ExpenseModel sampleExpense;

    setUp(() {
      mockAuthProvider = MockAuthProvider();
      mockNotificationProvider = MockNotificationProvider();
      mockExpenseService = MockExpenseService();
      mockL10n = MockAppLocalizations();

      // Utente fake con uid fisso
      fakeUser = FakeUser('user-123');

      // Spesa di esempio riutilizzabile nei test
      sampleExpense = ExpenseModel(
        uuid: 'expense-uuid-1',
        value: 50.0,
        description: 'Test expense',
        createdOn: DateTime(2024, 6, 15),
        userId: 'user-123',
        currency: ExpenseCurrency.euro,
        exchangeRates: {'EUR': 1.0, 'USD': 1.1, 'GBP': 0.85, 'JPY': 130.0},
        category: ExpenseCategory.food,
      );

      // Stub comuni a tutti i test: currentUser e NotificationProvider getters, l10n
      when(mockAuthProvider.currentUser).thenReturn(fakeUser);
      when(mockNotificationProvider.monthlyLimit).thenReturn(1000.0);
      when(mockNotificationProvider.limitAlertEnabled).thenReturn(false);
      when(mockL10n.warningOfflineCurrencyCreate).thenReturn('Offline warning');

      // Stub per calculateTotals: il provider lo chiama sempre dopo ogni operazione.
      // Ritorniamo zeri perché i calcoli reali sono già testati in ExpenseService e ExpenseCalculator.
      when(
        mockExpenseService.calculateTotals(any, any),
      ).thenReturn(ExpenseTotals(today: 0, week: 0, month: 0, year: 0));

      // Stub per sortExpenses: ritorna la lista invariata (l'ordinamento è già testato)
      when(mockExpenseService.sortExpenses(any, any, any)).thenAnswer(
        (invocation) => invocation.positionalArguments[0] as List<ExpenseModel>,
      );

      // Stub per checkBudgetLimit: ritorna sempre vuoto
      when(
        mockNotificationProvider.checkBudgetLimit(any, any, any),
      ).thenAnswer((_) async {});

      // Creazione del provider con le dipendenze mockate
      provider = ExpenseProvider(
        authProvider: mockAuthProvider,
        notificationProvider: mockNotificationProvider,
        expenseService: mockExpenseService,
      );
    });

    // =================================================================
    // TEST 1: initialise() - Caricamento spese con successo
    // =================================================================
    test(
      'Should load expenses and update list on successful initialise',
      () async {
        // ARRANGE
        // Definiamo cosa restituisce il service quando gli chiediamo le spese.
        // In questo test simuliamo una risposta positiva con una spesa.
        when(
          mockExpenseService.loadUserExpenses(user: fakeUser),
        ).thenAnswer((_) async => [sampleExpense]);

        // ACT
        await provider.initialise();

        // ASSERT
        // La lista deve contenere esattamente la spesa restituita dal service
        expect(provider.expenses, hasLength(1));
        expect(provider.expenses.first.uuid, 'expense-uuid-1');
        // Nessun errore deve essere presente
        expect(provider.errorMessage, isNull);
        // Verifichiamo che il service sia stato chiamato esattamente una volta
        verify(mockExpenseService.loadUserExpenses(user: fakeUser)).called(1);
      },
    );

    // =================================================================
    // TEST 2: initialise() - Gestione RepositoryFailure
    // =================================================================
    test(
      'Should set errorMessage and rethrow on RepositoryFailure during initialise',
      () async {
        // ARRANGE
        // Simuliamo un fallimento del repository (es. Firestore non raggiungibile)
        when(
          mockExpenseService.loadUserExpenses(user: fakeUser),
        ).thenThrow(RepositoryFailure("Firestore unavailable"));

        // ACT + ASSERT
        // Il provider deve rilanciare l'eccezione: usiamo expectLater + throwsA
        // per verificare che il Future completi con un errore
        await expectLater(
          provider.initialise(),
          throwsA(isA<RepositoryFailure>()),
        );

        // Verifichiamo anche lo stato interno dopo l'errore
        expect(provider.errorMessage, isNotNull);
        expect(provider.errorMessage, contains("Firestore unavailable"));
        expect(provider.expenses, isEmpty);
      },
    );

    // =================================================================
    // TEST 3: clear() - Reset completo dello stato
    // =================================================================
    test(
      'Should reset expenses and call calculateTotals with empty list on clear',
      () async {
        // ARRANGE
        when(
          mockExpenseService.loadUserExpenses(user: fakeUser),
        ).thenAnswer((_) async => [sampleExpense]);
        await provider.initialise();
        expect(provider.expenses, hasLength(1)); // precondizione
        clearInteractions(mockExpenseService); // azzera contatore dopo initialise

        // ACT
        provider.clear();

        // ASSERT
        expect(provider.expenses, isEmpty);
        expect(provider.errorMessage, isNull);

        // Verifica che calculateTotals sia stato chiamato con lista VUOTA:
        verify(mockExpenseService.calculateTotals([], any)).called(1);
      },
    );

    // =================================================================
    // TEST 4: clearError() - Reset messaggi di errore e warning
    // =================================================================
    test('Should clear errorMessage and warningMessage on clearError', () async {
      // ARRANGE
      // Provocchiamo un errore tramite initialise() per avere un errorMessage reale
      when(
        mockExpenseService.loadUserExpenses(user: fakeUser),
      ).thenThrow(RepositoryFailure("Some error"));

      await expectLater(
        provider.initialise(),
        throwsA(isA<RepositoryFailure>()),
      );
      expect(provider.errorMessage, isNotNull); // precondizione

      // ACT
      provider.clearError();

      // ASSERT
      expect(provider.errorMessage, isNull);
      expect(provider.warningMessage, isNull);
    });

    // =================================================================
    // TEST 5: notifyListeners() - Notifica UI nelle operazioni principali
    // =================================================================
    test('Should notify listeners during createExpense (loading=true then false)', () async {
      // ARRANGE
      when(
        mockExpenseService.createExpense(
          value: anyNamed('value'),
          description: anyNamed('description'),
          date: anyNamed('date'),
          currency: anyNamed('currency'),
          category: anyNamed('category'),
          user: anyNamed('user'),
        ),
      ).thenAnswer((_) async {
        // Catturiamo lo stato DURANTE l'operazione asincrona
        expect(provider.isLoading, true); // isLoading deve essere true qui
        return CreateExpenseResult(expense: sampleExpense, warning: null);
      });

      when(
        mockExpenseService.checkBudgetStatus(
          expenses: anyNamed('expenses'),
          expenseDate: anyNamed('expenseDate'),
          targetCurrency: anyNamed('targetCurrency'),
          budgetLimit: anyNamed('budgetLimit'),
          alertEnabled: anyNamed('alertEnabled'),
        ),
      ).thenReturn(BudgetCheckResult(shouldNotify: false, currentTotal: 0));

      // Contatore delle notifiche
      int notifyCount = 0;
      provider.addListener(() => notifyCount++);

      // ACT
      await provider.createExpense(
        value: 50.0,
        description: 'Test',
        date: DateTime(2024, 6, 15),
        currencyCode: ExpenseCurrency.euro,
        category: ExpenseCategory.food,
        l10n: mockL10n,
      );

      // ASSERT
      // Almeno 2 notifiche: una con isLoading=true, una nel finally con isLoading=false
      expect(notifyCount, greaterThanOrEqualTo(2));
      // Dopo tutto, isLoading deve essere false
      expect(provider.isLoading, false);
    });

    // =================================================================
    // TEST 6: updateAppCurrency() - Ricalcolo totali solo se valuta cambia
    // =================================================================
    test('Should recalculate totals only when currency actually changes', () {
      // ARRANGE
      // La valuta di default è EUR, quindi passare USD è un cambio reale

      // ACT - cambio reale: EUR → USD
      provider.updateAppCurrency(ExpenseCurrency.usd);

      // ASSERT
      // calculateTotals deve essere stato chiamato esattamente una volta
      verify(mockExpenseService.calculateTotals(any, any)).called(1);

      // ACT - nessun cambio: USD → USD
      provider.updateAppCurrency(ExpenseCurrency.usd);

      // ASSERT
      // calculateTotals NON deve essere chiamato una seconda volta
      verifyNever(mockExpenseService.calculateTotals(any, any));

    });

    // =================================================================
    // TEST 7: createExpense() - Aggiunta spesa alla lista con successo
    // =================================================================
    test('Should add expense to list on successful createExpense', () async {
      // ARRANGE
      when(
        mockExpenseService.createExpense(
          value: anyNamed('value'),
          description: anyNamed('description'),
          date: anyNamed('date'),
          currency: anyNamed('currency'),
          category: anyNamed('category'),
          user: anyNamed('user'),
        ),
      ).thenAnswer(
        (_) async => CreateExpenseResult(expense: sampleExpense, warning: null),
      );

      // Stub per checkBudgetStatus: alert disabilitato, nessuna notifica
      when(
        mockExpenseService.checkBudgetStatus(
          expenses: anyNamed('expenses'),
          expenseDate: anyNamed('expenseDate'),
          targetCurrency: anyNamed('targetCurrency'),
          budgetLimit: anyNamed('budgetLimit'),
          alertEnabled: anyNamed('alertEnabled'),
        ),
      ).thenReturn(BudgetCheckResult(shouldNotify: false, currentTotal: 0));

      // ACT
      await provider.createExpense(
        value: 50.0,
        description: 'Test',
        date: DateTime(2024, 6, 15),
        currencyCode: ExpenseCurrency.euro,
        category: ExpenseCategory.food,
        l10n: mockL10n,
      );

      // ASSERT
      expect(provider.expenses, hasLength(1));
      expect(provider.expenses.first.uuid, sampleExpense.uuid);
      expect(provider.isLoading, false);
      expect(provider.errorMessage, isNull);
    });

    // =================================================================
    // TEST 8: createExpense() - Warning offline settato correttamente
    // =================================================================
    test('Should set warningMessage when service returns a warning', () async {
      // ARRANGE
      // Simuliamo il caso offline: il service crea la spesa ma ritorna un warning
      when(
        mockExpenseService.createExpense(
          value: anyNamed('value'),
          description: anyNamed('description'),
          date: anyNamed('date'),
          currency: anyNamed('currency'),
          category: anyNamed('category'),
          user: anyNamed('user'),
        ),
      ).thenAnswer(
        (_) async => CreateExpenseResult(
          expense: sampleExpense,
          warning: 'offline_currency_create', // warning presente
        ),
      );

      when(
        mockExpenseService.checkBudgetStatus(
          expenses: anyNamed('expenses'),
          expenseDate: anyNamed('expenseDate'),
          targetCurrency: anyNamed('targetCurrency'),
          budgetLimit: anyNamed('budgetLimit'),
          alertEnabled: anyNamed('alertEnabled'),
        ),
      ).thenReturn(BudgetCheckResult(shouldNotify: false, currentTotal: 0));

      // ACT
      await provider.createExpense(
        value: 50.0,
        description: 'Offline expense',
        date: DateTime(2024, 6, 15),
        currencyCode: ExpenseCurrency.euro,
        category: ExpenseCategory.food,
        l10n: mockL10n,
      );

      // ASSERT
      // Il warning deve essere presente (testo localizzato dal mock l10n)
      expect(provider.warningMessage, isNotNull);
      expect(provider.warningMessage, 'Offline warning');
      // La spesa deve essere stata aggiunta comunque
      expect(provider.expenses, hasLength(1));
    });

    // =================================================================
    // TEST 9: createExpense() - Gestione RepositoryFailure
    // =================================================================
    test(
      'Should set errorMessage and not add expense on RepositoryFailure',
      () async {
        // ARRANGE
        when(
          mockExpenseService.createExpense(
            value: anyNamed('value'),
            description: anyNamed('description'),
            date: anyNamed('date'),
            currency: anyNamed('currency'),
            category: anyNamed('category'),
            user: anyNamed('user'),
          ),
        ).thenThrow(RepositoryFailure("Save failed"));

        // ACT
        await provider.createExpense(
          value: 50.0,
          description: 'Failing expense',
          date: DateTime(2024, 6, 15),
          currencyCode: ExpenseCurrency.euro,
          category: ExpenseCategory.food,
          l10n: mockL10n,
        );

        // ASSERT
        expect(provider.errorMessage, isNotNull);
        expect(provider.errorMessage, contains("Save failed"));
        // La spesa NON deve essere stata aggiunta alla lista
        expect(provider.expenses, isEmpty);
        // isLoading deve essere false: verifica che il finally abbia funzionato
        expect(provider.isLoading, false);
      },
    );

    // =================================================================
    // TEST 10: editExpense() - Modifica spesa con successo
    // =================================================================
    test('Should update expense in list on successful editExpense', () async {
      // ARRANGE
      // Prima popoliamo il provider con una spesa tramite initialise()
      when(
        mockExpenseService.loadUserExpenses(user: fakeUser),
      ).thenAnswer((_) async => [sampleExpense]);
      await provider.initialise();
      expect(provider.expenses, hasLength(1)); // precondizione

      final updatedExpense = sampleExpense.copyWith(value: 999.0);

      when(
        mockExpenseService.editExpense(
          sampleExpense,
          value: anyNamed('value'),
          description: anyNamed('description'),
          date: anyNamed('date'),
          currency: anyNamed('currency'),
          category: anyNamed('category'),
          user: anyNamed('user'),
        ),
      ).thenAnswer(
        (_) async => EditExpenseResult(expense: updatedExpense, warning: null),
      );

      when(
        mockExpenseService.checkBudgetStatus(
          expenses: anyNamed('expenses'),
          expenseDate: anyNamed('expenseDate'),
          targetCurrency: anyNamed('targetCurrency'),
          budgetLimit: anyNamed('budgetLimit'),
          alertEnabled: anyNamed('alertEnabled'),
        ),
      ).thenReturn(BudgetCheckResult(shouldNotify: false, currentTotal: 0));

      // ACT
      await provider.editExpense(
        sampleExpense,
        value: 999.0,
        description: 'Updated',
        date: DateTime(2024, 6, 15),
        currencyCode: ExpenseCurrency.euro,
        category: ExpenseCategory.food,
        l10n: mockL10n,
      );

      // ASSERT
      expect(provider.expenses, hasLength(1));
      expect(provider.expenses.first.value, 999.0);
      expect(provider.isLoading, false);
      expect(provider.errorMessage, isNull);
    });

    // =================================================================
    // TEST 11: editExpense() - Warning offline settato correttamente
    // =================================================================
    test(
      'Should set warningMessage when editExpense service returns a warning',
      () async {
        // ARRANGE
        when(
          mockExpenseService.loadUserExpenses(user: fakeUser),
        ).thenAnswer((_) async => [sampleExpense]);
        await provider.initialise();

        when(
          mockL10n.warningOfflineCurrencyEdit,
        ).thenReturn('Offline edit warning');

        final updatedExpense = sampleExpense.copyWith(value: 999.0);

        when(
          mockExpenseService.editExpense(
            sampleExpense,
            value: anyNamed('value'),
            description: anyNamed('description'),
            date: anyNamed('date'),
            currency: anyNamed('currency'),
            category: anyNamed('category'),
            user: anyNamed('user'),
          ),
        ).thenAnswer(
          (_) async => EditExpenseResult(
            expense: updatedExpense,
            warning: 'offline_currency_edit', // warning presente
          ),
        );

        when(
          mockExpenseService.checkBudgetStatus(
            expenses: anyNamed('expenses'),
            expenseDate: anyNamed('expenseDate'),
            targetCurrency: anyNamed('targetCurrency'),
            budgetLimit: anyNamed('budgetLimit'),
            alertEnabled: anyNamed('alertEnabled'),
          ),
        ).thenReturn(BudgetCheckResult(shouldNotify: false, currentTotal: 0));

        // ACT
        await provider.editExpense(
          sampleExpense,
          value: 999.0,
          description: 'Offline edit',
          date: DateTime(2024, 6, 15),
          currencyCode: ExpenseCurrency.euro,
          category: ExpenseCategory.food,
          l10n: mockL10n,
        );

        // ASSERT
        expect(provider.warningMessage, isNotNull);
        expect(provider.warningMessage, 'Offline edit warning');
        // La spesa deve essere stata aggiornata comunque
        expect(provider.expenses.first.value, 999.0);
      },
    );

    // =================================================================
    // TEST 12: editExpense() - Gestione RepositoryFailure
    // =================================================================
    test(
      'Should set errorMessage and keep original expense on RepositoryFailure during editExpense',
      () async {
        // ARRANGE
        // Prima popoliamo il provider con una spesa tramite initialise()
        when(
          mockExpenseService.loadUserExpenses(user: fakeUser),
        ).thenAnswer((_) async => [sampleExpense]);
        await provider.initialise();
        expect(provider.expenses, hasLength(1)); // precondizione

        when(
          mockExpenseService.editExpense(
            sampleExpense,
            value: anyNamed('value'),
            description: anyNamed('description'),
            date: anyNamed('date'),
            currency: anyNamed('currency'),
            category: anyNamed('category'),
            user: anyNamed('user'),
          ),
        ).thenThrow(RepositoryFailure("Edit failed"));

        // ACT
        await provider.editExpense(
          sampleExpense,
          value: 999.0,
          description: 'Updated',
          date: DateTime(2024, 6, 15),
          currencyCode: ExpenseCurrency.euro,
          category: ExpenseCategory.food,
          l10n: mockL10n,
        );

        // ASSERT
        expect(provider.errorMessage, isNotNull);
        expect(provider.errorMessage, contains("Edit failed"));
        // La spesa originale deve essere rimasta invariata
        expect(provider.expenses.first.value, 50.0);
        expect(provider.isLoading, false);
      },
    );

    // =================================================================
    // TEST 13: deleteExpenses() - Rimozione spese dalla lista locale
    // =================================================================
    test(
      'Should remove expenses from list on successful deleteExpenses',
      () async {
        // ARRANGE
        // Prima popoliamo il provider con una spesa tramite initialise()
        when(
          mockExpenseService.loadUserExpenses(user: fakeUser),
        ).thenAnswer((_) async => [sampleExpense]);
        await provider.initialise();
        expect(provider.expenses, hasLength(1)); // precondizione

        // Stub deleteExpense: operazione andata a buon fine (nessuna eccezione)
        when(
          mockExpenseService.deleteExpense(sampleExpense, user: fakeUser),
        ).thenAnswer((_) async {});

        // ACT
        await provider.deleteExpenses([sampleExpense]);

        // ASSERT
        expect(provider.expenses, isEmpty);
        expect(provider.isLoading, false);
        expect(provider.errorMessage, isNull);
      },
    );

    // =================================================================
    // TEST 14: deleteExpenses() - Gestione RepositoryFailure
    // =================================================================
    test(
      'Should set errorMessage and keep expenses on RepositoryFailure during deleteExpenses',
      () async {
        // ARRANGE
        when(
          mockExpenseService.loadUserExpenses(user: fakeUser),
        ).thenAnswer((_) async => [sampleExpense]);
        await provider.initialise();
        expect(provider.expenses, hasLength(1)); // precondizione

        when(
          mockExpenseService.deleteExpense(sampleExpense, user: fakeUser),
        ).thenThrow(RepositoryFailure("Deletion failed"));

        // ACT
        await provider.deleteExpenses([sampleExpense]);

        // ASSERT
        expect(provider.errorMessage, isNotNull);
        expect(provider.errorMessage, contains("Deletion failed"));
        // La spesa NON deve essere stata rimossa dalla lista
        expect(provider.expenses, hasLength(1));
        expect(provider.isLoading, false);
      },
    );

    // =================================================================
    // TEST 15: deleteExpenses() - isLoading true durante l'operazione
    // =================================================================
    test('Should set isLoading to true during deleteExpenses', () async {
      // ARRANGE
      when(
        mockExpenseService.loadUserExpenses(user: fakeUser),
      ).thenAnswer((_) async => [sampleExpense]);
      await provider.initialise();

      when(
        mockExpenseService.deleteExpense(sampleExpense, user: fakeUser),
      ).thenAnswer((_) async {
        // Verifica lo stato intermedio: durante la delete, isLoading deve essere true
        expect(provider.isLoading, true);
      });

      // ACT
      await provider.deleteExpenses([sampleExpense]);

      // ASSERT: dopo l'operazione, isLoading torna false
      expect(provider.isLoading, false);
    });

    // =================================================================
    // TEST 16: restoreExpenses() - Ripristino spese con successo
    // =================================================================
    test(
      'Should add restored expenses to list on successful restoreExpenses',
      () async {
        // ARRANGE
        // Il provider parte con lista vuota (nessun initialise())
        when(
          mockExpenseService.restoreExpense(sampleExpense, user: fakeUser),
        ).thenAnswer((_) async => sampleExpense);

        // Stub per checkBudgetStatusForList
        when(
          mockExpenseService.checkBudgetStatusForList(
            allExpenses: anyNamed('allExpenses'),
            newExpenses: anyNamed('newExpenses'),
            targetCurrency: anyNamed('targetCurrency'),
            budgetLimit: anyNamed('budgetLimit'),
            alertEnabled: anyNamed('alertEnabled'),
          ),
        ).thenReturn(BudgetCheckResult(shouldNotify: false, currentTotal: 0));

        // ACT
        await provider.restoreExpenses([sampleExpense], mockL10n);

        // ASSERT
        expect(provider.expenses, hasLength(1));
        expect(provider.expenses.first.uuid, sampleExpense.uuid);
        expect(provider.isLoading, false);
        expect(provider.errorMessage, isNull);
      },
    );

    // =================================================================
    // TEST 17: restoreExpenses() - Gestione RepositoryFailure
    // =================================================================
    test(
      'Should set errorMessage and not add expenses on RepositoryFailure during restoreExpenses',
      () async {
        // ARRANGE
        when(
          mockExpenseService.restoreExpense(sampleExpense, user: fakeUser),
        ).thenThrow(RepositoryFailure("Unable to restore"));

        // ACT
        await provider.restoreExpenses([sampleExpense], mockL10n);

        // ASSERT
        expect(provider.errorMessage, isNotNull);
        expect(provider.errorMessage, contains("Unable to restore"));
        // La spesa NON deve essere stata aggiunta alla lista
        expect(provider.expenses, isEmpty);
        expect(provider.isLoading, false);
      },
    );

    // =================================================================
    // TEST 18: _checkBudget() - Notifica inviata quando budget superato
    // =================================================================
    test(
      'Should call checkBudgetLimit on notificationProvider when budget is exceeded',
      () async {
        // ARRANGE
        when(
          mockExpenseService.createExpense(
            value: anyNamed('value'),
            description: anyNamed('description'),
            date: anyNamed('date'),
            currency: anyNamed('currency'),
            category: anyNamed('category'),
            user: anyNamed('user'),
          ),
        ).thenAnswer(
          (_) async =>
              CreateExpenseResult(expense: sampleExpense, warning: null),
        );

        // Simuliamo il budget superato
        when(
          mockExpenseService.checkBudgetStatus(
            expenses: anyNamed('expenses'),
            expenseDate: anyNamed('expenseDate'),
            targetCurrency: anyNamed('targetCurrency'),
            budgetLimit: anyNamed('budgetLimit'),
            alertEnabled: anyNamed('alertEnabled'),
          ),
        ).thenReturn(
          BudgetCheckResult(shouldNotify: true, currentTotal: 1200.0),
        );

        // ACT
        await provider.createExpense(
          value: 50.0,
          description: 'Over budget',
          date: DateTime.now(),
          currencyCode: ExpenseCurrency.euro,
          category: ExpenseCategory.food,
          l10n: mockL10n,
        );

        // ASSERT
        // Verifichiamo che la notifica sia stata effettivamente inviata
        verify(
          mockNotificationProvider.checkBudgetLimit(1200.0, any, any),
        ).called(1);
      },
    );

    // =================================================================
    // TEST 19: _checkBudgetForList() - Notifica inviata quando budget superato
    // =================================================================
    test(
      'Should call checkBudgetLimit on notificationProvider when budget is exceeded after restore',
      () async {
        // ARRANGE
        when(
          mockExpenseService.restoreExpense(sampleExpense, user: fakeUser),
        ).thenAnswer((_) async => sampleExpense);

        // Simuliamo il budget superato
        when(
          mockExpenseService.checkBudgetStatusForList(
            allExpenses: anyNamed('allExpenses'),
            newExpenses: anyNamed('newExpenses'),
            targetCurrency: anyNamed('targetCurrency'),
            budgetLimit: anyNamed('budgetLimit'),
            alertEnabled: anyNamed('alertEnabled'),
          ),
        ).thenReturn(
          BudgetCheckResult(shouldNotify: true, currentTotal: 1200.0),
        );

        // ACT
        await provider.restoreExpenses([sampleExpense], mockL10n);

        // ASSERT
        verify(
          mockNotificationProvider.checkBudgetLimit(1200.0, any, any),
        ).called(1);
      },
    );
  });
}
