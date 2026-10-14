import 'package:material_ui/material_ui.dart';

import '../../../../core/app_colors.dart';
import '../../../../core/theme.dart';

/// Deaver 응답 대기 — 점 3개 순차 깜빡임
class TypingIndicator extends StatefulWidget {
  const TypingIndicator({super.key});

  @override
  State<TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<TypingIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: Gap.screenH + 56 + Gap.card),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: Gap.md,
            vertical: Gap.card,
          ),
          decoration: BoxDecoration(
            color: AppColors.bubbleAi,
            borderRadius: BorderRadius.circular(Gap.card),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            spacing: Gap.xs,
            children: [
              for (var i = 0; i < 3; i++)
                _Dot(controller: _controller, index: i),
            ],
          ),
        ),
      ),
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot({required this.controller, required this.index});

  final AnimationController controller;
  final int index;

  @override
  Widget build(BuildContext context) {
    // 점마다 1/3 주기 지연 — 순차 깜빡임
    final begin = index / 3;

    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        final t = (controller.value - begin) % 1.0;
        final opacity = t < 0.5 ? 0.3 + t : 0.3 + (1.0 - t);

        return Opacity(opacity: opacity.clamp(0.3, 1.0), child: child);
      },
      child: const SizedBox(
        width: 8,
        height: 8,
        child: DecoratedBox(
          decoration: ShapeDecoration(
            color: AppColors.textMuted,
            shape: CircleBorder(),
          ),
        ),
      ),
    );
  }
}
