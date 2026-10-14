import 'package:material_ui/material_ui.dart';

class ProfileAvatar extends StatelessWidget {
  final String nickname;
  final double size;
  final VoidCallback? onTap;
  final FocusNode? focusNode;

  const ProfileAvatar({
    super.key,
    required this.nickname,
    this.size = 40,
    this.onTap,
    this.focusNode,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final isLight = colors.brightness == Brightness.light;

    return Material(
      color: isLight ? const Color(0xFFA6A6A6) : colors.surfaceContainerHighest,
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        focusNode: focusNode,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: size,
          height: size,
          child: Center(
            child: Text(
              nickname.characters.take(2).toString(),
              style: TextStyle(
                color: isLight ? const Color(0xFF243B53) : colors.onSurface,
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
