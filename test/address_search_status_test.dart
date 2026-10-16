import 'dart:async';

import 'package:dwell/features/auth/services/address_suggestions.dart';
import 'package:dwell/features/auth/widgets/address_suggestion_field.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

class PendingAddressSource implements AddressSuggestionSource {
  final requests = <String, Completer<List<AddressSuggestion>>>{};
  @override
  Future<List<AddressSuggestion>> search(String query) =>
      (requests[query] = Completer<List<AddressSuggestion>>()).future;
}

void main() {
  const emptyMessage = 'No demo suggestions. Enter your address manually.';
  const errorMessage =
      'Unable to search addresses. Try again or enter your address manually.';
  const result = AddressSuggestion(
    line1: 'New road',
    city: 'New York',
    stateCode: 'NY',
    zip: '10025',
  );

  testWidgets(
    'Address distinguishes loading, empty, error and successful retry',
    (tester) async {
      final controller = TextEditingController();
      final source = PendingAddressSource();
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AddressSuggestionField(
              controller: controller,
              source: source,
              onChanged: (_) {},
              onSelected: (_) {},
            ),
          ),
        ),
      );
      final field = find.byKey(const ValueKey('signup-address'));
      await tester.enterText(field, 'empty');
      await tester.pump();
      expect(find.text('Searching addresses...'), findsOneWidget);
      source.requests['empty']!.complete([]);
      await tester.pumpAndSettle();
      expect(find.text(emptyMessage), findsOneWidget);
      await tester.enterText(field, 'error');
      await tester.pump();
      source.requests['error']!.completeError(StateError('private detail'));
      await tester.pumpAndSettle();
      expect(find.text(errorMessage), findsOneWidget);
      expect(find.text(emptyMessage), findsNothing);
      expect(find.textContaining('private detail'), findsNothing);
      await tester.enterText(field, 'success');
      await tester.pump();
      source.requests['success']!.complete([result]);
      await tester.pumpAndSettle();
      expect(find.text('New road'), findsOneWidget);
      expect(find.text(errorMessage), findsNothing);
      await tester.enterText(field, '');
      await tester.pumpAndSettle();
      expect(find.text('Searching addresses...'), findsNothing);
      expect(find.text(emptyMessage), findsNothing);
    },
  );

  testWidgets('Stale search failure cannot replace newer suggestions', (
    tester,
  ) async {
    final controller = TextEditingController();
    final source = PendingAddressSource();
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AddressSuggestionField(
            controller: controller,
            source: source,
            onChanged: (_) {},
            onSelected: (_) {},
          ),
        ),
      ),
    );
    final field = find.byKey(const ValueKey('signup-address'));
    await tester.enterText(field, 'old');
    await tester.pump();
    await tester.enterText(field, 'new');
    await tester.pump();
    source.requests['new']!.complete([result]);
    await tester.pumpAndSettle();
    source.requests['old']!.completeError(StateError('late failure'));
    await tester.pumpAndSettle();
    expect(find.text('New road'), findsOneWidget);
    expect(find.text(errorMessage), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
