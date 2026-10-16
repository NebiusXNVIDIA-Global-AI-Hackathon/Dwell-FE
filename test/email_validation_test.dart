import 'package:dwell/features/auth/models/email_validation.dart';
import 'package:dwell/features/auth/models/sign_up_draft.dart';
import 'package:dwell/features/auth/widgets/login_form.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  const valid = ["o'neil", 'sam.smith', 'a+b', '!#%&*+/=?^_`{|}~-', ' sam '];
  const invalid = ['', 'a b', r'a\b', '.sam', 'sam.', 'a..b', 'a@b', '한글'];

  test(
    'Shared local-part validation and signup agree on special characters',
    () {
      for (final value in [...valid, ...invalid]) {
        final expected = valid.contains(value);
        expect(isValidEmailLocalPart(value), expected, reason: value);
        expect(
          SignUpDraft(
            emailLocalPart: value,
            emailDomain: 'naver.com',
          ).validEmail,
          expected,
          reason: value,
        );
      }
    },
  );

  testWidgets(
    'Login applies shared validation without changing password policy',
    (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: SingleChildScrollView(child: LoginForm())),
        ),
      );
      await tester.tap(find.byKey(const ValueKey('email-domain')));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(MenuItemButton, 'naver.com'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const ValueKey('login-password')), 'x');
      for (final value in [...valid, ...invalid]) {
        await tester.enterText(
          find.byKey(const ValueKey('login-email')),
          value,
        );
        await tester.pump();
        expect(
          tester
                  .widget<FilledButton>(
                    find.byKey(const ValueKey('login-submit')),
                  )
                  .onPressed !=
              null,
          valid.contains(value),
          reason: value,
        );
      }
    },
  );
}
