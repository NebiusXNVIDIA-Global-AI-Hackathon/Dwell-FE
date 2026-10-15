import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import '../widgets/login_form.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({super.key, this.onLogin, this.onDemo, this.onSignUp});
  final Future<void> Function(String email, String password)? onLogin;
  final Future<void> Function()? onDemo;
  final VoidCallback? onSignUp;

  @override
  Widget build(BuildContext context) {
    final top =
        (MediaQuery.sizeOf(context).height * .195 -
                MediaQuery.paddingOf(context).top)
            .clamp(24.0, 164.0);
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
        systemNavigationBarColor: Color(0xFFF8F8F8),
        systemNavigationBarIconBrightness: Brightness.dark,
        systemStatusBarContrastEnforced: false,
        systemNavigationBarContrastEnforced: false,
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFFF8F8F8),
        body: SafeArea(
          child: SingleChildScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: EdgeInsets.fromLTRB(34, top, 34, 40),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 400),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'LOGIN',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Color(0xFF243B53),
                        fontSize: 48,
                        fontWeight: FontWeight.w800,
                        height: 1.1,
                      ),
                    ),
                    const SizedBox(height: 52),
                    LoginForm(
                      onLogin: onLogin,
                      onDemo: onDemo,
                      onSignUp: onSignUp,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
