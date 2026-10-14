import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import 'logout_confirmation_dialog.dart';
import 'profile_avatar.dart';

class ProfileMenu extends StatefulWidget {
  const ProfileMenu({
    super.key,
    required this.nickname,
    this.size = 42,
    this.onLogout,
  });
  final String nickname;
  final double size;

  /// Supply the real session logout and auth-route handling when available.
  final Future<void> Function()? onLogout;

  @override
  State<ProfileMenu> createState() => _ProfileMenuState();
}

class _ProfileMenuState extends State<ProfileMenu> {
  final MenuController _menu = MenuController();
  final FocusNode _avatarFocus = FocusNode(debugLabel: 'Profile menu');
  GoRouter? _router;
  String? _openedPath;
  bool _open = false;
  bool _dialogOpen = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final router = GoRouter.maybeOf(context);
    if (_router != router) {
      _router?.routerDelegate.removeListener(_routeChanged);
      _router = router;
      _router?.routerDelegate.addListener(_routeChanged);
    }
  }

  void _routeChanged() {
    if (_menu.isOpen &&
        _router?.routeInformationProvider.value.uri.path != _openedPath) {
      _menu.close();
    }
  }

  void _toggle() {
    if (_dialogOpen) return;
    _menu.isOpen ? _menu.close() : _menu.open();
  }

  Future<void> _logout() async {
    if (_dialogOpen) return;
    _dialogOpen = true;
    _menu.close();
    try {
      await showDialog<void>(
        context: context,
        useRootNavigator: true,
        barrierDismissible: false,
        barrierColor: const Color(0x33000000),
        builder: (_) => LogoutConfirmationDialog(onLogout: widget.onLogout),
      );
    } finally {
      _dialogOpen = false;
      if (mounted &&
          (_router == null ||
              _router?.routeInformationProvider.value.uri.path ==
                  _openedPath)) {
        _avatarFocus.requestFocus();
      }
    }
  }

  @override
  void dispose() {
    _router?.routerDelegate.removeListener(_routeChanged);
    _avatarFocus.dispose();
    super.dispose();
  }

  Widget _item(String label, Color color, VoidCallback action) =>
      MenuItemButton(
        onPressed: action,
        style: ButtonStyle(
          minimumSize: const WidgetStatePropertyAll(Size(112, 48)),
          padding: const WidgetStatePropertyAll(
            EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          ),
          foregroundColor: WidgetStatePropertyAll(color),
          textStyle: const WidgetStatePropertyAll(
            TextStyle(
              fontFamily: 'Pretendard Variable',
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          alignment: Alignment.center,
        ),
        child: Center(child: Text(label, textAlign: TextAlign.center)),
      );

  @override
  Widget build(BuildContext context) => MenuAnchor(
    controller: _menu,
    childFocusNode: _avatarFocus,
    useRootOverlay: true,
    consumeOutsideTap: true,
    crossAxisUnconstrained: false,
    alignmentOffset: Offset(widget.size - 112, 4),
    onOpen: () {
      _openedPath = _router?.routeInformationProvider.value.uri.path;
      if (mounted) setState(() => _open = true);
    },
    onClose: () {
      if (mounted) setState(() => _open = false);
    },
    style: MenuStyle(
      alignment: Alignment.bottomLeft,
      fixedSize: const WidgetStatePropertyAll(Size.fromWidth(112)),
      padding: const WidgetStatePropertyAll(EdgeInsets.zero),
      backgroundColor: const WidgetStatePropertyAll(Colors.white),
      surfaceTintColor: const WidgetStatePropertyAll(Colors.transparent),
      side: const WidgetStatePropertyAll(BorderSide(color: Color(0xFFE5E5E5))),
      shape: WidgetStatePropertyAll(
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
      ),
      elevation: const WidgetStatePropertyAll(4),
      shadowColor: const WidgetStatePropertyAll(Color(0x33000000)),
    ),
    menuChildren: [
      _item('My Page', const Color(0xFF243B53), () {
        _menu.close();
        context.go('/my-page');
      }),
      const Divider(height: 1, thickness: 1, color: Color(0xFFE5E5E5)),
      _item('Log out', const Color(0xFFEF0000), _logout),
    ],
    builder: (_, _, _) => Semantics(
      label: 'Profile menu',
      button: true,
      expanded: _open,
      onTap: _toggle,
      excludeSemantics: true,
      child: ProfileAvatar(
        nickname: widget.nickname,
        size: widget.size,
        focusNode: _avatarFocus,
        onTap: _toggle,
      ),
    ),
  );
}
