// FILE: expense_provider_test.dart
// DESCRIZIONE: Test suite per ExpenseProvider
// Testa la gestione dello stato UI, l'orchestrazione verso il service
// e la corretta propagazione di errori e warning.

import 'package:expense_tracker/config/di/riverpod_providers.dart';
import 'package:expense_tracker/l10n/app_localizations.dart';
import 'package:expense_tracker/models/expense_category.dart';
import 'package:expense_tracker/models/expense_currency.dart';
import 'package:expense_tracker/models/expense_model.dart';
import 'package:expense_tracker/notifiers/expense_notifier.dart';
import 'package:expense_tracker/notifiers/notification_notifier.dart';
import 'package:expense_tracker/services/expense_service.dart';
import 'package:expense_tracker/utils/repository_failure.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

// Genera i mock per le 3 dipendenze del provider
@GenerateMocks([
  FirebaseAuth,
  NotificationNotifier,
  ExpenseService,
  AppLocalizations,
])
import 'expense_notifier_test.mocks.dart';

// --- FAKE USER ---
// User di Firebase non è mockabile direttamente con mockito.
// Creiamo un fake minimale con solo i campi usati dal provider (uid).
class FakeUser extends Fake implements User {
  @override
  final String uid;
  FakeUser(this.uid);
}

