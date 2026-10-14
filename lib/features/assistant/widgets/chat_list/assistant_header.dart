import 'package:material_ui/material_ui.dart';

import '../../../../core/app_colors.dart';
import '../../../../core/theme.dart';
import '../../data/shared_mock.dart';

/// 네이비 헤더 — 스크롤과 함께 올라감
class AssistantHeader extends StatelessWidget {
  const AssistantHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.navy,
      child: SafeArea(
        bottom: false,
        // 큰 글씨 · 좁은 폭에서 줄바꿈되면 늘어난다
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 124),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              Gap.lg,
              Gap.lg,
              Gap.screenH,
              Gap.lg,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              spacing: Gap.xs,
              children: [
                // SJ 는 타이틀과 같은 줄, 아래 맞춤
                const Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Text(
                        'Assistant',
                        style: TextStyle(
                          color: AppColors.bg,
                          fontSize: 40,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -1.2,
                        ),
                      ),
                    ),
                    _ProfileInitials(),
                  ],
                ),
                const Text(
                  'Your AI tenant advocate',
                  style: TextStyle(
                    color: AppColors.headerSubtle,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ProfileInitials extends StatelessWidget {
  const _ProfileInitials();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 42,
      height: 42,
      decoration: const ShapeDecoration(
        color: AppColors.textMuted,
        shape: CircleBorder(),
      ),
      child: const Center(
        child: Text(
          demoUserInitials,
          style: TextStyle(
            color: AppColors.textTitle,
            fontSize: 20,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.6,
          ),
        ),
      ),
    );
  }
}
