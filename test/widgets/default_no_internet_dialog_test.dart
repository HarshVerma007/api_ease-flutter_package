import 'package:api_ease/api_ease.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late BuildContext capturedContext;

  tearDown(() => DefaultNoInternetDialog.resetForTesting());

  Future<void> pumpHost(WidgetTester tester) {
    return tester.pumpWidget(
      MaterialApp(
        home: Builder(builder: (context) {
          capturedContext = context;
          return Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () => DefaultNoInternetDialog.show(context),
                child: const Text('Open'),
              ),
            ),
          );
        }),
      ),
    );
  }

  testWidgets('shows title, message, icon and both buttons', (tester) async {
    await pumpHost(tester);

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    expect(find.text('No Internet Connection'), findsOneWidget);
    expect(
      find.text('Please check your connection and try again.'),
      findsOneWidget,
    );
    expect(find.byIcon(Icons.wifi_off_rounded), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);
    expect(find.text('Dismiss'), findsOneWidget);
    expect(find.byType(FilledButton), findsOneWidget);
    expect(find.byType(TextButton), findsOneWidget);

    await tester.tap(find.text('Dismiss'));
    await tester.pumpAndSettle();
  });

  testWidgets('uses rounded corners of 28', (tester) async {
    await pumpHost(tester);

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    final dialog = tester.widget<Dialog>(find.byType(Dialog));
    expect(
      dialog.shape,
      RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
    );

    await tester.tap(find.text('Dismiss'));
    await tester.pumpAndSettle();
  });

  testWidgets('Retry closes the dialog and calls onRetry', (tester) async {
    var retried = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(builder: (context) {
          return Scaffold(
            body: ElevatedButton(
              onPressed: () =>
                  DefaultNoInternetDialog.show(context, onRetry: () => retried++),
              child: const Text('Open'),
            ),
          );
        }),
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();

    expect(retried, 1);
    expect(find.text('No Internet Connection'), findsNothing);
    expect(DefaultNoInternetDialog.isShowing, isFalse);
  });

  testWidgets('Dismiss closes the dialog without calling onRetry',
      (tester) async {
    var retried = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(builder: (context) {
          return Scaffold(
            body: ElevatedButton(
              onPressed: () =>
                  DefaultNoInternetDialog.show(context, onRetry: () => retried++),
              child: const Text('Open'),
            ),
          );
        }),
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Dismiss'));
    await tester.pumpAndSettle();

    expect(retried, 0);
    expect(find.text('No Internet Connection'), findsNothing);
    expect(DefaultNoInternetDialog.isShowing, isFalse);
  });

  testWidgets('show() de-duplicates while a dialog is visible', (tester) async {
    await pumpHost(tester);

    late Future<void> f1;
    late Future<void> f2;
    await tester.runAsync(() async {
      // Not awaited on purpose: the future completes when the dialog closes.
      f1 = DefaultNoInternetDialog.show(capturedContext);
      f2 = DefaultNoInternetDialog.show(capturedContext);
    });
    await tester.pumpAndSettle();

    expect(find.byType(DefaultNoInternetDialog), findsOneWidget);
    expect(DefaultNoInternetDialog.isShowing, isTrue);

    await tester.tap(find.text('Dismiss'));
    await tester.pumpAndSettle();
    await tester.runAsync(() => Future.wait([f1, f2]));
    expect(DefaultNoInternetDialog.isShowing, isFalse);
  });

  testWidgets('show() can open several dialogs when deduplicate is false',
      (tester) async {
    await pumpHost(tester);

    late Future<void> f1;
    late Future<void> f2;
    await tester.runAsync(() async {
      f1 = DefaultNoInternetDialog.show(capturedContext, deduplicate: false);
      f2 = DefaultNoInternetDialog.show(capturedContext, deduplicate: false);
    });
    await tester.pumpAndSettle();

    expect(find.byType(DefaultNoInternetDialog), findsNWidgets(2));

    await tester.tap(find.text('Dismiss').last);
    await tester.pumpAndSettle();
    await tester.runAsync(() => f2);
    await tester.tap(find.text('Dismiss'));
    await tester.pumpAndSettle();
    await tester.runAsync(() => f1);
    expect(DefaultNoInternetDialog.isShowing, isFalse);
  });

  testWidgets('supports custom texts', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: DefaultNoInternetDialog(
            title: 'Offline',
            message: 'Reconnect please',
            retryLabel: 'Again',
            dismissLabel: 'Close',
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Offline'), findsOneWidget);
    expect(find.text('Reconnect please'), findsOneWidget);
    expect(find.text('Again'), findsOneWidget);
    expect(find.text('Close'), findsOneWidget);
  });
}
