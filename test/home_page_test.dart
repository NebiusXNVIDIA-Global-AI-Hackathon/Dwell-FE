import 'dart:io';
import 'dart:ui' as ui;

import 'package:dwell/core/layouts/main_layout.dart';
import 'package:dwell/core/widgets/app_screen_header.dart';
import 'package:dwell/core/widgets/profile_avatar.dart';
import 'package:dwell/core/widgets/bottom_nav_bar.dart';
import 'package:dwell/features/home/widgets/current_case_card.dart';
import 'package:dwell/features/home/widgets/needs_attention_card.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'helpers/case_creation_test_harness.dart';

Future<CreationHarness> openHome(
  WidgetTester tester, {
  Size size = const Size(390, 844),
  double scale = 1,
}) async {
  final h = await CreationHarness.start(
    tester,
    size: size,
    textScale: scale,
    direct: true,
  );
  tester.view.padding = const FakeViewPadding(top: 44);
  tester.view.viewPadding = const FakeViewPadding(top: 44);
  addTearDown(tester.view.resetPadding);
  addTearDown(tester.view.resetViewPadding);
  h.router.go('/home');
  await tester.pumpAndSettle();
  return h;
}

void main() {
  setUpAll(loadCreationTestFonts);

  for (final insets in [
    const EdgeInsets.only(top: 24),
    const EdgeInsets.only(top: 32, bottom: 24),
    const EdgeInsets.only(top: 48, bottom: 48),
  ]) {
    testWidgets(
      'Home applies system insets once and scopes bar styling at $insets',
      (tester) async {
        final h = await openHome(tester);
        tester.view.padding = FakeViewPadding(
          top: insets.top,
          bottom: insets.bottom,
        );
        tester.view.viewPadding = FakeViewPadding(
          top: insets.top,
          bottom: insets.bottom,
        );
        await tester.pumpAndSettle();
        final logo = find.byWidgetPredicate(
          (widget) =>
              widget is SvgPicture &&
              widget.bytesLoader is SvgAssetLoader &&
              (widget.bytesLoader as SvgAssetLoader).assetName ==
                  'assets/icons/dwell_logo.svg',
        );
        expect(logo, findsOneWidget);
        expect(tester.getRect(logo).top, insets.top + 22);
        final nav = find.byType(BottomNavBar);
        expect(tester.getSize(nav).height, 80 + insets.bottom);
        final systemStyle = find.byType(AnnotatedRegion<SystemUiOverlayStyle>);
        final style = tester
            .widget<AnnotatedRegion<SystemUiOverlayStyle>>(systemStyle)
            .value;
        expect(style.statusBarColor, const Color(0xFFF8F8F8));
        expect(style.statusBarIconBrightness, Brightness.dark);
        expect(style.systemNavigationBarIconBrightness, Brightness.dark);
        final headerRect = tester.getRect(find.byType(AppScreenHeader));
        final avatarRect = tester.getRect(find.byType(ProfileAvatar));
        final scroll = find.byKey(const ValueKey('home-scroll'));
        final position = tester
            .state<ScrollableState>(
              find
                  .descendant(of: scroll, matching: find.byType(Scrollable))
                  .first,
            )
            .position;
        position.jumpTo(position.maxScrollExtent);
        await tester.pumpAndSettle();
        expect(
          tester.getRect(find.byKey(const ValueKey('home-check-unit'))).bottom,
          lessThan(tester.getRect(nav).top),
        );
        h.router.go('/cases');
        await tester.pumpAndSettle();
        expect(tester.getRect(find.byType(AppScreenHeader)), headerRect);
        expect(tester.getRect(find.byType(ProfileAvatar)), avatarRect);
        expect(systemStyle, findsNothing);
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets(
    'Home starts at top and scrolls behind fixed navigation to the final action',
    (tester) async {
      await openHome(tester);
      final scroll = find.byKey(const ValueKey('home-scroll'));
      final position = tester
          .state<ScrollableState>(
            find
                .descendant(of: scroll, matching: find.byType(Scrollable))
                .first,
          )
          .position;
      final nav = find.byType(BottomNavBar);
      final initialNav = tester.getRect(nav);
      final card = tester.getRect(find.byType(CurrentCaseCard));
      final action = find.byKey(const ValueKey('home-check-unit'));
      expect(position.pixels, 0);
      expect(tester.widget<BottomNavBar>(nav).currentIndex, 2);
      expect(tester.widget<BottomNavBar>(nav).casesLabel, 'Cases');
      expect(tester.getRect(action).bottom, greaterThan(initialNav.top));
      final shell = find
          .descendant(
            of: find.byType(MainLayout),
            matching: find.byType(Scaffold),
          )
          .first;
      expect(tester.widget<Scaffold>(shell).extendBody, true);

      await tester.drag(scroll, const Offset(0, -500));
      await tester.pumpAndSettle();
      expect(position.pixels, greaterThan(0));
      expect(tester.getRect(nav), initialNav);
      expect(
        tester.getRect(find.byType(CurrentCaseCard)).top,
        lessThan(card.top),
      );
      expect(tester.getRect(action).bottom, lessThan(initialNav.top));
      expect(action.hitTestable(), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Checklist toggles locally and existing routes keep other shell layouts unchanged',
    (tester) async {
      final h = await openHome(tester);
      final box = find.byKey(const ValueKey('home-checklist-0'));
      await tester.ensureVisible(box);
      await tester.tap(box);
      await tester.pumpAndSettle();
      expect(tester.widget<Checkbox>(box).value, true);
      await tester.tap(box);
      await tester.pumpAndSettle();
      expect(tester.widget<Checkbox>(box).value, false);
      final view = find.widgetWithText(FilledButton, 'View Case');
      await tester.ensureVisible(view);
      await tester.tap(view);
      await tester.pumpAndSettle();
      expect(h.router.routeInformationProvider.value.uri.path, '/cases');
      expect(
        tester.widget<BottomNavBar>(find.byType(BottomNavBar)).casesLabel,
        'Reports',
      );
      final shell = find
          .descendant(
            of: find.byType(MainLayout),
            matching: find.byType(Scaffold),
          )
          .first;
      expect(tester.widget<Scaffold>(shell).extendBody, false);
      h.router.go('/home');
      await tester.pumpAndSettle();
      final action = find.byKey(const ValueKey('home-check-unit'));
      await tester.ensureVisible(action);
      await tester.pumpAndSettle();
      await tester.tap(action);
      await tester.pumpAndSettle();
      expect(h.router.routeInformationProvider.value.uri.path, '/my-place');
      expect(tester.takeException(), isNull);
    },
  );

  for (final size in [
    const Size(320, 568),
    const Size(375, 667),
    const Size(390, 844),
    const Size(430, 932),
    const Size(1280, 900),
  ]) {
    for (final scale in [1.0, 1.5, 2.0]) {
      testWidgets(
        'Home at $size/$scale keeps the final button reachable without overflow',
        (tester) async {
          await openHome(tester, size: size, scale: scale);
          final scroll = find.byKey(const ValueKey('home-scroll'));
          final state = tester.state<ScrollableState>(
            find
                .descendant(of: scroll, matching: find.byType(Scrollable))
                .first,
          );
          state.position.jumpTo(state.position.maxScrollExtent);
          await tester.pumpAndSettle();
          final action = find.byKey(const ValueKey('home-check-unit'));
          expect(
            tester.getRect(action).bottom,
            lessThan(tester.getRect(find.byType(BottomNavBar)).top),
          );
          expect(action.hitTestable(), findsOneWidget);
          expect(find.byType(NeedsAttentionCard), findsOneWidget);
          expect(tester.takeException(), isNull);
        },
      );
    }
  }

  if (const bool.fromEnvironment('DWELL_HOME_PREVIEW')) {
    testWidgets('Home rendering previews', (tester) async {
      await openHome(tester);
      Future<void> capture(String name) async {
        final boundary = tester.renderObject<RenderRepaintBoundary>(
          find.byType(RepaintBoundary).first,
        );
        await tester.runAsync(() async {
          final image = await boundary.toImage(pixelRatio: 2);
          final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
          image.dispose();
          final directory = Directory(
            '${Directory.systemTemp.path}/dwell-diagnostics',
          );
          await directory.create(recursive: true);
          await File('${directory.path}/home-$name.png')
              .writeAsBytes(bytes!.buffer.asUint8List());
        });
      }

      await capture('initial');
      await tester.drag(
        find.byKey(const ValueKey('home-scroll')),
        const Offset(0, -500),
      );
      await tester.pumpAndSettle();
      await capture('scrolled');
    });
  }
}
