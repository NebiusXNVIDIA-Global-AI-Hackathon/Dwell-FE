import 'package:dwell/app.dart';
import 'package:dwell/core/router.dart';
import 'package:dwell/core/widgets/bottom_nav_bar.dart';
import 'package:dwell/features/home/home_page.dart';
import 'package:dwell/features/cases/pages/cases_page.dart';
import 'package:dwell/features/splash/splash_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  for (final width in [320.0, 375.0, 390.0, 430.0, 1440.0]) {
    for (final scale in [1.0, 2.0]) {
      testWidgets('Splash fits width $width and text scale $scale', (
        tester,
      ) async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = Size(width, 844);
        addTearDown(tester.view.resetDevicePixelRatio);
        addTearDown(tester.view.resetPhysicalSize);
        await tester.pumpWidget(
          MaterialApp(
            home: MediaQuery(
              data: MediaQueryData(
                size: Size(width, 844),
                textScaler: TextScaler.linear(scale),
              ),
              child: const SplashPage(),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.text('Dwell'), findsOneWidget);
        expect(find.text('Live well\nwhere you dwell'), findsOneWidget);
        final svg = tester.widget<SvgPicture>(find.byType(SvgPicture));
        expect(
          (svg.bytesLoader as SvgAssetLoader).assetName,
          'assets/icons/dwell_logo.svg',
        );
        final rect = tester.getRect(find.byKey(const ValueKey('splash-logo')));
        expect(rect.left, greaterThanOrEqualTo(12));
        expect(rect.right, lessThanOrEqualTo(width - 12));
        expect(rect.width, lessThanOrEqualTo(386));
        expect(rect.center.dx, closeTo(width / 2, 0.01));
        expect(rect.center.dy, closeTo(422, 0.01));
        expect(find.byType(BottomNavBar), findsNothing);
        expect(find.byType(Scrollable), findsNothing);
        expect(tester.takeException(), isNull);
      });
    }
  }

  testWidgets('System insets protect logo without changing full background', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(
            size: Size(800, 600),
            padding: EdgeInsets.only(top: 44, bottom: 24),
          ),
          child: SplashPage(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final rect = tester.getRect(find.byKey(const ValueKey('splash-logo')));
    expect(rect.center.dy, closeTo(310, 0.01));
    final region = tester.widget<AnnotatedRegion<SystemUiOverlayStyle>>(
      find.byType(AnnotatedRegion<SystemUiOverlayStyle>).first,
    );
    expect(region.value.statusBarIconBrightness, Brightness.dark);
    expect(region.value.systemNavigationBarIconBrightness, Brightness.dark);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'Initial and root routes show Splash; existing pages remain accessible',
    (tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final router = container.read(routerProvider);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const DwellApp(),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(SplashPage), findsOneWidget);
      await tester.pump(const Duration(seconds: 30));
      expect(find.byType(SplashPage), findsOneWidget);
      router.go('/home');
      await tester.pumpAndSettle();
      expect(find.byType(HomePage), findsOneWidget);
      expect(find.byType(BottomNavBar), findsOneWidget);
      router.go('/cases');
      await tester.pumpAndSettle();
      expect(find.byType(CasesPage), findsOneWidget);
      router.go('/');
      await tester.pumpAndSettle();
      expect(find.byType(SplashPage), findsOneWidget);
      expect(find.byType(BottomNavBar), findsNothing);
    },
  );
}
