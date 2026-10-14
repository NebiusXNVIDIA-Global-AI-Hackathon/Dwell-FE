import 'package:material_ui/material_ui.dart';

import '../../models/evidence_model.dart';
import 'evidence/evidence_audio_preview.dart';
import 'evidence/evidence_document_preview.dart';
import 'evidence/evidence_video_preview.dart';
import 'evidence/evidence_video_thumbnail.dart';

class EvidenceAnalysisPreview extends StatelessWidget {
  const EvidenceAnalysisPreview({super.key, required this.evidence});
  final List<EvidenceModel> evidence;

  Widget _photo(BuildContext context, EvidenceModel item) => LayoutBuilder(
    builder: (context, constraints) => Image(
      image: item.photoPreview(
        constraints.maxWidth,
        constraints.maxHeight,
        MediaQuery.devicePixelRatioOf(context),
      ),
      fit: BoxFit.cover,
      semanticLabel: 'Photo attachment',
      errorBuilder: (_, _, _) =>
          const Center(child: Icon(Icons.broken_image_outlined)),
    ),
  );

  @override
  Widget build(BuildContext context) {
    if (evidence.isEmpty) return const SizedBox.shrink();
    final first = evidence.first;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ClipRRect(
          key: ValueKey('analysis-primary-${first.id}'),
          borderRadius: BorderRadius.circular(evidence.length > 1 ? 10 : 12),
          child: switch (first.type) {
            EvidenceType.photo => AspectRatio(
              aspectRatio: evidence.length > 1 ? 2.06 : 1.9,
              child: _photo(context, first),
            ),
            EvidenceType.video => AspectRatio(
              aspectRatio: evidence.length > 1 ? 2.06 : 1.9,
              child: EvidenceVideoPreview(evidence: first),
            ),
            EvidenceType.audio => EvidenceAudioPreview(evidence: first),
            EvidenceType.document => EvidenceDocumentPreview(evidence: first),
          },
        ),
        if (evidence.length > 1) ...[
          const SizedBox(height: 12),
          SizedBox(
            key: const ValueKey('analysis-thumbnails'),
            height: 72,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: evidence.length - 1,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final item = evidence[index + 1];
                return Semantics(
                  label: 'Attachment ${index + 2}, ${item.type.name}',
                  child: SizedBox(
                    width: 72,
                    child: ClipRRect(
                      key: ValueKey('analysis-thumbnail-${item.id}'),
                      borderRadius: BorderRadius.circular(8),
                      child: switch (item.type) {
                        EvidenceType.photo => _photo(context, item),
                        EvidenceType.video => EvidenceVideoThumbnail(
                          evidence: item,
                        ),
                        EvidenceType.audio => const ColoredBox(
                          color: Color(0xFFE3E3E3),
                          child: Padding(
                            padding: EdgeInsets.all(8),
                            child: EvidenceAudioWave(),
                          ),
                        ),
                        EvidenceType.document => EvidenceDocumentThumbnail(
                          evidence: item,
                        ),
                      },
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ],
    );
  }
}
