import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

import '../../../../core/app_colors.dart';

/// 스탯 타일 안 작은 링 — 숫자는 타일이 따로 보여준다
class MiniDonut extends StatelessWidget {
  const MiniDonut({
    super.key,
    required this.ratio,
    this.color = AppColors.chartWarning,
    this.size = 32,
    this.thickness = 5,
  });

  /// 0~1
  final double ratio;
  final Color color;
  final double size;
  final double thickness;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _MiniDonutPainter(
          ratio: ratio.clamp(0.0, 1.0),
          color: color,
          thickness: thickness,
        ),
      ),
    );
  }
}

class _MiniDonutPainter extends CustomPainter {
  const _MiniDonutPainter({
    required this.ratio,
    required this.color,
    required this.thickness,
  });

  final double ratio;
  final Color color;
  final double thickness;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(
      thickness / 2,
      thickness / 2,
      size.width - thickness,
      size.height - thickness,
    );

    final track = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = thickness
      ..color = AppColors.chartTrack;

    canvas.drawArc(rect, 0, math.pi * 2, false, track);

    if (ratio <= 0) return;

    final fill = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = thickness
      ..strokeCap = StrokeCap.round
      ..color = color;

    // 12시에서 시계방향
    canvas.drawArc(rect, -math.pi / 2, math.pi * 2 * ratio, false, fill);
  }

  @override
  bool shouldRepaint(_MiniDonutPainter old) =>
      old.ratio != ratio || old.color != color || old.thickness != thickness;
}
