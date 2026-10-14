import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dwell/app.dart';
import 'package:dwell/core/router.dart';

import 'package:dwell/core/widgets/profile_avatar.dart';
import 'package:dwell/core/widgets/profile_menu.dart';
import 'package:dwell/core/widgets/logout_confirmation_dialog.dart';
import 'package:dwell/core/widgets/bottom_nav_bar.dart';
import 'package:dwell/features/my_page/my_page.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'home_page_test.dart' show openHome;
import 'helpers/case_creation_test_harness.dart';

Finder item(String label) => find.widgetWithText(MenuItemButton, label);
Finder avatar() => find.byType(ProfileAvatar);
Future<void> openMenu(WidgetTester tester) async {
  if (avatar().hitTestable().evaluate().isEmpty) {
    await tester.ensureVisible(avatar());
  }
  await tester.pumpAndSettle();
  await tester.tap(avatar());
  await tester.pumpAndSettle();
}

Future<void> openDialog(WidgetTester tester) async {
  await openMenu(tester);
  await tester.tap(item('Log out'));
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(loadCreationTestFonts);

  for (final path in ['/home', '/cases']) {
    testWidgets(
      '$path menu anchors to avatar, toggles and dismisses without changing layout',
      (tester) async {
        final h = await openHome(tester);
        h.router.go(path);
        await tester.pumpAndSettle();
        final before = tester.getRect(avatar());
        final nav = tester.getRect(find.byType(BottomNavBar));
        await openMenu(tester);
        expect(item('My Page'), findsOneWidget);
        expect(item('Log out'), findsOneWidget);
        expect(tester.getRect(item('My Page')).right, closeTo(before.right, 1));
        expect(
          tester.getRect(item('My Page')).top,
          greaterThanOrEqualTo(before.bottom),
        );
        expect(tester.getRect(avatar()), before);
        expect(tester.getRect(find.byType(BottomNavBar)), nav);
        await tester.tap(avatar());
        await tester.pumpAndSettle();
        expect(item('Log out'), findsNothing);
        await openMenu(tester);
        await tester.tapAt(const Offset(5, 300));
        await tester.pumpAndSettle();
        expect(item('Log out'), findsNothing);
        await openMenu(tester);
        h.router.go('/my-place');
        await tester.pumpAndSettle();
        expect(item('Log out'), findsNothing);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets('$path My Page selects existing bottom-nav branch', (
      tester,
    ) async {
      final h = await openHome(tester);
      h.router.go(path);
      await tester.pumpAndSettle();
      await openMenu(tester);
      await tester.tap(item('My Page'));
      await tester.pumpAndSettle();
      expect(h.router.routeInformationProvider.value.uri.path, '/my-page');
      expect(find.byType(MyPage), findsOneWidget);
      expect(
        tester.widget<BottomNavBar>(find.byType(BottomNavBar)).currentIndex,
        4,
      );
      expect(item('Log out'), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets(
      '$path logout confirmation covers navigation, blocks outside touches and closes on Back',
      (tester) async {
        final h = await openHome(tester);
        h.router.go(path);
        await tester.pumpAndSettle();
        await openMenu(tester);
        final action = tester
            .widget<MenuItemButton>(item('Log out'))
            .onPressed!;
        action();
        action();
        await tester.pumpAndSettle();
        expect(find.byType(LogoutConfirmationDialog), findsOneWidget);
        expect(item('Log out'), findsNothing);
        final barrier = find.byWidgetPredicate(
          (widget) =>
              widget is ModalBarrier && widget.color == const Color(0x33000000),
        );
        expect(
          tester
              .getRect(barrier)
              .contains(tester.getRect(find.byType(BottomNavBar)).center),
          true,
        );
        final nav = tester.getRect(find.byType(BottomNavBar));
        await tester.tapAt(Offset(nav.right - 30, nav.center.dy));
        await tester.pumpAndSettle();
        expect(h.router.routeInformationProvider.value.uri.path, path);
        expect(find.byType(LogoutConfirmationDialog), findsOneWidget);
        await tester.binding.handlePopRoute();
        await tester.pumpAndSettle();
        expect(find.byType(LogoutConfirmationDialog), findsNothing);
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets(
    'Cancel retains selected case, checked items and Home scroll offset',
    (tester) async {
      await openHome(tester);
      await tester.tap(find.byKey(const ValueKey('home-case-C-005')));
      await tester.pumpAndSettle();
      final check = find.byKey(const ValueKey('home-checklist-1'));
      await tester.ensureVisible(check);
      await tester.tap(check);
      await tester.pumpAndSettle();
      final scroll = find.byKey(const ValueKey('home-scroll'));
      final state = tester.state<ScrollableState>(
        find.descendant(of: scroll, matching: find.byType(Scrollable)).first,
      );
      state.position.jumpTo(15);
      await tester.pumpAndSettle();
      final offset = state.position.pixels;
      await tester.tapAt(
        tester.getRect(avatar()).bottomCenter - const Offset(0, 4),
      );
      await tester.pumpAndSettle();
      await tester.tap(item('Log out'));
      await tester.pumpAndSettle();
      final checkRect = tester.getRect(check);
      await tester.tapAt(checkRect.center);
      await tester.pumpAndSettle();
      expect(tester.widget<Checkbox>(check).value, true);
      expect(find.byType(LogoutConfirmationDialog), findsOneWidget);
      await tester.tap(find.widgetWithText(TextButton, 'Cancel'));
      await tester.pumpAndSettle();
      expect(find.text('Roaches'), findsOneWidget);
      expect(tester.widget<Checkbox>(check).value, true);
      expect(state.position.pixels, offset);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Unconnected logout reports missing integration without changing route or session',
    (tester) async {
      final h = await openHome(tester);
      await openDialog(tester);
      await tester.tap(find.widgetWithText(TextButton, 'Log out'));
      await tester.pumpAndSettle();
      expect(find.text('Logout is not connected yet.'), findsOneWidget);
      expect(h.router.routeInformationProvider.value.uri.path, '/home');
      expect(find.byType(LogoutConfirmationDialog), findsOneWidget);
      await tester.tap(find.widgetWithText(TextButton, 'Cancel'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Real handler hook runs once while pending; errors remain retryable',
    (tester) async {
      final pending = Completer<void>();
      var calls = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ProfileMenu(
              nickname: 'SJ',
              onLogout: () {
                calls++;
                return pending.future;
              },
            ),
          ),
        ),
      );
      await openDialog(tester);
      final action = tester
          .widget<TextButton>(find.widgetWithText(TextButton, 'Log out'))
          .onPressed!;
      action();
      action();
      await tester.pump();
      expect(calls, 1);
      expect(
        tester
            .widget<TextButton>(find.widgetWithText(TextButton, 'Cancel'))
            .onPressed,
        isNull,
      );
      pending.completeError(StateError('Network unavailable'));
      await tester.pumpAndSettle();
      expect(find.text('Unable to log out. Please try again.'), findsOneWidget);
      expect(find.byType(LogoutConfirmationDialog), findsOneWidget);
      await tester.tap(find.widgetWithText(TextButton, 'Cancel'));
      await tester.pumpAndSettle();
    },
  );

  testWidgets(
    'Successful real-handler callback closes confirmation exactly once',
    (tester) async {
      final pending = Completer<void>();
      var calls = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ProfileMenu(
              nickname: 'SJ',
              onLogout: () {
                calls++;
                return pending.future;
              },
            ),
          ),
        ),
      );
      await openDialog(tester);
      final action = tester
          .widget<TextButton>(find.widgetWithText(TextButton, 'Log out'))
          .onPressed!;
      action();
      await tester.pump();
      pending.complete();
      await tester.pump();
      action();
      await tester.pumpAndSettle();
      expect(calls, 1);
      expect(find.byType(LogoutConfirmationDialog), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('Profile keyboard activation and Escape close the menu', (
    tester,
  ) async {
    await openHome(tester);
    tester.widget<ProfileAvatar>(avatar()).focusNode!.requestFocus();
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(item('My Page'), findsOneWidget);
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(item('My Page'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  for (final size in [const Size(320, 568), const Size(390, 844)]) {
    for (final scale in [1.0, 2.0]) {
      testWidgets(
        'Menu and dialog at $size/$scale stay readable and within viewport',
        (tester) async {
          await openHome(tester, size: size, scale: scale);
          await openMenu(tester);
          for (final label in ['My Page', 'Log out']) {
            final rect = tester.getRect(item(label));
            expect(rect.left, greaterThanOrEqualTo(0));
            expect(rect.right, lessThanOrEqualTo(size.width));
            expect(rect.bottom, lessThanOrEqualTo(size.height));
            expect(rect.height, greaterThanOrEqualTo(48));
          }
          await tester.tap(item('Log out'));
          await tester.pumpAndSettle();
          expect(find.text('Are you logging out?'), findsOneWidget);
          expect(find.text('Your can always log back'), findsOneWidget);
          await tester.tap(find.widgetWithText(TextButton, 'Cancel'));
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
        },
      );
    }
  }

  if (const bool.fromEnvironment('DWELL_PROFILE_PREVIEW')) {
    testWidgets('Profile menu and logout design previews', (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(390, 844);
      tester.view.padding = const FakeViewPadding(top: 44);
      tester.view.viewPadding = const FakeViewPadding(top: 44);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetPadding);
      addTearDown(tester.view.resetViewPadding);
      // Capture outside MaterialApp so root-overlay menus/dialogs are included.
      final container = ProviderContainer();
      addTearDown(container.dispose);
      container.read(routerProvider).go('/home');
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const RepaintBoundary(
            key: ValueKey('profile-preview'),
            child: DwellApp(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      Future<void> capture(String name) async {
        final boundary = tester.renderObject<RenderRepaintBoundary>(
          find.byKey(const ValueKey('profile-preview')),
        );
        void repaint(RenderObject object) {
          object.markNeedsPaint();
          object.visitChildren(repaint);
        }

        repaint(boundary);
        final shadows = debugDisableShadows;
        debugDisableShadows = false;
        await tester.pump();
        try {
          await tester.runAsync(() async {
            final image = await boundary.toImage(pixelRatio: 2);
            final bytes = await image.toByteData(
              format: ui.ImageByteFormat.png,
            );
            image.dispose();
            final directory = Directory(
              '${Directory.systemTemp.path}/dwell-diagnostics',
            );
            await directory.create(recursive: true);
            await File('${directory.path}/$name.png')
                .writeAsBytes(bytes!.buffer.asUint8List());
          });
        } finally {
          debugDisableShadows = shadows;
        }
      }

      await tester.runAsync(
        () => precacheImage(
          const AssetImage('assets/images/beaver_inspection.png'),
          tester.element(avatar()),
        ),
      );
      await tester.pumpAndSettle();
      await openMenu(tester);
      await capture('profile-dropdown');
      await tester.tap(item('Log out'));
      await tester.pumpAndSettle();
      await capture('logout-dialog');
      await tester.tap(find.widgetWithText(TextButton, 'Cancel'));
      await tester.pumpAndSettle();
    });
  }
}
