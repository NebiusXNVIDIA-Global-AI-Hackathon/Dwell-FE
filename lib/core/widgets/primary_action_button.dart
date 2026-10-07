import 'package:material_ui/material_ui.dart';

/// 활성 여부는 부모가 결정하고, 눌림 색상은 버튼이 처리한다.
class PrimaryActionButton extends StatelessWidget {
  final String label;
  final bool enabled;
  final VoidCallback? onPressed;

  const PrimaryActionButton({
    super.key,
    required this.label,
    required this.enabled,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      onPressed: enabled ? onPressed : null,
      style: ButtonStyle(
        minimumSize: const WidgetStatePropertyAll(Size.fromHeight(48)),
        padding: const WidgetStatePropertyAll(
          EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
        backgroundColor: WidgetStateProperty.resolveWith<Color>((states) {
          if (states.contains(WidgetState.disabled)) {
            return const Color(0xFFE3E3E3);
          }

          if (states.contains(WidgetState.pressed)) {
            return const Color(0xFF1E4344);
          }

          return const Color(0xFF2B575F);
        }),
        foregroundColor: WidgetStateProperty.resolveWith<Color>((states) {
          return states.contains(WidgetState.disabled)
              ? const Color(0xFF929292)
              : Colors.white;
        }),
        overlayColor: const WidgetStatePropertyAll(Colors.transparent),
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        textStyle: const WidgetStatePropertyAll(
          TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),
      child: Text(label),
    );
  }
}
