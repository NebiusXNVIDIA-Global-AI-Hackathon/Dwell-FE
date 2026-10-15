import 'package:dwell/core/widgets/app_screen_header.dart';
import 'package:dwell/core/widgets/profile_avatar.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  for (final inset in [0.0, 24.0, 48.0]) {
    testWidgets(
      'Shared header uses one native inset and ignores web inset $inset',
      (tester) async {
        tester.view.physicalSize = const Size(390, 844);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              home: MediaQuery(
                data: MediaQueryData(
                  size: const Size(390, 844),
                  padding: EdgeInsets.only(top: inset),
                ),
                child: Builder(
                  builder: (context) => Scaffold(
                    body: Padding(
                      padding: EdgeInsets.only(
                        top: AppScreenHeader.systemTopInset(context),
                      ),
                      child: const AppScreenHeader(
                        webTopPadding: 70,
                        title: Text('Cases'),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
        final title = tester.getRect(find.text('Cases'));
        final avatar = tester.getRect(find.byType(ProfileAvatar));
        final expectedTop = kIsWeb ? 70.0 : inset + 22;
        expect(title.left, 22);
        expect(avatar.right, 390 - 22);
        expect(avatar.center.dy, expectedTop + 24);
        expect(avatar.size, const Size(42, 42));
        expect(tester.takeException(), isNull);
      },
    );
  }
}
