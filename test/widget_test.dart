import 'package:dwell/app.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('루트 라우트가 렌더된다', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: DwellApp()));
    await tester.pumpAndSettle();

    expect(find.text('Dwell'), findsOneWidget);
  });
}
