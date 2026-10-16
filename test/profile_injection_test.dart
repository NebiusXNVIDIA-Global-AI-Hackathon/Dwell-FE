import 'package:dwell/core/widgets/app_screen_header.dart';
import 'package:dwell/core/widgets/profile_avatar.dart';
import 'package:dwell/features/auth/providers/profile_provider.dart';
import 'package:dwell/features/auth/providers/session_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

class AuthenticatedSession extends SessionController {
  @override
  SessionMode build() => SessionMode.authenticated;
}

void main() {
  testWidgets('Authenticated header accepts a profile and explicit nickname', (
    tester,
  ) async {
    final container = ProviderContainer(
      overrides: [
        profileNicknameProvider.overrideWithValue('Alex'),
        sessionProvider.overrideWith(AuthenticatedSession.new),
      ],
    );
    addTearDown(container.dispose);
    Future<void> render(String? nickname) => tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          home: Scaffold(
            body: AppScreenHeader(
              title: const Text('Cases'),
              nickname: nickname,
            ),
          ),
        ),
      ),
    );
    await render(null);
    expect(
      tester.widget<ProfileAvatar>(find.byType(ProfileAvatar)).nickname,
      'Alex',
    );
    await render('Sam');
    expect(
      tester.widget<ProfileAvatar>(find.byType(ProfileAvatar)).nickname,
      'Sam',
    );
  });

  testWidgets('Demo always keeps SJ even if profile data is supplied', (
    tester,
  ) async {
    final container = ProviderContainer(
      overrides: [profileNicknameProvider.overrideWithValue('Alex')],
    );
    addTearDown(container.dispose);
    container.read(sessionProvider.notifier).enterDemo();
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          home: Scaffold(
            body: AppScreenHeader(title: Text('Cases'), nickname: 'Sam'),
          ),
        ),
      ),
    );
    expect(
      tester.widget<ProfileAvatar>(find.byType(ProfileAvatar)).nickname,
      'SJ',
    );
  });
}
