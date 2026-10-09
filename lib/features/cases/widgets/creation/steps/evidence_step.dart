import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:material_ui/material_ui.dart';

import '../../../controllers/evidence_controller.dart';

class EvidenceStep extends StatelessWidget {
  const EvidenceStep({
    super.key,
    required this.onAdd,
    this.isSheetOpen = false,
    this.evidence,
  });
  final VoidCallback onAdd;
  final bool isSheetOpen;
  final EvidenceController? evidence;

  @override
  Widget build(BuildContext context) => evidence == null
      ? _content(context)
      : AnimatedBuilder(
          animation: evidence!,
          builder: (context, _) => _content(context),
        );

  Widget _content(BuildContext context) => SingleChildScrollView(
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
        if (evidence?.selected case final photo?) ...[
          AspectRatio(
            aspectRatio: 4 / 3,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.memory(
                photo.bytes,
                fit: BoxFit.contain,
                semanticLabel: 'Selected photo',
                errorBuilder: (_, _, _) =>
                    const Center(child: Text('Unable to preview this photo')),
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 112,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: evidence!.items.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final item = evidence!.items[index];
                return SizedBox(
                  width: 96,
                  child: Column(
                    children: [
                      Expanded(
                        child: Semantics(
                          button: true,
                          selected: item.id == photo.id,
                          label: 'Photo ${index + 1}',
                          child: Material(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                              side: BorderSide(
                                color: item.id == photo.id
                                    ? const Color(0xFF007AFF)
                                    : const Color(0xFFE3E3E3),
                                width: 2,
                              ),
                            ),
                            clipBehavior: Clip.antiAlias,
                            child: InkWell(
                              key: ValueKey(item.id),
                              onTap: () => evidence!.select(item.id),
                              child: SizedBox.expand(
                                child: Image.memory(
                                  item.bytes,
                                  fit: BoxFit.cover,
                                  excludeFromSemantics: true,
                                  errorBuilder: (_, _, _) =>
                                      const Icon(LucideIcons.imageOff),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(
                        height: 44,
                        child: IconButton(
                          tooltip: 'Delete photo ${index + 1}',
                          onPressed: () {
                            MemoryImage(item.bytes).evict();
                            evidence!.remove(item.id);
                          },
                          icon: const Icon(
                            LucideIcons.trash2,
                            size: 20,
                            color: Color(0xFF243B53),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 12),
        ],
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
