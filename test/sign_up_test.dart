import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:dwell/core/router.dart';
import 'package:dwell/app.dart';
import 'package:dwell/core/theme.dart';
import 'package:dwell/core/widgets/bottom_nav_bar.dart';
import 'package:dwell/features/auth/data/us_states.dart';
import 'package:dwell/features/auth/models/sign_up_draft.dart';
import 'package:dwell/features/auth/pages/login_page.dart';
import 'package:dwell/features/auth/pages/sign_up_address_page.dart';
import 'package:dwell/features/auth/providers/session_provider.dart';
import 'package:dwell/features/auth/providers/sign_up_provider.dart';
import 'package:dwell/features/auth/services/address_suggestions.dart';
import 'package:dwell/features/auth/widgets/address_suggestion_field.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'demo_navigation_test.dart' show startApp;
import 'helpers/case_creation_test_harness.dart' show loadCreationTestFonts;

Finder field(String name) => find.byKey(ValueKey('signup-$name'));
Finder button(String label) => find.widgetWithText(FilledButton, label);
const validStep1 = SignUpDraft(
  nickname: 'Sam',
  password: '123456',
  confirmPassword: '123456',
  emailLocalPart: 'sam',
  emailDomain: 'naver.com',
);
final validAll = validStep1.copyWith(
  addressLine1: '254 W 107th St',
  city: 'New York',
  stateCode: 'NY',
  zipCode: '10025',
);

class PendingSuggestions implements AddressSuggestionSource {
  final requests = <String, Completer<List<AddressSuggestion>>>{};
  @override
  Future<List<AddressSuggestion>> search(String query) =>
      (requests[query] = Completer<List<AddressSuggestion>>()).future;
}

Future<ProviderContainer> openSignUp(
  WidgetTester tester, {
  double width = 390,
  double scale = 1,
  double height = 844,
}) async {
  final container = await startApp(
    tester,
    path: '/login',
    size: Size(width, height),
    scale: scale,
  );
  await tester.pumpAndSettle();
  await tester.ensureVisible(find.text('Sign up'));
  await tester.tap(find.text('Sign up'));
  await tester.pumpAndSettle();
  return container;
}

Future<void> enter(WidgetTester tester, String name, String value) async {
  final finder = find.byKey(ValueKey('signup-$name'));
  await tester.ensureVisible(finder);
  await tester.enterText(finder, value);
  await tester.pumpAndSettle();
}

Future<void> fillStep1(WidgetTester tester) async {
  await enter(tester, 'nickname', ' Sam ');
  await enter(tester, 'password', '123456');
  await enter(tester, 'confirm', '123456');
  await enter(tester, 'email', 'sam');
  final domain = find.byKey(const ValueKey('email-domain'));
  await tester.ensureVisible(domain);
  await tester.tap(domain);
  await tester.pumpAndSettle();
  await tester.tap(find.widgetWithText(MenuItemButton, 'naver.com'));
  await tester.pumpAndSettle();
}

Future<void> next(WidgetTester tester) async {
  await tester.ensureVisible(button('Next'));
  await tester.tap(button('Next'));
  await tester.pumpAndSettle();
}

