import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

import '../../../../core/app_colors.dart';

/// 라벨 없는 작은 반원 — 배지 설명처럼 모양만 보여줄 때
class GaugeMark extends StatelessWidget {
  const GaugeMark({
    super.key,
    required this.ratio,
    required this.color,
    this.width = 81,
    this.thickness = 8,
  });

  /// 0~1
  final double ratio;
  final Color color;
  final double width;
  final double thickness;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: width * 0.62,
      child: CustomPaint(
        painter: _GaugeMarkPainter(
          ratio: ratio.clamp(0.0, 1.0),
          color: color,
          thickness: thickness,
        ),
      ),
    );
  }
}

class _GaugeMarkPainter extends CustomPainter {
  const _GaugeMarkPainter({
    required this.ratio,
    required this.color,
    required this.thickness,
  });

  final double ratio;
  final Color color;
  final double thickness;

  @override
  void paint(Canvas canvas, Size size) {
    final radius = math.min(size.width / 2, size.height) - thickness / 2;
    final rect = Rect.fromCircle(
      center: Offset(size.width / 2, size.height),
      radius: radius,
    );

    final track = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = thickness
      ..color = AppColors.chartTrack;

    canvas.drawArc(rect, math.pi, math.pi, false, track);

    if (ratio <= 0) return;

    final fill = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = thickness
      ..color = color;

    canvas.drawArc(rect, math.pi, math.pi * ratio, false, fill);
  }

  @override
  bool shouldRepaint(_GaugeMarkPainter old) =>
      old.ratio != ratio || old.color != color || old.thickness != thickness;
}
