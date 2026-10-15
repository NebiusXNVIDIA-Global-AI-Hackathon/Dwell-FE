import 'package:dwell/features/auth/pages/login_page.dart';
import 'package:dwell/features/auth/pages/sign_up_page.dart';
import 'package:dwell/features/auth/widgets/email_domain_dropdown.dart';
import 'package:dwell/features/auth/widgets/email_input_row.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'demo_navigation_test.dart' show startApp;
import 'helpers/case_creation_test_harness.dart' show loadCreationTestFonts;

void main() {
  setUpAll(loadCreationTestFonts);
  for (final signUp in [false, true]) {
    for (final width in [320.0, 375.0, 390.0, 430.0]) {
      for (final scale in [1.0, 1.5, 2.0]) {
        testWidgets(
          '${signUp ? 'Signup' : 'Login'} domains stay unwrapped at $width / $scale',
          (tester) async {
            await startApp(
              tester,
              path: signUp ? '/sign-up' : '/login',
              size: Size(width, 844),
              scale: scale,
            );
            await tester.pumpAndSettle();
            final control = find.byKey(const ValueKey('email-domain'));
            final input = find.byKey(
              ValueKey(signUp ? 'signup-email' : 'login-email'),
            );
            for (final value in EmailDomainDropdown.domains) {
              await tester.ensureVisible(control);
              await tester.tap(control);
              await tester.pumpAndSettle();
              final option = find.widgetWithText(MenuItemButton, value);
              final optionText = find.descendant(
                of: option,
                matching: find.text(value),
              );
              final optionParagraph = tester.renderObject<RenderParagraph>(
                optionText,
              );
              final optionRect = tester.getRect(option);
              expect(optionRect.left, greaterThanOrEqualTo(0));
              expect(optionRect.right, lessThanOrEqualTo(width));
              expect(
                optionParagraph.getMaxIntrinsicWidth(double.infinity),
                lessThanOrEqualTo(optionParagraph.size.width + .1),
              );
              await tester.tap(option);
              await tester.pumpAndSettle();
              expect(find.byType(MenuItemButton), findsNothing);
              final selected = find.descendant(
                of: control,
                matching: find.text(value),
              );
              final text = tester.widget<Text>(selected);
              expect(text.maxLines, 1);
              expect(text.softWrap, isFalse);
              expect(text.overflow, isNot(TextOverflow.ellipsis));
              final paragraph = tester.renderObject<RenderParagraph>(selected);
              expect(
                paragraph.getMaxIntrinsicWidth(double.infinity),
                lessThanOrEqualTo(paragraph.size.width + .1),
              );
              final inputRect = tester.getRect(input);
              final domainRect = tester.getRect(control);
              final arrowRect = tester.getRect(
                find.descendant(of: control, matching: find.byType(Icon)).last,
              );
              expect(arrowRect.right, lessThanOrEqualTo(domainRect.right));
              expect(arrowRect.left, greaterThanOrEqualTo(domainRect.left));
              expect(domainRect.height, closeTo(inputRect.height, .1));
              if (domainRect.top < inputRect.bottom) {
                expect(domainRect.center.dy, closeTo(inputRect.center.dy, .1));
              } else {
                expect(scale, greaterThan(1));
                expect(
                  domainRect.top,
                  greaterThanOrEqualTo(inputRect.bottom + 9),
                );
              }
              final hint = tester.renderObject<RenderParagraph>(
                find.descendant(
                  of: input,
                  matching: find.text('Enter your email'),
                ),
              );
              expect(
                hint.getMaxIntrinsicWidth(double.infinity),
                lessThanOrEqualTo(hint.size.width + .1),
                reason:
                    'Input ${inputRect.width}; padding ${tester.widget<TextField>(input).decoration!.contentPadding}',
              );
              expect(domainRect.left, greaterThanOrEqualTo(34 - .1));
              expect(domainRect.right, lessThanOrEqualTo(width - 34 + .1));
              expect(inputRect.left, closeTo(34, .1));
              expect(inputRect.right, lessThanOrEqualTo(width - 34 + .1));
              expect(
                find.descendant(
                  of: find.byType(EmailInputRow),
                  matching: find.byType(SingleChildScrollView),
                ),
                findsNothing,
              );
              if (scale == 1) {
                expect(domainRect.top, closeTo(inputRect.top, .1));
              }
              if (signUp &&
                  value == EmailDomainDropdown.domains.first &&
                  scale == 1) {
                debugPrint(
                  'Email geometry at $width: available=${width - 68}, input=${inputRect.width}, domain=${domainRect.width}, at=${domainRect.left - inputRect.right}',
                );
              }
              expect(tester.takeException(), isNull);
            }
            expect(
              find.byType(signUp ? SignUpPage : LoginPage),
              findsOneWidget,
            );
          },
        );
      }
    }
  }
}
