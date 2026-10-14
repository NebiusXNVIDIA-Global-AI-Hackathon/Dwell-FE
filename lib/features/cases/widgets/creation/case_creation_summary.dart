import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';

import '../../models/case_creation_result.dart';
import '../../models/case_model.dart';
import '../../models/evidence_model.dart';
import 'evidence/evidence_audio_preview.dart';
import 'evidence/evidence_document_preview.dart';
import 'evidence/evidence_video_thumbnail.dart';

/// Follows the Reports card's typography and badge treatment without inventing
/// a domain CaseModel (which requires an actual severity and persisted ID).
class CaseCreationSummary extends StatelessWidget {
  const CaseCreationSummary({super.key, required this.result});
  final CaseCreationResult result;

  String get _createdAtLabel {
    final date = result.createdAt;
    final day = date.day;
    final suffix = day >= 11 && day <= 13
        ? 'th'
        : switch (day % 10) {
            1 => 'st',
            2 => 'nd',
            3 => 'rd',
            _ => 'th',
          };
    return '${DateFormat('MMM').format(date)} $day$suffix, ${DateFormat('yyyy · h:mm a').format(date)}';
  }

  Widget _card(BuildContext context) => Container(
    key: const ValueKey('created-case-card'),
    width: 114,
    clipBehavior: Clip.antiAlias,
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: const Color(0xFFE5E5E5)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: 96,
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (result.input.evidence.firstOrNull case final item?)
                switch (item.type) {
                  EvidenceType.photo => Image(
                    image: item.photoPreview(
                      114,
                      96,
                      MediaQuery.devicePixelRatioOf(context),
                    ),
                    fit: BoxFit.cover,
                    semanticLabel: 'Representative evidence',
                    errorBuilder: (_, _, _) =>
                        const Icon(Icons.broken_image_outlined),
                  ),
                  EvidenceType.video => EvidenceVideoThumbnail(evidence: item),
                  EvidenceType.audio => const ColoredBox(
                    color: Color(0xFFE3E3E3),
                    child: Padding(
                      padding: EdgeInsets.all(18),
                      child: EvidenceAudioWave(),
                    ),
                  ),
                  EvidenceType.document => EvidenceDocumentThumbnail(
                    evidence: item,
                  ),
                },
              Positioned(
                right: 6,
                bottom: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: ShapeDecoration(
                    color: Colors.black26,
                    shape: const StadiumBorder(
                      side: BorderSide(color: Colors.white),
                    ),
                  ),
                  child: Text(
                    result.severityLabel,
                    style: const TextStyle(color: Colors.white, fontSize: 10),
                  ),
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                result.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Color(0xFF243B53),
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  height: 1.15,
                ),
              ),
              Text(
                result.location,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Color(0xFF243B53),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  height: 1.2,
                ),
              ),
              Text(
                DateFormat('M/d/yyyy').format(result.createdAt),
                style: const TextStyle(
                  color: Color(0xFF667685),
                  fontSize: 10,
                  height: 1.2,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );

  Widget _details() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        result.id,
        key: const ValueKey('created-case-id'),
        style: const TextStyle(
          color: Color(0xFF243B53),
          fontSize: 20,
          fontWeight: FontWeight.w700,
          height: 1.2,
        ),
      ),
      Text(
        result.title,
        style: const TextStyle(
          color: Color(0xFF243B53),
          fontSize: 20,
          fontWeight: FontWeight.w700,
          height: 1.2,
        ),
      ),
      const SizedBox(height: 5),
      Text(
        result.locationSummary,
        style: const TextStyle(
          color: Color(0xFF858E96),
          fontSize: 16,
          fontWeight: FontWeight.w500,
          height: 1.3,
        ),
      ),
      const SizedBox(height: 7),
      FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.centerLeft,
        child: Text(
          _createdAtLabel,
          style: const TextStyle(
            color: Color(0xFF858E96),
            fontSize: 16,
            fontWeight: FontWeight.w500,
            height: 1.3,
          ),
        ),
      ),
      const SizedBox(height: 8),
      Wrap(
        spacing: 10,
        runSpacing: 6,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          const Text(
            'Severity',
            style: TextStyle(
              color: Color(0xFF243B53),
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
            decoration: ShapeDecoration(
              color: result.severity == CaseSeverity.high
                  ? const Color(0xFFEDABA8)
                  : const Color(0xFFE5E5E5),
              shape: const StadiumBorder(),
            ),
            child: Text(
              result.severityLabel,
              style: TextStyle(
                fontSize: 12,
                color: result.severity == CaseSeverity.high
                    ? const Color(0xFFBD0000)
                    : const Color(0xFF667685),
              ),
            ),
          ),
        ],
      ),
    ],
  );

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final compact =
          constraints.maxWidth < 340 ||
          MediaQuery.textScalerOf(context).scale(16) > 20;
      return Padding(
        padding: EdgeInsets.only(left: compact ? 0 : 22),
        child: compact
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _card(context),
                  const SizedBox(height: 20),
                  _details(),
                ],
              )
            : Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  _card(context),
                  const SizedBox(width: 34),
                  Expanded(child: _details()),
                ],
              ),
      );
    },
  );
}
