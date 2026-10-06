import 'package:dwell/app.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dwell/features/home/home_page.dart';

void main() {
  testWidgets('루트 라우트가 렌더된다', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: DwellApp()));
    await tester.pumpAndSettle();

    expect(find.byType(HomePage), findsOneWidget); //시작할 때 홈 페이지가 표시되는 테스트로 바꿈
  });
}