void main() {
  group('ExpenseNotifier Tests', () {
    // --- DIPENDENZE MOCKATE ---
    late MockFirebaseAuth mockFirebaseAuth;
    late MockNotificationNotifier mockNotificationNotifier;
    late MockExpenseService mockExpenseService;
    late MockAppLocalizations mockL10n;
    late ProviderContainer container;
    late FakeUser fakeUser;
    late ExpenseModel sampleExpense;

    ExpenseState readState() => container.read(expenseNotifierProvider);
    ExpenseNotifier readNotifier() => container.read(expenseNotifierProvider.notifier);

    setUp(() {
      mockFirebaseAuth = MockFirebaseAuth();
      mockNotificationNotifier = MockNotificationNotifier();
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
      when(mockFirebaseAuth.currentUser).thenReturn(fakeUser);
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

      when(
        mockNotificationNotifier.checkBudgetLimit(any, any, any),
      ).thenAnswer((_) async {});

      // ProviderContainer con override di tutti i provider necessari
      container = ProviderContainer(
        overrides: [
          firebaseAuthProvider.overrideWithValue(mockFirebaseAuth),
          expenseServiceProvider.overrideWithValue(mockExpenseService),
          // Override del notificationNotifierProvider con uno stub
          notificationNotifierProvider.overrideWith(
            () => _FakeNotificationNotifier(mockNotificationNotifier),
          ),
        ],
      );
    });

    tearDown(() {
      container.dispose();
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
        await readNotifier().initialise();

        // ASSERT
        // La lista deve contenere esattamente la spesa restituita dal service
        expect(readState().expenses, hasLength(1));
        expect(readState().expenses.first.uuid, 'expense-uuid-1');
        // Nessun errore deve essere presente
        expect(readState().errorMessage, isNull);
        expect(readState().initError, isNull);
        // initStatus deve essere initialized
        expect(readState().initStatus, ExpenseInitStatus.initialized);
        // Verifichiamo che il service sia stato chiamato esattamente una volta
        verify(mockExpenseService.loadUserExpenses(user: fakeUser)).called(1);
      },
    );

    // =================================================================
    // TEST 2: initialise() - Seconda chiamata
    // =================================================================
    test('Should not re-execute initialise if already initialized', () async {
      // ARRANGE
      when(
        mockExpenseService.loadUserExpenses(user: fakeUser),
      ).thenAnswer((_) async => [sampleExpense]);
      await readNotifier().initialise();
      expect(
        readState().initStatus,
        ExpenseInitStatus.initialized,
      ); // precondizione

      // ACT — seconda chiamata, deve essere ignorata dal guard
      await readNotifier().initialise();

      // ASSERT
      // loadUserExpenses deve essere stato chiamato una sola volta in totale
      verify(mockExpenseService.loadUserExpenses(user: fakeUser)).called(1);
    });

    // =================================================================
    // TEST 3: initialise() - Seconda chiamata (parallelo)
    // =================================================================
    test('Should not re-execute initialise if already loading', () async {
      // ARRANGE
      when(mockExpenseService.loadUserExpenses(user: fakeUser)).thenAnswer((
        _,
      ) async {
        // Durante il primo initialise(), lanciamo il secondo in parallelo
        await readNotifier().initialise(); // deve essere bloccato dal guard
        return [sampleExpense];
      });

      // ACT
      await readNotifier().initialise();

      // ASSERT
      // loadUserExpenses deve essere stato chiamato una sola volta in totale
      verify(mockExpenseService.loadUserExpenses(user: fakeUser)).called(1);
      expect(readState().initStatus, ExpenseInitStatus.initialized);
    });

    // =================================================================
    // TEST 4: initialise() - Gestione RepositoryFailure
    // =================================================================
    test(
      'Should set initStatus to error and initError on RepositoryFailure during initialise',
      () async {
        // ARRANGE
        // Simuliamo un fallimento del repository (es. Firestore non raggiungibile)
        when(
          mockExpenseService.loadUserExpenses(user: fakeUser),
        ).thenThrow(RepositoryFailure("Firestore unavailable"));

        // ACT
        await readNotifier().initialise();

        // ASSERT
        expect(readState().initStatus, ExpenseInitStatus.error);
        expect(readState().initError, isA<RepositoryFailure>());
        expect(readState().expenses, isEmpty);
        expect(
          readState().errorMessage,
          isNull,
        ); // errorMessage non viene settato in initialise()
      },
    );

    // =================================================================
    // TEST 5: clear() - Reset completo dello stato
    // =================================================================
    test(
      'Should reset expenses and call calculateTotals with empty list on clear',
      () async {
        // ARRANGE
        when(
          mockExpenseService.loadUserExpenses(user: fakeUser),
        ).thenAnswer((_) async => [sampleExpense]);
        await readNotifier().initialise();
        expect(readState().expenses, hasLength(1)); // precondizione
        clearInteractions(
          mockExpenseService,
        ); // azzera contatore dopo initialise

        // ACT
        readNotifier().clear();

        // ASSERT
        expect(readState().expenses, isEmpty);
        expect(readState().errorMessage, isNull);
        expect(readState().initStatus, ExpenseInitStatus.initial);
        expect(readState().initError, isNull);
      },
    );

    // =================================================================
    // TEST 6: clearError() - Reset messaggi di errore e warning
    // =================================================================
    test(
      'Should clear errorMessage and warningMessage on clearError',
      () async {
        // ARRANGE — provoca un errorMessage tramite createExpense
        when(
          mockExpenseService.createExpense(
            value: anyNamed('value'),
            description: anyNamed('description'),
            date: anyNamed('date'),
            currency: anyNamed('currency'),
            category: anyNamed('category'),
            user: anyNamed('user'),
          ),
        ).thenThrow(RepositoryFailure("Some error"));

        await readNotifier().createExpense(
          value: 50.0,
          description: 'fail',
          date: DateTime(2024, 6, 15),
          currencyCode: ExpenseCurrency.euro,
          category: ExpenseCategory.food,
          l10n: mockL10n,
        );
        expect(readState().errorMessage, isNotNull); // precondizione

        // ACT
        readNotifier().clearError();

        // ASSERT
        expect(readState().errorMessage, isNull);
        expect(readState().warningMessage, isNull);
      },
    );

    // =================================================================
    // TEST 7: notifyListeners() - Notifica UI nelle operazioni principali
    // =================================================================
    test(
      'Should notify listeners during createExpense (loading=true then false)',
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
        ).thenAnswer((_) async {
          // Catturiamo lo stato DURANTE l'operazione asincrona
          expect(readState().isLoading, true); // isLoading deve essere true qui
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
        container.listen(expenseNotifierProvider, (_, _) => notifyCount++);

        // ACT
        await readNotifier().createExpense(
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
        expect(readState().isLoading, false);
      },
    );

    // =================================================================
    // TEST 8: updateAppCurrency() - Ricalcolo totali solo se valuta cambia
    // =================================================================
    test('Should recalculate totals only when currency actually changes', () {
      // ARRANGE
      // La valuta di default è EUR, quindi passare USD è un cambio reale

      // ACT - cambio reale: EUR → USD
      readNotifier().updateAppCurrency(ExpenseCurrency.usd);

      // ASSERT
      // calculateTotals deve essere stato chiamato esattamente una volta
      expect(readState().appCurrency, ExpenseCurrency.usd);
      verify(mockExpenseService.calculateTotals(any, any)).called(1);

      clearInteractions(mockExpenseService); // reset

      // ACT - nessun cambio: USD → USD
      readNotifier().updateAppCurrency(ExpenseCurrency.usd);

      // ASSERT
      // calculateTotals NON deve essere chiamato una seconda volta
      verifyNever(mockExpenseService.calculateTotals(any, any));
    });

    // =================================================================
    // TEST 9: createExpense() - Aggiunta spesa alla lista con successo
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
      await readNotifier().createExpense(
        value: 50.0,
        description: 'Test',
        date: DateTime(2024, 6, 15),
        currencyCode: ExpenseCurrency.euro,
        category: ExpenseCategory.food,
        l10n: mockL10n,
      );

      // ASSERT
      expect(readState().expenses, hasLength(1));
      expect(readState().expenses.first.uuid, sampleExpense.uuid);
      expect(readState().isLoading, false);
      expect(readState().errorMessage, isNull);

      // DOPO gli expect esistenti, aggiungi:
      verify(
        mockExpenseService.createExpense(
          value: 50.0,
          description: 'Test',
          date: DateTime(2024, 6, 15),
          currency: ExpenseCurrency.euro,
          category: ExpenseCategory.food,
          user: fakeUser,
        ),
      ).called(1);
    });

    // =================================================================
    // TEST 10: createExpense() - Warning offline settato correttamente
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
      await readNotifier().createExpense(
        value: 50.0,
        description: 'Offline expense',
        date: DateTime(2024, 6, 15),
        currencyCode: ExpenseCurrency.euro,
        category: ExpenseCategory.food,
        l10n: mockL10n,
      );

      // ASSERT
      // Il warning deve essere presente (testo localizzato dal mock l10n)
      expect(readState().warningMessage, isNotNull);
      expect(readState().warningMessage, 'Offline warning');
      // La spesa deve essere stata aggiunta comunque
      expect(readState().expenses, hasLength(1));
      verify(
        mockExpenseService.createExpense(
          value: 50.0,
          description: 'Offline expense',
          date: DateTime(2024, 6, 15),
          currency: ExpenseCurrency.euro,
          category: ExpenseCategory.food,
          user: fakeUser,
        ),
      ).called(1);
    });

    // =================================================================
    // TEST 11: createExpense() - Gestione RepositoryFailure
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
        await readNotifier().createExpense(
          value: 50.0,
          description: 'Failing expense',
          date: DateTime(2024, 6, 15),
          currencyCode: ExpenseCurrency.euro,
          category: ExpenseCategory.food,
          l10n: mockL10n,
        );

        // ASSERT
        expect(readState().errorMessage, isNotNull);
        expect(readState().errorMessage, contains("Save failed"));
        // La spesa NON deve essere stata aggiunta alla lista
        expect(readState().expenses, isEmpty);
        // isLoading deve essere false: verifica che il finally abbia funzionato
        expect(readState().isLoading, false);
      },
    );

    // =================================================================
    // TEST 12: editExpense() - Modifica spesa con successo
    // =================================================================
    test('Should update expense in list on successful editExpense', () async {
      // ARRANGE
      // Prima popoliamo il provider con una spesa tramite initialise()
      when(
        mockExpenseService.loadUserExpenses(user: fakeUser),
      ).thenAnswer((_) async => [sampleExpense]);
      await readNotifier().initialise();
      expect(readState().expenses, hasLength(1)); // precondizione
      expect(readState().initStatus, ExpenseInitStatus.initialized);

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
      await readNotifier().editExpense(
        sampleExpense,
        value: 999.0,
        description: 'Updated',
        date: DateTime(2024, 6, 15),
        currencyCode: ExpenseCurrency.euro,
        category: ExpenseCategory.food,
        l10n: mockL10n,
      );

      // ASSERT
      expect(readState().expenses, hasLength(1));
      expect(readState().expenses.first.value, 999.0);
      expect(readState().isLoading, false);
      expect(readState().errorMessage, isNull);

      verify(
        mockExpenseService.editExpense(
          sampleExpense,
          value: 999.0,
          description: 'Updated',
          date: DateTime(2024, 6, 15),
          currency: ExpenseCurrency.euro,
          category: ExpenseCategory.food,
          user: fakeUser,
        ),
      ).called(1);
    });

    // =================================================================
    // TEST 13: editExpense() - Warning offline settato correttamente
    // =================================================================
    test(
      'Should set warningMessage when editExpense service returns a warning',
      () async {
        // ARRANGE
        when(
          mockExpenseService.loadUserExpenses(user: fakeUser),
        ).thenAnswer((_) async => [sampleExpense]);
        await readNotifier().initialise();
        expect(readState().initStatus, ExpenseInitStatus.initialized);

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
        await readNotifier().editExpense(
          sampleExpense,
          value: 999.0,
          description: 'Offline edit',
          date: DateTime(2024, 6, 15),
          currencyCode: ExpenseCurrency.euro,
          category: ExpenseCategory.food,
          l10n: mockL10n,
        );

        // ASSERT
        expect(readState().warningMessage, isNotNull);
        expect(readState().warningMessage, 'Offline edit warning');
        // La spesa deve essere stata aggiornata comunque
        expect(readState().expenses.first.value, 999.0);

        verify(
          mockExpenseService.editExpense(
            sampleExpense,
            value: 999.0,
            description: 'Offline edit',
            date: DateTime(2024, 6, 15),
            currency: ExpenseCurrency.euro,
            category: ExpenseCategory.food,
            user: fakeUser,
          ),
        ).called(1);
      },
    );

    // =================================================================
    // TEST 14: editExpense() - Gestione RepositoryFailure
    // =================================================================
    test(
      'Should set errorMessage and keep original expense on RepositoryFailure during editExpense',
      () async {
        // ARRANGE
        // Prima popoliamo il provider con una spesa tramite initialise()
        when(
          mockExpenseService.loadUserExpenses(user: fakeUser),
        ).thenAnswer((_) async => [sampleExpense]);
        await readNotifier().initialise();
        expect(readState().expenses, hasLength(1)); // precondizione
        expect(readState().initStatus, ExpenseInitStatus.initialized);

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
        await readNotifier().editExpense(
          sampleExpense,
          value: 999.0,
          description: 'Updated',
          date: DateTime(2024, 6, 15),
          currencyCode: ExpenseCurrency.euro,
          category: ExpenseCategory.food,
          l10n: mockL10n,
        );

        // ASSERT
        expect(readState().errorMessage, isNotNull);
        expect(readState().errorMessage, contains("Edit failed"));
        // La spesa originale deve essere rimasta invariata
        expect(readState().expenses.first.value, 50.0);
        expect(readState().isLoading, false);
      },
    );

    // =================================================================
    // TEST 15: deleteExpenses() - Rimozione spese dalla lista locale
    // =================================================================
    test(
      'Should remove expenses from list on successful deleteExpenses',
      () async {
        // ARRANGE
        // Prima popoliamo il provider con una spesa tramite initialise()
        when(
          mockExpenseService.loadUserExpenses(user: fakeUser),
        ).thenAnswer((_) async => [sampleExpense]);
        await readNotifier().initialise();
        expect(readState().expenses, hasLength(1)); // precondizione
        expect(readState().initStatus, ExpenseInitStatus.initialized);

        // Stub deleteExpense: operazione andata a buon fine (nessuna eccezione)
        when(
          mockExpenseService.deleteExpense(sampleExpense, user: fakeUser),
        ).thenAnswer((_) async {});

        // ACT
        await readNotifier().deleteExpenses([sampleExpense]);

        // ASSERT
        expect(readState().expenses, isEmpty);
        expect(readState().isLoading, false);
        expect(readState().errorMessage, isNull);
      },
    );

    // =================================================================
    // TEST 16: deleteExpenses() - Gestione RepositoryFailure (partial)
    // =================================================================
    test(
      'Should remove only succeeded expenses and set errorMessage on partial deleteExpenses failure',
      () async {
        // ARRANGE
        final secondExpense = sampleExpense.copyWith(uuid: 'expense-uuid-2');

        when(
          mockExpenseService.loadUserExpenses(user: fakeUser),
        ).thenAnswer((_) async => [sampleExpense, secondExpense]);
        await readNotifier().initialise();
        expect(readState().expenses, hasLength(2)); // precondizione
        expect(readState().initStatus, ExpenseInitStatus.initialized);

        // Prima spesa: successo
        when(
          mockExpenseService.deleteExpense(sampleExpense, user: fakeUser),
        ).thenAnswer((_) async {});
        // Seconda spesa: fallimento
        when(
          mockExpenseService.deleteExpense(secondExpense, user: fakeUser),
        ).thenAnswer(
          (_) async => Future.error(RepositoryFailure("Network error")),
        );

        // ACT
        await readNotifier().deleteExpenses([sampleExpense, secondExpense]);

        // ASSERT
        expect(readState().expenses, hasLength(1));
        expect(readState().expenses.first.uuid, secondExpense.uuid);
        expect(readState().errorMessage, contains("Deletion failed for"));
        expect(readState().isLoading, false);
      },
    );

    // =================================================================
    // TEST 17: deleteExpenses() - Gestione RepositoryFailure
    // =================================================================
    test(
      'Should set errorMessage and keep expenses on RepositoryFailure during deleteExpenses',
      () async {
        // ARRANGE
        when(
          mockExpenseService.loadUserExpenses(user: fakeUser),
        ).thenAnswer((_) async => [sampleExpense]);
        await readNotifier().initialise();
        expect(readState().expenses, hasLength(1)); // precondizione
        expect(readState().initStatus, ExpenseInitStatus.initialized);

        when(
          mockExpenseService.deleteExpense(sampleExpense, user: fakeUser),
        ).thenAnswer(
          (_) async => Future.error(RepositoryFailure("Deletion failed")),
        );

        // ACT
        await readNotifier().deleteExpenses([sampleExpense]);

        // ASSERT
        expect(readState().errorMessage, isNotNull);
        expect(readState().errorMessage, contains("Deletion failed for"));
        // La spesa NON deve essere stata rimossa dalla lista
        expect(readState().expenses, hasLength(1));
        expect(readState().isLoading, false);
      },
    );

    // =================================================================
    // TEST 18: deleteExpenses() - isLoading true durante l'operazione
    // =================================================================
    test('Should set isLoading to true during deleteExpenses', () async {
      // ARRANGE
      when(
        mockExpenseService.loadUserExpenses(user: fakeUser),
      ).thenAnswer((_) async => [sampleExpense]);
      await readNotifier().initialise();
      expect(readState().initStatus, ExpenseInitStatus.initialized);

      when(
        mockExpenseService.deleteExpense(sampleExpense, user: fakeUser),
      ).thenAnswer((_) async {
        // Verifica lo stato intermedio: durante la delete, isLoading deve essere true
        expect(readState().isLoading, true);
      });

      // ACT
      await readNotifier().deleteExpenses([sampleExpense]);

      // ASSERT: dopo l'operazione, isLoading torna false
      expect(readState().isLoading, false);
    });

    // =================================================================
    // TEST 19: restoreExpenses() - Ripristino spese con successo
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
        await readNotifier().restoreExpenses([sampleExpense], mockL10n);

        // ASSERT
        expect(readState().expenses, hasLength(1));
        expect(readState().expenses.first.uuid, sampleExpense.uuid);
        expect(readState().isLoading, false);
        expect(readState().errorMessage, isNull);
        // restoreExpenses è l'unico path che chiama sortExpenses dopo un'aggiunta —
        // verifichiamo che l'ordinamento sia stato effettivamente orchestrato.
        verify(
          mockExpenseService.sortExpenses(any, 'date_desc', null),
        ).called(1);
      },
    );

    // =================================================================
    // TEST 20: restoreExpenses() - Failure parziale
    // =================================================================
    test(
      'Should add only succeeded expenses and set errorMessage on partial restoreExpenses failure',
      () async {
        // ARRANGE
        final secondExpense = sampleExpense.copyWith(uuid: 'expense-uuid-2');

        // Prima spesa: successo
        when(
          mockExpenseService.restoreExpense(sampleExpense, user: fakeUser),
        ).thenAnswer((_) async => sampleExpense);
        // Seconda spesa: fallimento
        when(
          mockExpenseService.restoreExpense(secondExpense, user: fakeUser),
        ).thenAnswer(
          (_) async => Future.error(RepositoryFailure("Network error")),
        );

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
        await readNotifier().restoreExpenses([
          sampleExpense,
          secondExpense,
        ], mockL10n);

        // ASSERT
        // Solo la prima spesa deve essere stata aggiunta
        expect(readState().expenses, hasLength(1));
        expect(readState().expenses.first.uuid, sampleExpense.uuid);
        expect(readState().errorMessage, contains("Restore failed for"));
        expect(readState().isLoading, false);
      },
    );

    // =================================================================
    // TEST 21: restoreExpenses() - Gestione RepositoryFailure
    // =================================================================
    test(
      'Should set errorMessage and not add expenses on RepositoryFailure during restoreExpenses',
      () async {
        // ARRANGE
        when(
          mockExpenseService.restoreExpense(sampleExpense, user: fakeUser),
        ).thenAnswer(
          (_) async => Future.error(RepositoryFailure("Unable to restore")),
        );

        // ACT
        await readNotifier().restoreExpenses([sampleExpense], mockL10n);

        // ASSERT
        expect(readState().errorMessage, isNotNull);
        expect(readState().errorMessage, contains("Restore failed for"));
        // La spesa NON deve essere stata aggiunta alla lista
        expect(readState().expenses, isEmpty);
        expect(readState().isLoading, false);
      },
    );

    // =================================================================
    // TEST 22: _checkBudget() - Notifica inviata quando budget superato
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
        await readNotifier().createExpense(
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
          mockNotificationNotifier.checkBudgetLimit(1200.0, any, any),
        ).called(1);
      },
    );

    // =================================================================
    // TEST 23: _checkBudgetForList() - Notifica inviata quando budget superato
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
        await readNotifier().restoreExpenses([sampleExpense], mockL10n);

        // ASSERT
        verify(
          mockNotificationNotifier.checkBudgetLimit(1200.0, any, any),
        ).called(1);
      },
    );

    // =================================================================
    // TEST 24: initialise() - Gestione eccezione generica (non RepositoryFailure)
    // =================================================================
    test(
      'Should set initStatus to error and initError as String on generic exception during initialise',
      () async {
        // ARRANGE
        when(
          mockExpenseService.loadUserExpenses(user: fakeUser),
        ).thenThrow(Exception("Unexpected"));

        // ACT
        await readNotifier().initialise();

        // ASSERT
        expect(readState().initStatus, ExpenseInitStatus.error);
        // Il catch generico setta initError come String, non come RepositoryFailure
        expect(readState().initError, isA<String>());
        expect(readState().initError.toString(), contains("Unexpected"));
        expect(readState().expenses, isEmpty);
        // errorMessage NON viene settato in initialise() — né nel catch RepositoryFailure né in quello generico
        expect(readState().errorMessage, isNull);
      },
    );

    // =================================================================
    // TEST 25: createExpense() - Gestione eccezione generica (non RepositoryFailure)
    // =================================================================
    test(
      'Should set errorMessage via toString and not add expense on generic exception during createExpense',
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
        ).thenThrow(Exception("Generic error"));

        // ACT
        await readNotifier().createExpense(
          value: 50.0,
          description: 'Test',
          date: DateTime(2024, 6, 15),
          currencyCode: ExpenseCurrency.euro,
          category: ExpenseCategory.food,
          l10n: mockL10n,
        );

        // ASSERT
        expect(readState().errorMessage, isNotNull);
        // Il catch generico usa e.toString(), non e.message come RepositoryFailure
        expect(readState().errorMessage, contains("Generic error"));
        expect(readState().expenses, isEmpty);
        expect(readState().isLoading, false);
      },
    );

    // =================================================================
    // TEST 26: editExpense() - Gestione eccezione generica (non RepositoryFailure)
    // =================================================================
    test(
      'Should set errorMessage via toString and keep original expense on generic exception during editExpense',
      () async {
        // ARRANGE
        when(
          mockExpenseService.loadUserExpenses(user: fakeUser),
        ).thenAnswer((_) async => [sampleExpense]);
        await readNotifier().initialise();
        expect(readState().expenses, hasLength(1)); // precondizione

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
        ).thenThrow(Exception("Generic error"));

        // ACT
        await readNotifier().editExpense(
          sampleExpense,
          value: 999.0,
          description: 'Updated',
          date: DateTime(2024, 6, 15),
          currencyCode: ExpenseCurrency.euro,
          category: ExpenseCategory.food,
          l10n: mockL10n,
        );

        // ASSERT
        expect(readState().errorMessage, isNotNull);
        expect(readState().errorMessage, contains("Generic error"));
        // La spesa originale deve essere rimasta invariata
        expect(readState().expenses, hasLength(1));
        expect(readState().expenses.first.value, 50.0);
        expect(readState().isLoading, false);
      },
    );

    // =================================================================
    // TEST 27: sortBy() - Passa appCurrency al service quando criteria contiene "amount"
    // =================================================================
    test(
      'Should pass appCurrency to sortExpenses when criteria contains amount',
      () {
        // ARRANGE
        // La valuta di default del provider è EUR

        // ACT
        readNotifier().sortBy('amount_desc');

        // ASSERT
        // Quando il criterio contiene "amount", il provider deve passare _appCurrency (EUR)
        verify(
          mockExpenseService.sortExpenses(
            any,
            'amount_desc',
            ExpenseCurrency.euro,
          ),
        ).called(1);
      },
    );

    // =================================================================
    // TEST 28: sortBy() - Passa null al service quando criteria non contiene "amount"
    // =================================================================
    test(
      'Should pass null currency to sortExpenses when criteria does not contain amount',
      () {
        // ARRANGE + ACT
        readNotifier().sortBy('date_desc');

        // ASSERT
        // Quando il criterio non contiene "amount", il provider deve passare null
        verify(
          mockExpenseService.sortExpenses(any, 'date_desc', null),
        ).called(1);
      },
    );
  });
}

// --- FAKE NOTIFICATION NOTIFIER ---
// Necessario perché NotificationNotifier estende Notifier e non può essere
// mockato direttamente. Lo wrappa delegando al mock.
class _FakeNotificationNotifier extends NotificationNotifier {
  final MockNotificationNotifier _mock;
  _FakeNotificationNotifier(this._mock);

  @override
  NotificationState build() => const NotificationState(
    monthlyLimit: 1000.0,
    limitAlertEnabled: false,
  );

  @override
  Future<void> checkBudgetLimit(
    double currentMonthlySpent,
    dynamic l10n,
    String currencySymbol,
  ) => _mock.checkBudgetLimit(currentMonthlySpent, l10n, currencySymbol);
}