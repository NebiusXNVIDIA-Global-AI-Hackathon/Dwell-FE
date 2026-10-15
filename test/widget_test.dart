import 'package:dwell/app.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dwell/features/splash/splash_page.dart';
import 'package:dwell/features/auth/pages/login_page.dart';

void main() {
  testWidgets('루트 라우트가 렌더된다', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: DwellApp()));
    await tester.pumpAndSettle();

    expect(find.byType(SplashPage), findsOneWidget);
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();
    expect(find.byType(LoginPage), findsOneWidget);
  });
}
