import 'package:material_ui/material_ui.dart';

import '../../../../core/theme.dart';
import '../../models/evidence_group.dart';
import '../case_detail_format.dart';
import '../case_detail_tokens.dart';

class EvidenceFolderCard extends StatelessWidget {
  const EvidenceFolderCard({super.key, required this.group});

  final EvidenceGroup group;

  @override
  Widget build(BuildContext context) {
    const size = CaseDetailSizes.folderSize;
    const glassRadius = BorderRadius.vertical(
      top: Radius.circular(CaseDetailSizes.folderRadius),
      bottom: Radius.circular(CaseDetailSizes.folderBottomRadius),
    );

    return SizedBox.square(
      dimension: size,
      child: Stack(
        children: [
          const Positioned.fill(
            child: CustomPaint(painter: _FolderBackPainter()),
          ),
          // Thumbnail slot stays empty until the asset is added
          Positioned(
            left: Gap.card,
            right: Gap.card,
            top: CaseDetailSizes.folderThumbTop,
            height: CaseDetailSizes.folderThumbHeight,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(CaseDetailSizes.folderRadius),
              child: group.thumbnailPath == null
                  ? const SizedBox.expand()
                  : Image.asset(group.thumbnailPath!, fit: BoxFit.cover),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            top: CaseDetailSizes.folderGlassTop,
            bottom: 0,
            child: Container(
              decoration: const BoxDecoration(
                color: CaseDetailColors.folderGlass,
                borderRadius: glassRadius,
                border: Border(
                  top: BorderSide(color: CaseDetailColors.folderEdge),
                ),
              ),
              padding: const EdgeInsets.fromLTRB(
                Gap.card,
                Gap.card,
                Gap.card,
                Gap.card,
              ),
              child: Column(
                children: [
                  Container(
                    width: CaseDetailSizes.pillWidth,
                    height: CaseDetailSizes.badgeHeight,
                    alignment: Alignment.center,
                    decoration: const ShapeDecoration(
                      color: CaseDetailColors.glassPill,
                      shape: StadiumBorder(
                        side: BorderSide(color: CaseDetailColors.surface),
                      ),
                    ),
                    child: Text(
                      CaseDetailFormat.itemCount(group.itemCount),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: CaseDetailText.folderLabel,
                    ),
                  ),
                  const Spacer(),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      CaseDetailFormat.folderDate(group.capturedAt),
                      maxLines: 1,
                      style: CaseDetailText.folderLabel,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FolderBackPainter extends CustomPainter {
  const _FolderBackPainter();

  @override
  void paint(Canvas canvas, Size size) {
    const r = CaseDetailSizes.folderRadius;
    const tabW = CaseDetailSizes.folderTabWidth;
    const tabH = CaseDetailSizes.folderTabHeight;
    final path = Path()
      ..moveTo(0, r)
      ..quadraticBezierTo(0, 0, r, 0)
      ..lineTo(tabW - r, 0)
      ..cubicTo(tabW, 0, tabW + r, tabH, tabW + r * 2, tabH)
      ..lineTo(size.width - r, tabH)
      ..quadraticBezierTo(size.width, tabH, size.width, tabH + r)
      ..lineTo(size.width, size.height - r)
      ..quadraticBezierTo(size.width, size.height, size.width - r, size.height)
      ..lineTo(r, size.height)
      ..quadraticBezierTo(0, size.height, 0, size.height - r)
      ..close();
    canvas.drawPath(path, Paint()..color = CaseDetailColors.folder);
  }

  @override
  bool shouldRepaint(covariant _FolderBackPainter oldDelegate) => false;
}
