import 'package:material_ui/material_ui.dart';

class LogoutConfirmationDialog extends StatefulWidget {
  const LogoutConfirmationDialog({super.key, this.onLogout});
  final Future<void> Function()? onLogout;

  @override
  State<LogoutConfirmationDialog> createState() =>
      _LogoutConfirmationDialogState();
}

class _LogoutConfirmationDialogState extends State<LogoutConfirmationDialog> {
  bool _busy = false;
  String? _message;

  Future<void> _confirm() async {
    if (_busy) return;
    final logout = widget.onLogout;
    if (logout == null) {
      setState(() => _message = 'Logout is not connected yet.');
      return;
    }
    setState(() {
      _busy = true;
      _message = null;
    });
    try {
      await logout();
      if (mounted) Navigator.of(context).pop();
    } catch (_) {
      if (mounted) {
        setState(() {
          _busy = false;
          _message = 'Unable to log out. Please try again.';
        });
      }
    }
  }

  Widget _action(String label, Color color, VoidCallback? onPressed) =>
      TextButton(
        onPressed: onPressed,
        style: TextButton.styleFrom(
          foregroundColor: color,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
          minimumSize: const Size(0, 48),
          shape: const RoundedRectangleBorder(),
          splashFactory: NoSplash.splashFactory,
          overlayColor: Colors.transparent,
          textStyle: const TextStyle(
            fontFamily: 'Pretendard Variable',
            fontSize: 12,
            fontWeight: FontWeight.w500,
            height: 1.25,
          ),
        ),
        child: Text(label, textAlign: TextAlign.center),
      );

  @override
  Widget build(BuildContext context) => PopScope<Object?>(
    canPop: !_busy,
    child: Dialog(
      key: const ValueKey('logout-confirmation-dialog'),
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(24),
      constraints: const BoxConstraints(maxWidth: 254),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Semantics(
                    namesRoute: true,
                    child: const Text(
                      'Are you logging out?',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        height: 1.25,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Your can always log back',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Color(0xFF606060),
                      fontSize: 14,
                      height: 1.25,
                    ),
                  ),
                  if (_message case final message?) ...[
                    const SizedBox(height: 8),
                    Semantics(
                      liveRegion: true,
                      child: Text(
                        message,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Color(0xFF606060),
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const Divider(height: 1, thickness: 1, color: Color(0xFFE5E5E5)),
          IntrinsicHeight(
            child: Row(
              children: [
                Expanded(
                  child: _action(
                    'Cancel',
                    const Color(0xFF606060),
                    _busy ? null : () => Navigator.of(context).pop(),
                  ),
                ),
                const VerticalDivider(
                  width: 1,
                  thickness: 1,
                  color: Color(0xFFE5E5E5),
                ),
                Expanded(
                  child: _action(
                    _busy ? 'Logging out...' : 'Log out',
                    const Color(0xFF0065F3),
                    _busy ? null : _confirm,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}
