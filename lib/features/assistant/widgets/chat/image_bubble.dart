import 'package:material_ui/material_ui.dart';

import '../../../../core/app_colors.dart';
import '../../../../core/theme.dart';

/// 문자 스크린샷 등 — 우측 정렬
class ImageBubble extends StatelessWidget {
  const ImageBubble({super.key, required this.path});

  final String path;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Gap.screenH),
      child: Align(
        alignment: Alignment.centerRight,
        child: Container(
          width: 276,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(Gap.card),
            border: Border.all(color: AppColors.divider),
          ),
          clipBehavior: Clip.antiAlias,
          child: Image.asset(
            path,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) =>
                const _ImageFallback(),
          ),
        ),
      ),
    );
  }
}

/// 이미지 로드 실패 대비
class _ImageFallback extends StatelessWidget {
  const _ImageFallback();

  @override
  Widget build(BuildContext context) {
    return const ColoredBox(
      color: AppColors.infoCard,
      child: SizedBox(
        height: 200,
        child: Center(
          child: Icon(
            Icons.image_outlined,
            size: 28,
            color: AppColors.textMuted,
          ),
        ),
      ),
    );
  }
}
