import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:material_ui/material_ui.dart';

import 'email_domain_dropdown.dart';

/// Integration hooks never create a session or navigate on their own.
class LoginForm extends StatefulWidget {
  const LoginForm({super.key, this.onLogin, this.onDemo, this.onSignUp});
  final Future<void> Function(String email, String password)? onLogin;
  final Future<void> Function()? onDemo;
  final VoidCallback? onSignUp;

  @override
  State<LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends State<LoginForm> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  String? _domain;
  bool _hidden = true;
  bool _busy = false;
  String? _notice;

  bool get _valid {
    final local = _email.text.trim();
    return _domain != null &&
        RegExp(
          r'^[a-zA-Z0-9!#$%&\x27*+/=?^_`{|}~-]+(?:\.[a-zA-Z0-9!#$%&\x27*+/=?^_`{|}~-]+)*$',
        ).hasMatch(local) &&
        _password.text.trim().isNotEmpty;
  }

  Future<void> _run(Future<void> Function()? action, String unavailable) async {
    if (_busy) return;
    FocusManager.instance.primaryFocus?.unfocus();
    if (action == null) {
      setState(() => _notice = unavailable);
      return;
    }
    setState(() {
      _busy = true;
      _notice = null;
    });
    try {
      await action();
    } catch (_) {
      if (mounted) {
        setState(
          () => _notice = 'Unable to complete this request. Please try again.',
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  InputDecoration _decoration(String hint, {Widget? suffix}) => InputDecoration(
    hintText: hint,
    hintStyle: const TextStyle(
      color: Color(0xFFAAAAAA),
      fontSize: 16,
      height: 1.2,
    ),
    filled: true,
    fillColor: const Color(0xFFFCFCFC),
    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: Color(0xFF666666)),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: Color(0xFF666666)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: Color(0xFF243B53)),
    ),
    suffixIcon: suffix,
  );

  Widget _button(
    String label,
    VoidCallback? action,
    Color color,
    Color pressed, {
    Key? key,
  }) => FilledButton(
    key: key,
    onPressed: action,
    style: ButtonStyle(
      minimumSize: const WidgetStatePropertyAll(Size.fromHeight(56)),
      padding: const WidgetStatePropertyAll(
        EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
      backgroundColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.disabled)
            ? const Color(0xFFE5E5E5)
            : states.contains(WidgetState.pressed)
            ? pressed
            : color,
      ),
      foregroundColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.disabled)
            ? const Color(0xFF606060)
            : Colors.white,
      ),
      overlayColor: const WidgetStatePropertyAll(Colors.transparent),
      splashFactory: NoSplash.splashFactory,
      elevation: const WidgetStatePropertyAll(0),
      side: WidgetStateProperty.resolveWith(
        (states) => BorderSide(
          color: states.contains(WidgetState.disabled)
              ? const Color(0xFF666666)
              : const Color(0xFF192D3C),
        ),
      ),
      shape: WidgetStatePropertyAll(
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      textStyle: const WidgetStatePropertyAll(
        TextStyle(
          fontFamily: 'Pretendard Variable',
          fontSize: 16,
          fontWeight: FontWeight.w700,
        ),
      ),
    ),
    child: Text(label, textAlign: TextAlign.center),
  );

  @override
  Widget build(BuildContext context) => AutofillGroup(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Email Address',
          style: TextStyle(color: Color(0xFF606060), fontSize: 16, height: 1.2),
        ),
        const SizedBox(height: 10),
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              flex: 7,
              child: TextField(
                key: const ValueKey('login-email'),
                controller: _email,
                enabled: !_busy,
                autocorrect: false,
                enableSuggestions: false,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                style: const TextStyle(fontSize: 16, height: 1.2),
                decoration: _decoration('Enter your email'),
                onChanged: (_) => setState(() => _notice = null),
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                '@',
                style: TextStyle(color: Color(0xFF606060), fontSize: 20),
              ),
            ),
            Expanded(
              flex: 4,
              child: EmailDomainDropdown(
                value: _domain,
                enabled: !_busy,
                onChanged: (domain) => setState(() {
                  _domain = domain;
                  _notice = null;
                }),
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        const Text(
          'Password',
          style: TextStyle(color: Color(0xFF606060), fontSize: 16, height: 1.2),
        ),
        const SizedBox(height: 10),
        TextField(
          key: const ValueKey('login-password'),
          controller: _password,
          enabled: !_busy,
          obscureText: _hidden,
          autocorrect: false,
          enableSuggestions: false,
          autofillHints: const [AutofillHints.password],
          textInputAction: TextInputAction.done,
          style: const TextStyle(fontSize: 16, height: 1.2),
          onChanged: (_) => setState(() => _notice = null),
          onSubmitted: (_) {
            if (_valid && !_busy) _submit();
          },
          decoration: _decoration(
            'Enter your password',
            suffix: IconButton(
              tooltip: _hidden ? 'Show password' : 'Hide password',
              onPressed: _busy
                  ? null
                  : () => setState(() => _hidden = !_hidden),
              icon: Icon(
                _hidden ? LucideIcons.eyeOff : LucideIcons.eye,
                color: const Color(0xFF606060),
                size: 24,
              ),
              style: const ButtonStyle(
                overlayColor: WidgetStatePropertyAll(Colors.transparent),
                splashFactory: NoSplash.splashFactory,
              ),
            ),
          ),
        ),
        const SizedBox(height: 26),
        _button(
          'Login',
          _valid && !_busy ? _submit : null,
          const Color(0xFF243B53),
          const Color(0xFF506477),
          key: const ValueKey('login-submit'),
        ),
        const SizedBox(height: 10),
        _button(
          'Try a demo account',
          _busy
              ? null
              : () => _run(widget.onDemo, 'Demo mode is not connected yet.'),
          const Color(0xFF2B575F),
          const Color(0xFF527078),
          key: const ValueKey('login-demo'),
        ),
        if (_busy)
          const Padding(
            padding: EdgeInsets.only(top: 16),
            child: Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          ),
        if (_notice != null)
          Padding(
            padding: const EdgeInsets.only(top: 16),
            child: Semantics(
              liveRegion: true,
              child: Text(
                _notice!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Color(0xFF606060)),
              ),
            ),
          ),
        const SizedBox(height: 26),
        Wrap(
          alignment: WrapAlignment.center,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 8,
          children: [
            const Text(
              "Don't have an account?",
              style: TextStyle(fontSize: 16, color: Color(0xFF606060)),
            ),
            TextButton(
              onPressed: _busy
                  ? null
                  : () {
                      if (widget.onSignUp != null) {
                        widget.onSignUp!();
                      } else {
                        setState(
                          () => _notice = 'Sign up is not connected yet.',
                        );
                      }
                    },
              style: const ButtonStyle(
                padding: WidgetStatePropertyAll(EdgeInsets.zero),
                foregroundColor: WidgetStatePropertyAll(Color(0xFF3D907E)),
                overlayColor: WidgetStatePropertyAll(Colors.transparent),
                splashFactory: NoSplash.splashFactory,
                textStyle: WidgetStatePropertyAll(
                  TextStyle(
                    fontFamily: 'Pretendard Variable',
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              child: const Text('Sign up'),
            ),
          ],
        ),
      ],
    ),
  );

  void _submit() {
    if (!_valid || _busy) return;
    final email = '${_email.text.trim()}@$_domain';
    final password = _password.text;
    _run(
      widget.onLogin == null ? null : () => widget.onLogin!(email, password),
      'Login is not connected yet.',
    );
  }
}
