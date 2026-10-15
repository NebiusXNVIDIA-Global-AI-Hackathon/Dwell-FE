import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../providers/sign_up_provider.dart';
import '../widgets/email_domain_dropdown.dart';
import '../widgets/email_input_row.dart';
import '../widgets/sign_up_components.dart';

class SignUpPage extends ConsumerStatefulWidget {
  const SignUpPage({super.key});
  @override
  ConsumerState<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends ConsumerState<SignUpPage> {
  late final TextEditingController _nickname, _password, _confirm, _email;
  @override
  void initState() {
    super.initState();
    final draft = ref.read(signUpProvider);
    _nickname = TextEditingController(text: draft.nickname);
    _password = TextEditingController(text: draft.password);
    _confirm = TextEditingController(text: draft.confirmPassword);
    _email = TextEditingController(text: draft.emailLocalPart);
  }

  @override
  void dispose() {
    for (final controller in [_nickname, _password, _confirm, _email]) {
      controller.dispose();
    }
    super.dispose();
  }

  void _next() {
    if (!ref.read(signUpProvider).canContinue) return;
    FocusManager.instance.primaryFocus?.unfocus();
    // Nested declarative routes retain Step 1 and also update browser history.
    context.goNamed('sign-up-address');
  }

  @override
  Widget build(BuildContext context) {
    final draft = ref.watch(signUpProvider);
    final controller = ref.read(signUpProvider.notifier);
    return BackButtonListener(
      onBackButtonPressed: () async {
        if (GoRouter.of(context).canPop()) return false;
        context.go('/login');
        return true;
      },
      child: SignUpScaffold(
        title: 'JOIN US',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SignUpField(
              label: 'Nickname',
              child: TextField(
                key: const ValueKey('signup-nickname'),
                controller: _nickname,
                textInputAction: TextInputAction.next,
                style: const TextStyle(fontSize: 16, height: 1.2),
                decoration: signUpDecoration('Enter your nickname'),
                onChanged: (value) => controller.update(
                  ref.read(signUpProvider).copyWith(nickname: value),
                ),
              ),
            ),
            const SizedBox(height: 14),
            SignUpPasswordField(
              label: 'Password',
              controller: _password,
              error: draft.passwordError,
              onChanged: (value) => controller.update(
                ref
                    .read(signUpProvider)
                    .copyWith(password: value, passwordTouched: true),
              ),
            ),
            const SizedBox(height: 14),
            SignUpPasswordField(
              label: 'Confirm Password',
              controller: _confirm,
              confirm: true,
              error: draft.confirmError,
              onChanged: (value) => controller.update(
                ref
                    .read(signUpProvider)
                    .copyWith(confirmPassword: value, confirmTouched: true),
              ),
            ),
            const SizedBox(height: 14),
            SignUpField(
              label: 'Email Address',
              child: EmailInputRow(
                inputBuilder: (padding) => TextField(
                  key: const ValueKey('signup-email'),
                  controller: _email,
                  keyboardType: TextInputType.emailAddress,
                  autocorrect: false,
                  enableSuggestions: false,
                  style: const TextStyle(fontSize: 16, height: 1.2),
                  decoration: emailInputDecoration(
                    signUpDecoration('Enter your email'),
                    padding,
                  ),
                  onChanged: (value) => controller.update(
                    ref.read(signUpProvider).copyWith(emailLocalPart: value),
                  ),
                ),
                dropdown: EmailDomainDropdown(
                  value: draft.emailDomain.isEmpty ? null : draft.emailDomain,
                  showSelectionMark: true,
                  onChanged: (value) => controller.update(
                    ref.read(signUpProvider).copyWith(emailDomain: value),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 26),
            SignUpButton(
              label: 'Next',
              onPressed: draft.canContinue ? _next : null,
            ),
          ],
        ),
      ),
    );
  }
}
