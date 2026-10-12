import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:material_ui/material_ui.dart';

import '../../../models/evidence_model.dart';

String evidenceDocumentLabel(EvidenceModel item) =>
    item.fileName.split('.').last.toUpperCase();
String evidenceDocumentSize(EvidenceModel item) {
  final size = item.documentSize ?? 0;
  if (size < 1024) return '${size}B';
  if (size < 1024 * 1024) return '${(size / 1024).ceil()}KB';
  final mb = size / (1024 * 1024);
  return '${mb.toStringAsFixed(mb == mb.roundToDouble() ? 0 : 1)}MB';
}

class EvidenceDocumentIcon extends StatelessWidget {
  const EvidenceDocumentIcon({
    super.key,
    required this.evidence,
    this.size = 32,
    this.showLabel = true,
  });
  final EvidenceModel evidence;
  final double size;
  final bool showLabel;
  @override
  Widget build(BuildContext context) {
    final preview = evidence.documentPreviewBytes;
    if (preview != null) {
      return Image.memory(
        preview,
        fit: BoxFit.cover,
        excludeFromSemantics: true,
      );
    }
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            evidence.mimeType == 'application/pdf'
                ? Icons.picture_as_pdf_outlined
                : LucideIcons.fileText,
            size: size,
            color: const Color(0xFF243B53),
          ),
          if (showLabel) const SizedBox(height: 2),
          if (showLabel)
            Text(
              evidenceDocumentLabel(evidence),
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: Color(0xFF243B53),
              ),
            ),
        ],
      ),
    );
  }
}

class EvidenceDocumentThumbnail extends StatelessWidget {
  const EvidenceDocumentThumbnail({super.key, required this.evidence});
  final EvidenceModel evidence;
  @override
  Widget build(BuildContext context) => ColoredBox(
    color: const Color(0xFFE3E8EF),
    child: Padding(
      padding: const EdgeInsets.fromLTRB(4, 6, 4, 4),
      child: Column(
        children: [
          Expanded(
            child: EvidenceDocumentIcon(
              evidence: evidence,
              size: 24,
              showLabel: false,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            evidence.fileName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 10, color: Color(0xFF243B53)),
          ),
        ],
      ),
    ),
  );
}

class EvidenceDocumentPreview extends StatelessWidget {
  const EvidenceDocumentPreview({super.key, required this.evidence});
  final EvidenceModel evidence;
  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    color: const Color(0xFFE3E8EF),
    padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 64,
          height: 64,
          child: EvidenceDocumentIcon(
            evidence: evidence,
            size: 42,
            showLabel: false,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          evidence.fileName,
          key: const ValueKey('evidence-document-name'),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Color(0xFF243B53),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          '${evidenceDocumentLabel(evidence)} · ${evidenceDocumentSize(evidence)}',
          style: const TextStyle(color: Color(0xFF627381)),
        ),
      ],
    ),
  );
}
