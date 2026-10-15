import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:dwell/app.dart';
import 'package:dwell/core/router.dart';
import 'package:dwell/core/theme.dart';
import 'package:dwell/core/widgets/bottom_nav_bar.dart';
import 'package:dwell/features/auth/pages/login_page.dart';
import 'package:dwell/features/splash/splash_page.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

Finder get email => find.byKey(const ValueKey('login-email'));
Finder get password => find.byKey(const ValueKey('login-password'));
Finder get domain => find.byKey(const ValueKey('email-domain'));
Finder get submit => find.byKey(const ValueKey('login-submit'));
Finder get demo => find.byKey(const ValueKey('login-demo'));

Future<void> pumpLogin(
  WidgetTester tester, {
  LoginPage page = const LoginPage(),
  double width = 390,
  double scale = 1,
  double height = 844,
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = Size(width, height);
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetPhysicalSize);
  await tester.pumpWidget(
    MaterialApp(
      theme: buildTheme(Brightness.light),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context)
            .copyWith(textScaler: TextScaler.linear(scale)),
        child: child!,
      ),
      home: page,
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> fillValid(WidgetTester tester) async {
  await tester.enterText(email, 'example');
  await tester.tap(domain);
  await tester.pumpAndSettle();
  await tester.tap(find.widgetWithText(MenuItemButton, 'naver.com'));
  await tester.pumpAndSettle();
  await tester.enterText(password, '123456');
  await tester.pump();
}

void main() {
  if (const bool.fromEnvironment('DWELL_LOGIN_PREVIEW')) {
    testWidgets('Login design previews', (tester) async {
      final loader = FontLoader('Pretendard Variable')
        ..addFont(rootBundle.load('assets/fonts/PretendardVariable.ttf'));
      await tester.runAsync(() => loader.load());
      final icons = FontLoader('packages/lucide_icons_flutter/Lucide')
        ..addFont(
          rootBundle.load('packages/lucide_icons_flutter/assets/lucide.ttf'),
        );
      await tester.runAsync(() => icons.load());
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(390, 844);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);
      await tester.pumpWidget(
        RepaintBoundary(
          key: const ValueKey('login-preview'),
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: buildTheme(Brightness.light),
            home: const LoginPage(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      Future<void> capture(String name) async {
        await tester.runAsync(() async {
          final boundary = tester.renderObject<RenderRepaintBoundary>(
            find.byKey(const ValueKey('login-preview')),
          );
          final rendered = await boundary.toImage();
          final bytes = await rendered.toByteData(
            format: ui.ImageByteFormat.png,
          );
          final directory = Directory(
            '${Directory.systemTemp.path}/dwell-diagnostics',
          );
          await directory.create(recursive: true);
          await File('${directory.path}/$name.png')
              .writeAsBytes(bytes!.buffer.asUint8List());
          rendered.dispose();
        });
      }

      await capture('login-default');
      await tester.tap(domain);
      await tester.pumpAndSettle();
      await capture('login-domain');
      await tester.tap(find.widgetWithText(MenuItemButton, 'naver.com'));
      await tester.pumpAndSettle();
      await tester.enterText(email, 'example');
      await tester.enterText(password, '123456');
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pumpAndSettle();
      await capture('login-filled');
    });
  }
  testWidgets('Default Login omits Google, OR and bottom navigation', (
    tester,
  ) async {
    await pumpLogin(tester);
    expect(find.text('LOGIN'), findsOneWidget);
    expect(find.text('Email Address'), findsOneWidget);
    expect(find.text('Password'), findsOneWidget);
    expect(find.text('OR'), findsNothing);
    expect(find.textContaining('Google'), findsNothing);
    expect(find.byType(BottomNavBar), findsNothing);
    expect(tester.widget<FilledButton>(submit).onPressed, isNull);
    expect(tester.widget<TextField>(password).obscureText, isTrue);
  });

  testWidgets('Domain overlays form, toggles and dismisses outside', (
    tester,
  ) async {
    await pumpLogin(tester);
    final before = tester.getTopLeft(password);
    await tester.tap(domain);
    await tester.pumpAndSettle();
    expect(find.byType(MenuItemButton), findsNWidgets(3));
    expect(tester.getTopLeft(password), before);
    await tester.tap(domain);
    await tester.pumpAndSettle();
    expect(find.byType(MenuItemButton), findsNothing);
    await tester.tap(domain);
    await tester.pumpAndSettle();
    await tester.tap(find.text('LOGIN'));
    await tester.pumpAndSettle();
    expect(find.byType(MenuItemButton), findsNothing);
  });

  testWidgets(
    'Valid inputs enable Login and deliver combined email unchanged password',
    (tester) async {
      String? receivedEmail;
      String? receivedPassword;
      await pumpLogin(
        tester,
        page: LoginPage(
          onLogin: (email, password) async {
            receivedEmail = email;
            receivedPassword = password;
          },
        ),
      );
      await fillValid(tester);
      expect(tester.widget<FilledButton>(submit).onPressed, isNotNull);
      await tester.tap(submit);
      await tester.pumpAndSettle();
      expect(receivedEmail, 'example@naver.com');
      expect(receivedPassword, '123456');
      expect(find.byType(LoginPage), findsOneWidget);
    },
  );

  testWidgets(
    'Missing domain, invalid local parts and blank password disable Login',
    (tester) async {
      await pumpLogin(tester);
      await tester.enterText(email, 'example');
      await tester.enterText(password, 'password');
      await tester.pump();
      expect(tester.widget<FilledButton>(submit).onPressed, isNull);
      await fillValid(tester);
      for (final invalid in [
        '',
        ' ',
        'a@b',
        'a b',
        '.example',
        'example.',
        'a..b',
      ]) {
        await tester.enterText(email, invalid);
        await tester.pump();
        expect(
          tester.widget<FilledButton>(submit).onPressed,
          isNull,
          reason: invalid,
        );
      }
      await tester.enterText(email, 'valid.name+tag');
      await tester.enterText(password, '   ');
      await tester.pump();
      expect(tester.widget<FilledButton>(submit).onPressed, isNull);
    },
  );

  testWidgets('Password visibility preserves text and selection', (
    tester,
  ) async {
    await pumpLogin(tester);
    await tester.enterText(password, '123456');
    final controller = tester.widget<TextField>(password).controller!;
    controller.selection = const TextSelection.collapsed(offset: 3);
    await tester.tap(find.byTooltip('Show password'));
    await tester.pump();
    expect(tester.widget<TextField>(password).obscureText, isFalse);
    expect(controller.text, '123456');
    expect(controller.selection.baseOffset, 3);
    await tester.tap(find.byTooltip('Hide password'));
    await tester.pump();
    expect(tester.widget<TextField>(password).obscureText, isTrue);
    expect(controller.text, '123456');
  });

  testWidgets('Login and Demo brighten only while pressed with no overlay', (
    tester,
  ) async {
    await pumpLogin(tester);
    await fillValid(tester);
    for (final button in [submit, demo]) {
      final widget = tester.widget<FilledButton>(button);
      expect(
        widget.style!.overlayColor!.resolve({WidgetState.hovered}),
        Colors.transparent,
      );
      final normal = widget.style!.backgroundColor!.resolve({});
      final pressed = widget.style!.backgroundColor!.resolve({
        WidgetState.pressed,
      });
      expect(pressed, isNot(normal));
      await tester.ensureVisible(button);
      final gesture = await tester.startGesture(tester.getCenter(button));
      await tester.pump(const Duration(milliseconds: 250));
      Material material() => tester.widget<Material>(
        find.descendant(of: button, matching: find.byType(Material)).first,
      );
      expect(material().color, pressed);
      await gesture.cancel();
      await tester.pumpAndSettle();
      expect(material().color, normal);
    }
  });

  testWidgets('Unconnected actions show guidance without leaving Login', (
    tester,
  ) async {
    await pumpLogin(tester);
    await fillValid(tester);
    await tester.tap(submit);
    await tester.pumpAndSettle();
    expect(find.text('Login is not connected yet.'), findsOneWidget);
    await tester.tap(demo);
    await tester.pumpAndSettle();
    expect(find.text('Demo mode is not connected yet.'), findsOneWidget);
    await tester.ensureVisible(find.text('Sign up'));
    await tester.tap(find.text('Sign up'));
    await tester.pumpAndSettle();
    expect(find.text('Sign up is not connected yet.'), findsOneWidget);
    expect(find.byType(LoginPage), findsOneWidget);
  });

  testWidgets(
    'Busy Login rejects duplicates and handles errors without leaking credentials',
    (tester) async {
      final pending = Completer<void>();
      var calls = 0;
      await pumpLogin(
        tester,
        page: LoginPage(
          onLogin: (_, _) {
            calls++;
            return pending.future;
          },
        ),
      );
      await fillValid(tester);
      await tester.tap(submit);
      await tester.pump();
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(tester.widget<FilledButton>(submit).onPressed, isNull);
      expect(tester.widget<FilledButton>(demo).onPressed, isNull);
      expect(calls, 1);
      pending.completeError(StateError('private password'));
      await tester.pumpAndSettle();
      expect(
        find.text('Unable to complete this request. Please try again.'),
        findsOneWidget,
      );
      expect(find.textContaining('private'), findsNothing);
      expect(tester.widget<FilledButton>(submit).onPressed, isNotNull);
    },
  );

  testWidgets(
    'Demo and Sign up hooks are called without automatic authentication',
    (tester) async {
      var demoCalls = 0;
      var signUpCalls = 0;
      await pumpLogin(
        tester,
        page: LoginPage(
          onDemo: () async {
            demoCalls++;
          },
          onSignUp: () {
            signUpCalls++;
          },
        ),
      );
      await tester.tap(demo);
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Sign up'));
      await tester.tap(find.text('Sign up'));
      await tester.pump();
      expect(demoCalls, 1);
      expect(signUpCalls, 1);
      expect(find.byType(LoginPage), findsOneWidget);
    },
  );

  testWidgets('Pending callbacks safely finish after disposal', (tester) async {
    final pending = Completer<void>();
    await pumpLogin(tester, page: LoginPage(onDemo: () => pending.future));
    await tester.tap(demo);
    await tester.pump();
    await tester.pumpWidget(const SizedBox());
    pending.complete();
    await tester.pump();
    expect(tester.takeException(), isNull);
  });

  for (final width in [320.0, 375.0, 390.0, 430.0, 1440.0]) {
    for (final scale in [1.0, 1.5, 2.0]) {
      testWidgets('Login and domain fit $width at $scale text scale', (
        tester,
      ) async {
        await pumpLogin(tester, width: width, scale: scale);
        await tester.ensureVisible(domain);
        await tester.tap(domain);
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        await tester.tap(find.widgetWithText(MenuItemButton, 'google.com'));
        await tester.pumpAndSettle();
        await tester.ensureVisible(demo);
        expect(tester.getRect(demo).right, lessThanOrEqualTo(width));
        expect(tester.takeException(), isNull);
      });
    }
  }

  testWidgets('Keyboard resizing keeps Password and Login reachable', (
    tester,
  ) async {
    await pumpLogin(tester, width: 320, height: 568);
    tester.view.viewInsets = const FakeViewPadding(bottom: 280);
    addTearDown(tester.view.resetViewInsets);
    await tester.pump();
    await tester.ensureVisible(password);
    await tester.enterText(password, '123456');
    await tester.ensureVisible(submit);
    await tester.pump();
    expect(tester.getRect(submit).bottom, lessThanOrEqualTo(288));
    expect(tester.takeException(), isNull);
  });

  testWidgets('Splash completion navigates to standalone Login once', (
    tester,
  ) async {
    final ready = Completer<void>();
    final container = ProviderContainer(
      overrides: [splashCompletionProvider.overrideWithValue(ready.future)],
    );
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(container: container, child: const DwellApp()),
    );
    await tester.pumpAndSettle();
    expect(find.byType(SplashPage), findsOneWidget);
    ready.complete();
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();
    expect(find.byType(LoginPage), findsOneWidget);
    expect(find.byType(BottomNavBar), findsNothing);
    expect(
      container.read(routerProvider).routeInformationProvider.value.uri.path,
      '/login',
    );
  });

  testWidgets('Disposed Splash never calls its completion callback', (
    tester,
  ) async {
    final ready = Completer<void>();
    var calls = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: SplashPage(ready: ready.future, onCompleted: () => calls++),
      ),
    );
    await tester.pumpAndSettle();
    await tester.pumpWidget(const SizedBox());
    ready.complete();
    await tester.pump();
    expect(calls, 0);
    expect(tester.takeException(), isNull);
  });
}
