import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:material_ui/material_ui.dart';

class EvidenceStep extends StatelessWidget {
  const EvidenceStep({
    super.key,
    required this.onAdd,
    this.isSheetOpen = false,
  });
  final VoidCallback onAdd;
  final bool isSheetOpen;

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Add evidence that clearly shows the issue and affected area.',
          style: TextStyle(
            fontSize: 16,
            height: 1.2,
            fontWeight: FontWeight.w600,
            color: Color(0xFF243B53),
          ),
        ),
        const SizedBox(height: 20),
        Semantics(
          label: 'Add evidence',
          button: true,
          onTap: onAdd,
          excludeSemantics: true,
          child: SizedBox(
            key: const ValueKey('evidence-add'),
            width: 96,
            height: 96,
            child: Material(
              color: isSheetOpen
                  ? const Color(0xFFA6A6A6)
                  : const Color(0xFFE3E3E3),
              borderRadius: BorderRadius.circular(8),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: onAdd,
                excludeFromSemantics: true,
                overlayColor: WidgetStateProperty.resolveWith(
                  (states) => states.contains(WidgetState.pressed)
                      ? const Color(0xFFA6A6A6)
                      : Colors.transparent,
                ),
                child: const Center(
                  child: Icon(
                    LucideIcons.plus,
                    size: 64,
                    color: Color(0xFFF7F7F7),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    ),
  );
}
