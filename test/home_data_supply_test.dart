import 'dart:async';

import 'package:dwell/features/home/data/home_cases_provider.dart';
import 'package:dwell/features/home/data/home_mock_data.dart';
import 'package:dwell/features/home/home_page.dart';
import 'package:dwell/features/home/widgets/current_case_card.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  testWidgets('Home handles loading, error, retry and empty data', (
    tester,
  ) async {
    var request = Completer<List<HomeCaseData>>();
    final container = ProviderContainer(
      overrides: [homeCasesProvider.overrideWith((ref) => request.future)],
    );
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: HomePage()),
      ),
    );
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    request.completeError(StateError('private server detail'));
    await tester.pumpAndSettle();
    expect(find.text('Unable to load cases.'), findsOneWidget);
    expect(find.textContaining('private server detail'), findsNothing);
    request = Completer<List<HomeCaseData>>();
    await tester.tap(find.text('Retry'));
    await tester.pump();
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    request.complete([]);
    await tester.pumpAndSettle();
    expect(find.text('No cases found.'), findsOneWidget);
    expect(find.byType(CurrentCaseCard), findsNothing);
    expect(find.text('Needs Your Attention'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'Refresh corrects removed selection and retains case checklists',
    (tester) async {
      var data = homeCases;
      final container = ProviderContainer(
        overrides: [homeCasesProvider.overrideWith((ref) => data)],
      );
      addTearDown(container.dispose);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: HomePage()),
        ),
      );
      await tester.pumpAndSettle();
      final check = find.byKey(const ValueKey('home-checklist-0'));
      await tester.ensureVisible(check);
      await tester.tap(check);
      await tester.pump();
      final secondTab = find.byKey(
        ValueKey('home-case-${homeCases.last.number}'),
      );
      await tester.ensureVisible(secondTab);
      await tester.tap(secondTab);
      await tester.pumpAndSettle();
      data = [homeCases.first];
      container.invalidate(homeCasesProvider);
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<CurrentCaseCard>(find.byType(CurrentCaseCard))
            .data
            .number,
        homeCases.first.number,
      );
      expect(tester.widget<Checkbox>(check).value, isTrue);
      data = [];
      container.invalidate(homeCasesProvider);
      await tester.pumpAndSettle();
      expect(find.text('No cases found.'), findsOneWidget);
      data = homeCases;
      container.invalidate(homeCasesProvider);
      await tester.pumpAndSettle();
      expect(tester.widget<Checkbox>(check).value, isTrue);
      expect(tester.takeException(), isNull);
    },
  );
}
