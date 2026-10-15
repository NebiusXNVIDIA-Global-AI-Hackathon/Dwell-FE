import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:material_ui/material_ui.dart';

class SignUpScaffold extends StatelessWidget {
  const SignUpScaffold({
    super.key,
    required this.title,
    required this.child,
    this.address = false,
  });
  final String title;
  final Widget child;
  final bool address;

  @override
  Widget build(BuildContext context) {
    final top =
        (MediaQuery.sizeOf(context).height * (address ? .15 : .195) -
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
                    Text(
                      title,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Color(0xFF243B53),
                        fontSize: 48,
                        fontWeight: FontWeight.w800,
                        height: 1.1,
                      ),
                    ),
                    SizedBox(height: address ? 40 : 52),
                    child,
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

InputDecoration signUpDecoration(
  String hint, {
  String? error,
  Widget? suffix,
}) => InputDecoration(
  hintText: hint,
  errorText: error,
  errorMaxLines: 3,
  hintStyle: const TextStyle(
    color: Color(0xFFAAAAAA),
    fontSize: 16,
    height: 1.2,
  ),
  errorStyle: const TextStyle(
    color: Color(0xFFFF0000),
    fontSize: 14,
    height: 1.25,
  ),
  filled: true,
  fillColor: const Color(0xFFFCFCFC),
  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
  enabledBorder: OutlineInputBorder(
    borderRadius: BorderRadius.circular(10),
    borderSide: const BorderSide(color: Color(0xFF666666)),
  ),
  focusedBorder: OutlineInputBorder(
    borderRadius: BorderRadius.circular(10),
    borderSide: const BorderSide(color: Color(0xFF243B53)),
  ),
  errorBorder: OutlineInputBorder(
    borderRadius: BorderRadius.circular(10),
    borderSide: const BorderSide(color: Color(0xFFFF0000)),
  ),
  focusedErrorBorder: OutlineInputBorder(
    borderRadius: BorderRadius.circular(10),
    borderSide: const BorderSide(color: Color(0xFFFF0000)),
  ),
  suffixIcon: suffix,
);

class SignUpField extends StatelessWidget {
  const SignUpField({super.key, required this.label, required this.child});
  final String label;
  final Widget child;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Text(
        label,
        style: const TextStyle(
          color: Color(0xFF606060),
          fontSize: 16,
          height: 1.2,
        ),
      ),
      const SizedBox(height: 10),
      child,
    ],
  );
}

class SignUpPasswordField extends StatefulWidget {
  const SignUpPasswordField({
    super.key,
    required this.label,
    required this.controller,
    required this.onChanged,
    this.error,
    this.confirm = false,
  });
  final String label;
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final String? error;
  final bool confirm;
  @override
  State<SignUpPasswordField> createState() => _SignUpPasswordFieldState();
}

class _SignUpPasswordFieldState extends State<SignUpPasswordField> {
  bool _hidden = true;
  @override
  Widget build(BuildContext context) => SignUpField(
    label: widget.label,
    child: TextField(
      key: ValueKey(widget.confirm ? 'signup-confirm' : 'signup-password'),
      controller: widget.controller,
      onChanged: widget.onChanged,
      obscureText: _hidden,
      autocorrect: false,
      enableSuggestions: false,
      textInputAction: TextInputAction.next,
      style: const TextStyle(fontSize: 16, height: 1.2),
      decoration: signUpDecoration(
        widget.confirm ? 'Re-enter your password' : 'Enter your password',
        error: widget.error,
        suffix: IconButton(
          tooltip:
              '${_hidden ? 'Show' : 'Hide'} ${widget.confirm ? 'confirm password' : 'password'}',
          onPressed: () => setState(() => _hidden = !_hidden),
          icon: Icon(
            _hidden ? LucideIcons.eyeOff : LucideIcons.eye,
            size: 24,
            color: const Color(0xFF606060),
          ),
          style: const ButtonStyle(
            overlayColor: WidgetStatePropertyAll(Colors.transparent),
            splashFactory: NoSplash.splashFactory,
          ),
        ),
      ),
    ),
  );
}

class SignUpButton extends StatelessWidget {
  const SignUpButton({super.key, required this.label, required this.onPressed});
  final String label;
  final VoidCallback? onPressed;
  @override
  Widget build(BuildContext context) => FilledButton(
    onPressed: onPressed,
    style: ButtonStyle(
      minimumSize: const WidgetStatePropertyAll(Size.fromHeight(56)),
      padding: const WidgetStatePropertyAll(
        EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
      backgroundColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.disabled)
            ? const Color(0xFFE5E5E5)
            : states.contains(WidgetState.pressed)
            ? const Color(0xFF506477)
            : const Color(0xFF243B53),
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
}
