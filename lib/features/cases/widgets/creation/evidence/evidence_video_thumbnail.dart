import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../models/evidence_model.dart';
import '../../../services/evidence_video_thumbnail.dart';

class EvidenceVideoThumbnail extends ConsumerStatefulWidget {
  const EvidenceVideoThumbnail({super.key, required this.evidence});
  final EvidenceModel evidence;
  @override
  ConsumerState<EvidenceVideoThumbnail> createState() =>
      _EvidenceVideoThumbnailState();
}

class _EvidenceVideoThumbnailState
    extends ConsumerState<EvidenceVideoThumbnail> {
  late Future<Uint8List?> _frame;
  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    _frame = evidenceVideoThumbnail(
      widget.evidence,
      ref.read(evidenceThumbnailExtractorProvider),
      clearNativeCache: ref.read(evidenceThumbnailCacheClearerProvider),
    );
  }

  @override
  void didUpdateWidget(covariant EvidenceVideoThumbnail oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.evidence != widget.evidence) _load();
  }

  @override
  void dispose() {
    final evidence = widget.evidence;
    unawaited(
      _frame.then((bytes) async {
        // Evict after Image has unmounted as well, so decoding cannot repopulate
        // the image cache after the model's earlier eviction during deletion.
        if (evidence.isDisposed && bytes != null) {
          await MemoryImage(bytes).evict();
        }
      }),
    );
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<Uint8List?>(
    future: _frame,
    builder: (context, snapshot) => Stack(
      fit: StackFit.expand,
      children: [
        const ColoredBox(color: Color(0xFF243B53)),
        if (snapshot.data case final bytes?)
          Image.memory(
            bytes,
            fit: BoxFit.cover,
            excludeFromSemantics: true,
            errorBuilder: (_, _, _) =>
                const ColoredBox(color: Color(0xFF243B53)),
          ),
        const Center(
          child: Icon(
            Icons.play_circle_outline,
            size: 24,
            color: Colors.white,
            semanticLabel: 'Video',
          ),
        ),
      ],
    ),
  );
}
