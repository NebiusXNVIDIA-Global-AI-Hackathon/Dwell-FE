import 'package:material_ui/material_ui.dart';

class CaseCreationBottom extends StatelessWidget {
  const CaseCreationBottom({
    super.key,
    required this.enabled,
    required this.onNext,
    this.label = 'Next',
    this.height = 56,
  });

  final bool enabled;
  final VoidCallback? onNext;
  final String label;
  final double height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: height,
      child: FilledButton(
        onPressed: enabled ? onNext : null,
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.resolveWith<Color>((states) {
            if (states.contains(WidgetState.disabled)) {
              return const Color(0xFFE3E3E3);
            }

            if (states.contains(WidgetState.pressed)) {
              return const Color(0xFF506275);
            }

            return const Color(0xFF243B53);
          }),
          foregroundColor: WidgetStateProperty.resolveWith<Color>((states) {
            return states.contains(WidgetState.disabled)
                ? const Color(0xFFA6A6A6)
                : Colors.white;
          }),
          overlayColor: const WidgetStatePropertyAll(Colors.transparent),
          padding: const WidgetStatePropertyAll(
            EdgeInsets.symmetric(horizontal: 16),
          ),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          textStyle: const WidgetStatePropertyAll(
            TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
        ),
        child: SizedBox(
          width: double.infinity,
          child: Text(label, textAlign: TextAlign.center),
        ),
      ),
    );
  }
}
