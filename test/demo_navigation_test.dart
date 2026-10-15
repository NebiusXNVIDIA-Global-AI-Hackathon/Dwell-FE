import 'dart:async';

import 'package:dwell/app.dart';
import 'package:dwell/core/router.dart';
import 'package:dwell/core/widgets/bottom_nav_bar.dart';
import 'package:dwell/core/widgets/logout_confirmation_dialog.dart';
import 'package:dwell/core/widgets/profile_avatar.dart';
import 'package:dwell/features/auth/pages/login_page.dart';
import 'package:dwell/features/auth/providers/session_provider.dart';
import 'package:dwell/features/home/home_page.dart';
import 'package:dwell/features/splash/splash_page.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'helpers/case_creation_test_harness.dart' show loadCreationTestFonts;

Future<ProviderContainer> startApp(
  WidgetTester tester, {
  String? path,
  bool demo = false,
  Size size = const Size(390, 844),
  double scale = 1,
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
  tester.platformDispatcher.textScaleFactorTestValue = scale;
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
  final container = ProviderContainer();
  if (demo) container.read(sessionProvider.notifier).enterDemo();
  final router = container.read(routerProvider);
  if (path != null) router.go(path);
  addTearDown(() async {
    await tester.pumpWidget(const SizedBox.shrink());
    container.dispose();
  });
  await tester.pumpWidget(
    UncontrolledProviderScope(container: container, child: const DwellApp()),
  );
  await tester.pump();
  return container;
}

Future<void> confirmLogout(WidgetTester tester, {bool cancel = false}) async {
  await tester.tap(find.byType(ProfileAvatar).hitTestable());
  await tester.pumpAndSettle();
  await tester.tap(find.widgetWithText(MenuItemButton, 'Log out'));
  await tester.pumpAndSettle();
  expect(find.byType(LogoutConfirmationDialog), findsOneWidget);
  await tester.tap(
    find.widgetWithText(TextButton, cancel ? 'Cancel' : 'Log out'),
  );
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(loadCreationTestFonts);
  test('Demo is memory-only and does not authenticate an account', () {
    final first = ProviderContainer();
    expect(first.read(sessionProvider), SessionMode.unauthenticated);
    first.read(sessionProvider.notifier).enterDemo();
    first.read(sessionProvider.notifier).enterDemo();
    expect(first.read(sessionProvider), SessionMode.demo);
    first.read(sessionProvider.notifier).endDemo();
    expect(first.read(sessionProvider), SessionMode.unauthenticated);
    first.read(sessionProvider.notifier).enterDemo();
    first.dispose();
    final second = ProviderContainer();
    addTearDown(second.dispose);
    expect(second.read(sessionProvider), SessionMode.unauthenticated);
  });

  testWidgets(
    'Splash stays for two seconds then replaces itself with Login once',
    (tester) async {
      final container = await startApp(tester);
      final router = container.read(routerProvider);
      var loginTransitions = 0;
      router.routerDelegate.addListener(() {
        if (router.routeInformationProvider.value.uri.path == '/login') {
          loginTransitions++;
        }
      });
      expect(find.byType(SplashPage), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 1999));
      expect(find.byType(SplashPage), findsOneWidget);
      expect(find.byType(LoginPage), findsNothing);
      await tester.pump(const Duration(milliseconds: 1));
      await tester.pumpAndSettle();
      expect(find.byType(LoginPage), findsOneWidget);
      expect(router.canPop(), isFalse);
      final transitions = loginTransitions;
      expect(transitions, 1);
      await tester.pump(const Duration(seconds: 10));
      expect(loginTransitions, transitions);
    },
  );

  testWidgets('Splash timer is cancelled on disposal', (tester) async {
    var completions = 0;
    await tester.pumpWidget(
      MaterialApp(home: SplashPage(onCompleted: () => completions++)),
    );
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 3));
    expect(completions, 0);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Optional startup check must finish before Splash proceeds', (
    tester,
  ) async {
    final ready = Completer<void>();
    var completions = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: SplashPage(ready: ready.future, onCompleted: () => completions++),
      ),
    );
    await tester.pump(const Duration(seconds: 3));
    expect(completions, 0);
    ready.complete();
    await tester.pump();
    expect(completions, 1);
    await tester.pump(const Duration(seconds: 3));
    expect(completions, 1);
  });

  testWidgets(
    'Demo button enters Home with original mocks and Login cannot reappear via history',
    (tester) async {
      final container = await startApp(tester, path: '/login');
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('login-demo')));
      await tester.pumpAndSettle();
      expect(container.read(sessionProvider), SessionMode.demo);
      expect(find.byType(HomePage), findsOneWidget);
      expect(find.text('Water Leak'), findsOneWidget);
      expect(find.byKey(const ValueKey('home-case-C-005')), findsOneWidget);
      expect(find.byType(BottomNavBar), findsOneWidget);
      final router = container.read(routerProvider);
      expect(router.canPop(), isFalse);
      router.go('/login');
      await tester.pumpAndSettle();
      expect(router.routeInformationProvider.value.uri.path, '/home');
      expect(find.byType(LoginPage), findsNothing);
    },
  );

  testWidgets('Normal Login remains unconnected and does not grant access', (
    tester,
  ) async {
    final container = await startApp(tester, path: '/login');
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('login-email')),
      'example',
    );
    await tester.tap(find.byKey(const ValueKey('email-domain')));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(MenuItemButton, 'naver.com'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('login-password')),
      'password',
    );
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('login-submit')));
    await tester.pumpAndSettle();
    expect(find.text('Login is not connected yet.'), findsOneWidget);
    expect(container.read(sessionProvider), SessionMode.unauthenticated);
    expect(find.byType(HomePage), findsNothing);
  });

  const protected = [
    '/home',
    '/cases',
    '/my-place',
    '/my-page',
    '/assistant',
    '/cases/new',
    '/cases/new/analyzing',
    '/cases/new/created',
    '/assistant/bring-in-case',
    '/assistant/chat/C-006',
  ];
  testWidgets('Unauthenticated direct access is guarded for every app route', (
    tester,
  ) async {
    final container = await startApp(tester, path: '/login');
    final router = container.read(routerProvider);
    for (final path in protected) {
      router.go(path);
      await tester.pumpAndSettle();
      expect(
        router.routeInformationProvider.value.uri.path,
        '/login',
        reason: path,
      );
      expect(find.byType(LoginPage), findsOneWidget);
      expect(find.byType(BottomNavBar), findsNothing);
    }
  });

  testWidgets(
    'Demo can access existing app routes without rebuilding its router',
    (tester) async {
      final container = await startApp(tester, path: '/login');
      final router = container.read(routerProvider);
      container.read(sessionProvider.notifier).enterDemo();
      await tester.pumpAndSettle();
      for (final path in protected.where(
        (p) =>
            !p.endsWith('/analyzing') &&
            !p.endsWith('/created') &&
            !p.contains('/assistant/'),
      )) {
        router.go(path);
        await tester.pumpAndSettle();
        expect(router.routeInformationProvider.value.uri.path, path);
        expect(container.read(routerProvider), same(router));
      }
      expect(tester.takeException(), isNull);
    },
  );

  for (final path in ['/home', '/cases']) {
    testWidgets(
      '$path Cancel preserves Demo; confirmation closes Dialog then guards browser history',
      (tester) async {
        final container = await startApp(tester, path: path, demo: true);
        await tester.pumpAndSettle();
        final router = container.read(routerProvider);
        await confirmLogout(tester, cancel: true);
        expect(container.read(sessionProvider), SessionMode.demo);
        expect(router.routeInformationProvider.value.uri.path, path);
        await confirmLogout(tester);
        expect(container.read(sessionProvider), SessionMode.unauthenticated);
        expect(find.byType(LoginPage), findsOneWidget);
        expect(find.byType(LogoutConfirmationDialog), findsNothing);
        expect(find.byType(BottomNavBar), findsNothing);
        expect(router.canPop(), isFalse);
        // A restored browser URL is evaluated by the same parser/redirect guard.
        await router.routeInformationProvider.didPushRouteInformation(
          RouteInformation(uri: Uri.parse(path)),
        );
        await tester.pumpAndSettle();
        expect(router.routeInformationProvider.value.uri.path, '/login');
        expect(find.byType(LoginPage), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets('A new demo starts fresh Home state after logout', (
    tester,
  ) async {
    await startApp(tester, path: '/home', demo: true);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('home-case-C-005')));
    await tester.pumpAndSettle();
    expect(find.text('Roaches'), findsOneWidget);
    await confirmLogout(tester);
    await tester.tap(find.byKey(const ValueKey('login-demo')));
    await tester.pumpAndSettle();
    expect(find.text('Water Leak'), findsOneWidget);
  });

  for (final size in [
    const Size(320, 568),
    const Size(390, 844),
    const Size(1440, 900),
  ]) {
    testWidgets(
      'Entry flow at $size with text scale 2 fits and uses no auth tokens',
      (tester) async {
        final container = await startApp(
          tester,
          path: '/login',
          size: size,
          scale: 2,
        );
        await tester.pumpAndSettle();
        final button = find.byKey(const ValueKey('login-demo'));
        await tester.ensureVisible(button);
        await tester.tap(button);
        await tester.pumpAndSettle();
        expect(container.read(sessionProvider), SessionMode.demo);
        expect(find.byType(HomePage), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  }
}