Future<void> chooseAddress(WidgetTester tester) async {
  await enter(tester, 'address', '254 W 107');
  await tester.tap(
    find.widgetWithText(TextButton, '254 W 107th St').hitTestable(),
  );
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(loadCreationTestFonts);

  if (const bool.fromEnvironment('DWELL_SIGNUP_PREVIEW')) {
    testWidgets('Signup design previews', (tester) async {
      final icons = FontLoader('packages/lucide_icons_flutter/Lucide')
        ..addFont(
          rootBundle.load('packages/lucide_icons_flutter/assets/lucide.ttf'),
        );
      await tester.runAsync(() => icons.load());
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(390, 844);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);
      final container = ProviderContainer();
      container.read(routerProvider).go('/sign-up');
      addTearDown(container.dispose);
      await tester.pumpWidget(
        RepaintBoundary(
          key: const ValueKey('signup-preview'),
          child: UncontrolledProviderScope(
            container: container,
            child: const DwellApp(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      Future<void> capture(String name) async {
        await tester.runAsync(() async {
          final boundary = tester.renderObject<RenderRepaintBoundary>(
            find.byKey(const ValueKey('signup-preview')),
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

      await capture('signup-default');
      await enter(tester, 'password', '1234');
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pumpAndSettle();
      await capture('signup-invalid');
      await fillStep1(tester);
      await next(tester);
      await chooseAddress(tester);
      await capture('signup-address');
      await tester.tap(find.byKey(const ValueKey('signup-state')));
      await tester.pumpAndSettle();
      await capture('signup-states');
    });
  }

  testWidgets('Address results reject stale requests and dispose safely', (
    tester,
  ) async {
    final controller = TextEditingController();
    final source = PendingSuggestions();
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
    await tester.enterText(field('address'), 'old');
    await tester.pump();
    await tester.enterText(field('address'), 'new');
    await tester.pump();
    source.requests['new']!.complete([
      const AddressSuggestion(
        line1: 'New road',
        city: 'New York',
        stateCode: 'NY',
        zip: '10025',
      ),
    ]);
    await tester.pumpAndSettle();
    source.requests['old']!.complete([]);
    await tester.pumpAndSettle();
    expect(find.text('New road'), findsOneWidget);
    expect(
      find.text('No demo suggestions. Enter your address manually.'),
      findsNothing,
    );
    await tester.enterText(field('address'), 'late');
    await tester.pump();
    await tester.pumpWidget(const SizedBox.shrink());
    source.requests['late']!.complete([]);
    await tester.pump();
    expect(tester.takeException(), isNull);
  });

  test('Draft validation, normalization and ZIP retain leading zero', () {
    expect(const SignUpDraft().canContinue, isFalse);
    for (final password in ['12345', '123456789']) {
      expect(validStep1.copyWith(password: password).canContinue, isFalse);
    }
    expect(validStep1.copyWith(nickname: '  ').canContinue, isFalse);
    expect(validStep1.copyWith(emailLocalPart: 'a@b').canContinue, isFalse);
    expect(validStep1.copyWith(emailDomain: '').canContinue, isFalse);
    expect(validStep1.copyWith(confirmPassword: '654321').canContinue, isFalse);
    expect(validAll.canSubmit, isTrue);
    expect(validAll.copyWith(zipCode: '01234').validAddress, isTrue);
    for (final zip in ['', '1234', '123456', '12a45', '10025-1234']) {
      expect(validAll.copyWith(zipCode: zip).validAddress, isFalse);
    }
    expect(validAll.copyWith(stateCode: 'XX').validAddress, isFalse);
    expect(validAll.copyWith(city: '  ').validAddress, isFalse);
    expect(validAll.copyWith(apartment: '').canSubmit, isTrue);
    final normalized = validAll
        .copyWith(
          nickname: ' Sam ',
          addressLine1: ' Road ',
          city: ' City ',
          zipCode: ' 01234 ',
          password: ' abcde',
          confirmPassword: ' abcde',
        )
        .normalized;
    expect(normalized.nickname, 'Sam');
    expect(normalized.addressLine1, 'Road');
    expect(normalized.zipCode, '01234');
    expect(normalized.password, ' abcde');
    expect(normalized.toString(), isNot(contains('abcde')));
  });

  test(
    'State dataset contains 50 states plus DC and local source is only a demo',
    () async {
      expect(usStates.length, 51);
      expect(usStates['DC'], 'District of Columbia');
      expect(usStates['NY'], 'New York');
      final source = MockAddressSuggestions();
      expect(await source.search(''), isEmpty);
      expect(await source.search('unknown road'), isEmpty);
      final results = await source.search('254 W 107');
      expect(results.single.line1, '254 W 107th St');
      expect(results.single.zip, '10025');
    },
  );

  testWidgets(
    'Login opens public JOIN US with empty fields and no Bottom Navigation',
    (tester) async {
      final container = await openSignUp(tester);
      expect(find.text('JOIN US'), findsOneWidget);
      expect(
        tester.widget<TextField>(field('nickname')).controller!.text,
        isEmpty,
      );
      expect(find.text('Password must be 6-8 characters long.'), findsNothing);
      expect(find.text('Passwords do not match.'), findsNothing);
      expect(find.byType(BottomNavBar), findsNothing);
      expect(tester.widget<FilledButton>(button('Next')).onPressed, isNull);
      expect(container.read(sessionProvider), SessionMode.unauthenticated);
    },
  );

  testWidgets(
    'Password errors appear after editing, do not truncate, and confirm revalidates',
    (tester) async {
      await openSignUp(tester);
      await enter(tester, 'password', '1234');
      expect(
        find.text('Password must be 6-8 characters long.'),
        findsOneWidget,
      );
      await enter(tester, 'password', '123456789');
      expect(
        tester.widget<TextField>(field('password')).controller!.text,
        '123456789',
      );
      expect(
        find.text('Password must be 6-8 characters long.'),
        findsOneWidget,
      );
      await enter(tester, 'password', '123456');
      await enter(tester, 'confirm', '654321');
      expect(find.text('Passwords do not match.'), findsOneWidget);
      await enter(tester, 'confirm', '123456');
      expect(find.text('Passwords do not match.'), findsNothing);
      await enter(tester, 'password', '1234567');
      expect(find.text('Passwords do not match.'), findsOneWidget);
    },
  );

  testWidgets('Password eyes are independent and retain cursor and text', (
    tester,
  ) async {
    await openSignUp(tester);
    await enter(tester, 'password', '123456');
    await enter(tester, 'confirm', '123456');
    final controller = tester.widget<TextField>(field('password')).controller!;
    controller.selection = const TextSelection.collapsed(offset: 2);
    await tester.tap(find.byTooltip('Show password').hitTestable());
    await tester.pump();
    expect(tester.widget<TextField>(field('password')).obscureText, isFalse);
    expect(tester.widget<TextField>(field('confirm')).obscureText, isTrue);
    expect(controller.selection.baseOffset, 2);
    expect(controller.text, '123456');
    await tester.tap(find.byTooltip('Show confirm password').hitTestable());
    await tester.pump();
    expect(tester.widget<TextField>(field('confirm')).obscureText, isFalse);
  });

  testWidgets(
    'Email selection combines value, keeps form position, and shows current check',
    (tester) async {
      final container = await openSignUp(tester);
      await fillStep1(tester);
      expect(container.read(signUpProvider).email, 'sam@naver.com');
      final before = tester.getTopLeft(button('Next'));
      await tester.tap(
        find.byKey(const ValueKey('email-domain')).hitTestable(),
      );
      await tester.pumpAndSettle();
      final selected = tester.widget<MenuItemButton>(
        find.widgetWithText(MenuItemButton, 'naver.com'),
      );
      expect(selected.trailingIcon, isNotNull);
      expect(tester.getTopLeft(button('Next')), before);
      await tester.tap(find.text('JOIN US'));
      await tester.pumpAndSettle();
      expect(find.byType(MenuItemButton), findsNothing);
      expect(tester.widget<FilledButton>(button('Next')).onPressed, isNotNull);
    },
  );

  testWidgets('Next uses pressed Navy only while held', (tester) async {
    await openSignUp(tester);
    await fillStep1(tester);
    await tester.ensureVisible(button('Next'));
    final gesture = await tester.startGesture(tester.getCenter(button('Next')));
    await tester.pump(const Duration(milliseconds: 250));
    final material = tester.widget<Material>(
      find
          .descendant(of: button('Next'), matching: find.byType(Material))
          .first,
    );
    expect(material.color, const Color(0xFF506477));
    await gesture.cancel();
    await tester.pumpAndSettle();
    expect(find.text('JOIN US'), findsOneWidget);
  });

  testWidgets(
    'Address overlay autofills fields, preserves apartment and allows Join without it',
    (tester) async {
      final container = await openSignUp(tester);
      await fillStep1(tester);
      await next(tester);
      expect(find.text('ADDRESS'), findsOneWidget);
      expect(tester.widget<FilledButton>(button('Join')).onPressed, isNull);
      await enter(tester, 'apartment', 'Apt 4B');
      final before = tester.getTopLeft(field('city'));
      await enter(tester, 'address', '254 W 107');
      expect(find.text('New York, NY 10025'), findsOneWidget);
      expect(tester.getTopLeft(field('city')), before);
      await tester.tap(
        find.widgetWithText(TextButton, '254 W 107th St').hitTestable(),
      );
      await tester.pumpAndSettle();
      expect(container.read(signUpProvider).stateCode, 'NY');
      expect(
        tester.widget<TextField>(field('city')).controller!.text,
        'New York',
      );
      expect(tester.widget<TextField>(field('zip')).controller!.text, '10025');
      expect(
        tester.widget<TextField>(field('apartment')).controller!.text,
        'Apt 4B',
      );
      await enter(tester, 'apartment', '');
      expect(tester.widget<FilledButton>(button('Join')).onPressed, isNotNull);
    },
  );

  testWidgets(
    'State dropdown selection and ZIP validation permit manual addresses',
    (tester) async {
      final container = await openSignUp(tester);
      await fillStep1(tester);
      await next(tester);
      await enter(tester, 'address', 'Unknown road');
      expect(
        find.text('No demo suggestions. Enter your address manually.'),
        findsOneWidget,
      );
      await enter(tester, 'city', 'My city');
      final state = find.byKey(const ValueKey('signup-state'));
      await tester.ensureVisible(state);
      await tester.tap(state);
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(MenuItemButton, 'AL'));
      await tester.pumpAndSettle();
      expect(container.read(signUpProvider).stateCode, 'AL');
      await tester.tap(state);
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<MenuItemButton>(find.widgetWithText(MenuItemButton, 'AL'))
            .trailingIcon,
        isNotNull,
      );
      await tester.tap(find.text('ADDRESS'));
      await tester.pumpAndSettle();
      expect(find.byType(MenuItemButton), findsNothing);
      for (final zip in ['1234', '123456']) {
        await enter(tester, 'zip', zip);
        expect(tester.widget<FilledButton>(button('Join')).onPressed, isNull);
      }
      await enter(tester, 'zip', '01234');
      expect(container.read(signUpProvider).zipCode, '01234');
      expect(tester.widget<FilledButton>(button('Join')).onPressed, isNotNull);
    },
  );

  testWidgets('Join is pressed correctly and never creates an auth session', (
    tester,
  ) async {
    final container = await openSignUp(tester);
    await fillStep1(tester);
    await next(tester);
    await chooseAddress(tester);
    await tester.ensureVisible(button('Join'));
    final gesture = await tester.startGesture(tester.getCenter(button('Join')));
    await tester.pump(const Duration(milliseconds: 250));
    expect(
      tester
          .widget<Material>(
            find
                .descendant(of: button('Join'), matching: find.byType(Material))
                .first,
          )
          .color,
      const Color(0xFF506477),
    );
    await gesture.up();
    await tester.pumpAndSettle();
    expect(
      find.text('Sign up is not connected yet. No account has been created.'),
      findsOneWidget,
    );
    expect(container.read(sessionProvider), SessionMode.unauthenticated);
    expect(
      container.read(routerProvider).routeInformationProvider.value.uri.path,
      '/sign-up/address',
    );
    expect(
      find.text(
        "Your exact address and the fact that you live here stay private, and you'll always appear anonymously.",
      ),
      findsOneWidget,
    );
  });

  testWidgets(
    'System back and re-entry retain both steps; leaving signup clears secrets',
    (tester) async {
      final container = await openSignUp(tester);
      await fillStep1(tester);
      await next(tester);
      await chooseAddress(tester);
      await enter(tester, 'apartment', 'Apt 4B');
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.text('JOIN US'), findsOneWidget);
      expect(
        tester.widget<TextField>(field('nickname')).controller!.text,
        ' Sam ',
      );
      await next(tester);
      expect(
        tester.widget<TextField>(field('apartment')).controller!.text,
        'Apt 4B',
      );
      expect(
        tester.widget<TextField>(field('city')).controller!.text,
        'New York',
      );
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.byType(LoginPage), findsOneWidget);
      await tester.ensureVisible(find.text('Sign up'));
      await tester.tap(find.text('Sign up'));
      await tester.pumpAndSettle();
      expect(container.read(signUpProvider).password, isEmpty);
      expect(
        tester.widget<TextField>(field('nickname')).controller!.text,
        isEmpty,
      );
    },
  );

  testWidgets('Browser route events preserve draft across step navigation', (
    tester,
  ) async {
    final container = await openSignUp(tester);
    await fillStep1(tester);
    await next(tester);
    await chooseAddress(tester);
    final router = container.read(routerProvider);
    await router.routeInformationProvider.didPushRouteInformation(
      RouteInformation(uri: Uri.parse('/sign-up')),
    );
    await tester.pumpAndSettle();
    expect(find.text('JOIN US'), findsOneWidget);
    await router.routeInformationProvider.didPushRouteInformation(
      RouteInformation(uri: Uri.parse('/sign-up/address')),
    );
    await tester.pumpAndSettle();
    expect(find.text('ADDRESS'), findsOneWidget);
    expect(container.read(signUpProvider).zipCode, '10025');
  });

  testWidgets(
    'Deep link Address redirects to required first step; Demo cannot open signup',
    (tester) async {
      final container = await startApp(tester, path: '/sign-up/address');
      await tester.pumpAndSettle();
      expect(find.text('JOIN US'), findsOneWidget);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.byType(LoginPage), findsOneWidget);
      container.read(sessionProvider.notifier).enterDemo();
      await tester.pumpAndSettle();
      final router = container.read(routerProvider);
      router.go('/sign-up');
      await tester.pumpAndSettle();
      expect(router.routeInformationProvider.value.uri.path, '/home');
      router.go('/sign-up/address');
      await tester.pumpAndSettle();
      expect(router.routeInformationProvider.value.uri.path, '/home');
    },
  );

  for (final width in [320.0, 375.0, 390.0, 430.0]) {
    for (final scale in [1.0, 1.5, 2.0]) {
      testWidgets('Signup both steps and overlays fit $width / $scale', (
        tester,
      ) async {
        await openSignUp(tester, width: width, scale: scale);
        await fillStep1(tester);
        await next(tester);
        await chooseAddress(tester);
        final state = find.byKey(const ValueKey('signup-state'));
        await tester.ensureVisible(state);
        await tester.tap(state);
        await tester.pumpAndSettle();
        await tester.tap(find.widgetWithText(MenuItemButton, 'AL'));
        await tester.pumpAndSettle();
        await tester.ensureVisible(button('Join'));
        expect(tester.getRect(button('Join')).right, lessThanOrEqualTo(width));
        expect(tester.takeException(), isNull);
      });
    }
  }

  testWidgets('Keyboard resize leaves final fields and Join reachable', (
    tester,
  ) async {
    await openSignUp(tester, width: 320, height: 568);
    await fillStep1(tester);
    await next(tester);
    tester.view.viewInsets = const FakeViewPadding(bottom: 250);
    addTearDown(tester.view.resetViewInsets);
    await tester.pump();
    await chooseAddress(tester);
    await enter(tester, 'zip', '01234');
    await tester.ensureVisible(button('Join'));
    await tester.pumpAndSettle();
    expect(tester.getRect(button('Join')).bottom, lessThanOrEqualTo(318));
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'Submit hook is normalized, rejects duplicate calls and recovers errors',
    (tester) async {
      final container = ProviderContainer();
      final subscription = container.listen(signUpProvider, (_, _) {});
      container
          .read(signUpProvider.notifier)
          .update(validAll.copyWith(nickname: ' Sam '));
      final pending = Completer<void>();
      var calls = 0;
      SignUpDraft? submitted;
      addTearDown(() {
        subscription.close();
        container.dispose();
      });
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            theme: buildTheme(Brightness.light),
            home: SignUpAddressPage(
              onSubmit: (draft) {
                calls++;
                submitted = draft;
                return pending.future;
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.ensureVisible(button('Join'));
      await tester.tap(button('Join'));
      await tester.pump();
      expect(calls, 1);
      expect(submitted!.nickname, 'Sam');
      expect(tester.widget<FilledButton>(button('Join')).onPressed, isNull);
      pending.completeError(StateError('Sensitive backend information'));
      await tester.pumpAndSettle();
      expect(find.text('Unable to submit. Please try again.'), findsOneWidget);
      expect(find.textContaining('Sensitive'), findsNothing);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
}
