import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:material_ui/material_ui.dart';

import '../../../controllers/evidence_controller.dart';
import '../../../models/evidence_model.dart';
import '../evidence/evidence_video_preview.dart';
import '../evidence/evidence_audio_preview.dart';
import '../evidence/evidence_video_thumbnail.dart';

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

  void _remove(EvidenceModel item) {
    if (item.type == EvidenceType.photo) MemoryImage(item.bytes).evict();
    evidence!.remove(item.id);
  }

  Widget _delete(EvidenceModel item, int index, {bool main = false}) =>
      SizedBox(
        width: main ? 44 : 28,
        height: main ? 44 : 28,
        child: IconButton(
          tooltip: main
              ? 'Delete selected evidence'
              : 'Delete ${item.type.name} ${index + 1}',
          onPressed: () => _remove(item),
          padding: EdgeInsets.zero,
          icon: Container(
            width: main ? 28 : 18,
            height: main ? 28 : 18,
            decoration: const BoxDecoration(
              color: Colors.black38,
              shape: BoxShape.circle,
            ),
            child: Icon(
              LucideIcons.x,
              size: main ? 20 : 14,
              color: Colors.white,
            ),
          ),
        ),
      );

  Widget _add({double size = 72}) => Semantics(
    label: 'Add evidence',
    button: true,
    onTap: onAdd,
    excludeSemantics: true,
    child: SizedBox(
      key: const ValueKey('evidence-add'),
      width: size,
      height: size,
      child: Material(
        color: isSheetOpen ? const Color(0xFFA6A6A6) : const Color(0xFFE3E3E3),
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
          child: Center(
            child: Icon(
              LucideIcons.plus,
              size: size * 2 / 3,
              color: const Color(0xFFF7F7F7),
            ),
          ),
        ),
      ),
    ),
  );

  Widget _thumbnail(
    EvidenceModel item,
    EvidenceModel selected,
    int index,
  ) => SizedBox(
    width: 72,
    height: 72,
    child: Stack(
      fit: StackFit.expand,
      children: [
        Semantics(
          button: true,
          selected: item.id == selected.id,
          label:
              '${item.type.name[0].toUpperCase()}${item.type.name.substring(1)} ${index + 1}',
          child: Material(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
              side: BorderSide(
                color: item.id == selected.id
                    ? const Color(0xFF007AFF)
                    : const Color(0xFFE3E3E3),
                width: 2,
              ),
            ),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              key: ValueKey(item.id),
              onTap: () => evidence!.select(item.id),
              child: item.type == EvidenceType.video
                  ? EvidenceVideoThumbnail(
                      key: ValueKey('thumbnail-${item.id}'),
                      evidence: item,
                    )
                  : item.type == EvidenceType.audio
                  ? const ColoredBox(
                      color: Color(0xFFE3E3E3),
                      child: Padding(
                        padding: EdgeInsets.all(8),
                        child: EvidenceAudioWave(),
                      ),
                    )
                  : Image.memory(
                      item.bytes,
                      fit: BoxFit.cover,
                      excludeFromSemantics: true,
                      errorBuilder: (_, _, _) =>
                          const Icon(LucideIcons.imageOff),
                    ),
            ),
          ),
        ),
        Positioned(top: 0, right: 0, child: _delete(item, index)),
      ],
    ),
  );

  Widget _content(BuildContext context) => SingleChildScrollView(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        const Text(
          'Add evidence that clearly shows the issue and affected area.',
          style: TextStyle(
            fontSize: 16,
            height: 1.2,
            fontWeight: FontWeight.w600,
            color: Color(0xFF243B53),
          ),
        ),
        const SizedBox(height: 24),
        if (evidence?.selected case final selected?) ...[
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Stack(
              children: [
                selected.type == EvidenceType.video
                    ? EvidenceVideoPreview(
                        key: ValueKey(selected.id),
                        evidence: selected,
                        active: !isSheetOpen,
                      )
                    : selected.type == EvidenceType.audio
                    ? EvidenceAudioPreview(
                        key: ValueKey(selected.id),
                        evidence: selected,
                        active: !isSheetOpen,
                      )
                    : AspectRatio(
                        aspectRatio: 2.06,
                        child: Image.memory(
                          selected.bytes,
                          fit: BoxFit.cover,
                          semanticLabel: 'Selected photo',
                          errorBuilder: (_, _, _) => const Center(
                            child: Text('Unable to preview this photo'),
                          ),
                        ),
                      ),
                Positioned(
                  top: 4,
                  right: 4,
                  child: _delete(
                    selected,
                    evidence!.items.indexOf(selected),
                    main: true,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 72,
            child: ListView.separated(
              key: const ValueKey('evidence-thumbnails'),
              scrollDirection: Axis.horizontal,
              itemCount: evidence!.items.length + 1,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (context, index) => index == evidence!.items.length
                  ? _add()
                  : _thumbnail(evidence!.items[index], selected, index),
            ),
          ),
        ] else
          _add(size: 96),
      ],
    ),
  );
}
