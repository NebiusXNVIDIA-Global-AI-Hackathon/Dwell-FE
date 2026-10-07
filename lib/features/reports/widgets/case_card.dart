import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';

import '../models/case_model.dart';

class CaseCard extends StatelessWidget {
  final CaseModel caseItem;
  final VoidCallback? onTap;

  const CaseCard({super.key, required this.caseItem, this.onTap});

  String get _badgeLabel {
    if (caseItem.status == CaseStatus.resolved) {
      return 'Resolved';
    }

    return switch (caseItem.severity) {
      CaseSeverity.low => 'Low',
      CaseSeverity.medium => 'Medium',
      CaseSeverity.high => 'High',
    };
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textColor = colors.brightness == Brightness.light
        ? const Color(0xFF243B53)
        : colors.onSurface;

    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      color: colors.surface,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              height: 97,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  _buildThumbnail(colors),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: SvgPicture.asset(
                      caseItem.isPublic
                          ? 'assets/icons/case/eye.svg'
                          : 'assets/icons/case/eye_off.svg',
                      width: 16,
                      height: 13,
                      colorFilter: const ColorFilter.mode(
                        Colors.white,
                        BlendMode.srcIn,
                      ),
                      semanticsLabel: caseItem.isPublic ? 'Public' : 'Private',
                    ),
                  ),
                  //영상 조건문
                  if (caseItem.representativeEvidence?.mediaType ==
                      CaseMediaType.video)
                    Center(
                      child: SvgPicture.asset(
                        'assets/icons/case/play.svg',
                        width: 32,
                        height: 32,
                        semanticsLabel: 'Video evidence',
                      ),
                    ),
                  Positioned(
                    right: 8,
                    bottom: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: ShapeDecoration(
                        shape: const StadiumBorder(
                          side: BorderSide(color: Colors.white),
                        ),
                      ),
                      child: Text(
                        _badgeLabel,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
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
                    caseItem.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: textColor,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    caseItem.location,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: textColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    DateFormat('M/d/yyyy').format(caseItem.createdAt),
                    style: TextStyle(
                      color: colors.onSurfaceVariant,
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildThumbnail(ColorScheme colors) {
    final evidence = caseItem.representativeEvidence;

    if (evidence == null) {
      return _placeholder(colors);
    }

    // 최초 업로드한 증거가 음성이면 파형 SVG 표시
    if (evidence.mediaType == CaseMediaType.audio) {
      return ColoredBox(
        color: colors.surfaceContainerHighest,
        child: Center(
          child: SvgPicture.asset(
            'assets/icons/case/audio.svg',
            width: 64,
            semanticsLabel: 'Audio evidence',
          ),
        ),
      );
    }

    // 사진 또는 영상의 미리보기 이미지
    final source = evidence.thumbnailUrl;

    if (source == null || source.trim().isEmpty) {
      return _placeholder(colors);
    }

    final uri = Uri.tryParse(source);
    final isNetworkImage = uri?.scheme == 'https' || uri?.scheme == 'http';

    if (isNetworkImage) {
      return Image.network(
        source,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return _placeholder(colors);
        },
      );
    }

    return Image.asset(
      source,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) {
        return _placeholder(colors);
      },
    );
  }

  Widget _placeholder(ColorScheme colors) {
    return ColoredBox(
      color: colors.surfaceContainerHighest,
      child: Center(
        child: Icon(
          Icons.image_outlined,
          color: colors.onSurfaceVariant,
          size: 28,
        ),
      ),
    );
  }
}
