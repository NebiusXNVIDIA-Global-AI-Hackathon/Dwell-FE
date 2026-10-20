import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

import '../../../../core/app_colors.dart';
import '../../../../core/theme.dart';

/// 반원 게이지 — 값 + 시 평균 마커 + 0~상한 스케일
/// 값이 null 이면 저데이터: 트랙만 그리고 가운데에 짧은 선
class GaugeChart extends StatelessWidget {
  const GaugeChart({
    super.key,
    required this.value,
    required this.maxValue,
    required this.caption,
    required this.startLabel,
    required this.endLabel,
    this.markerValue,
    this.markerLabel,
    this.fillColor = AppColors.chartDanger,
    this.height = 156,
  });

  final int? value;
  final int maxValue;

  /// `avg. days to fix`
  final String caption;

  /// 스케일 양끝 — `0` · `90d`
  final String startLabel;
  final String endLabel;

  /// 시 평균 — 없으면 마커를 그리지 않는다
  final int? markerValue;
  final String? markerLabel;

  final Color fillColor;
  final double height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final metrics = _GaugeMetrics(Size(constraints.maxWidth, height));
          final marker = markerValue == null
              ? null
              : metrics.pointAt(markerValue! / maxValue);

          return Stack(
            children: [
              Positioned.fill(
                child: CustomPaint(
                  painter: _GaugePainter(
                    ratio: value == null ? null : value! / maxValue,
                    markerRatio: markerValue == null
                        ? null
                        : markerValue! / maxValue,
                    fillColor: fillColor,
                  ),
                ),
              ),
              // 반원 안쪽 — 값과 설명
              Positioned(
                left: 0,
                right: 0,
                top: metrics.center.dy - 54,
                child: Column(
                  children: [
                    if (value == null)
                      Container(
                        width: 20,
                        height: 2,
                        margin: const EdgeInsets.symmetric(
                          vertical: Gap.screenH,
                        ),
                        color: AppColors.textMuted,
                      )
                    else
                      Text(
                        '$value',
                        style: const TextStyle(
                          color: AppColors.chartInk,
                          fontSize: 38,
                          fontWeight: FontWeight.w700,
                          height: 1.1,
                        ),
                      ),
                    Text(
                      caption,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: AppColors.textSubtle,
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              // 스케일 양끝
              Positioned(
                left: metrics.scaleInset,
                top: metrics.center.dy + Gap.card,
                child: _ScaleLabel(text: startLabel),
              ),
              Positioned(
                right: metrics.scaleInset,
                top: metrics.center.dy + Gap.card,
                child: _ScaleLabel(text: endLabel),
              ),
              if (marker != null && markerLabel != null)
                Positioned(
                  left: 0,
                  right: 0,
                  top: math.max(marker.dy - 28, 0),
                  child: Align(
                    alignment: Alignment(
                      ((marker.dx / metrics.size.width) * 2 - 1).clamp(
                        -1.0,
                        1.0,
                      ),
                      0,
                    ),
                    child: Text(
                      markerLabel!,
                      style: const TextStyle(
                        color: AppColors.chartInk,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _ScaleLabel extends StatelessWidget {
  const _ScaleLabel({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: AppColors.chartNeutral,
        fontSize: 13,
        fontWeight: FontWeight.w500,
      ),
    );
  }
}

/// 반원 기하 — 페인터와 라벨 배치가 같은 값을 쓴다
class _GaugeMetrics {
  _GaugeMetrics(this.size)
    : radius = math.min((size.width - 28) / 2, size.height - 45);

  static const stroke = 22.0;
  static const startAngle = math.pi; // 9시 방향
  static const sweepAngle = math.pi; // 반원

  final Size size;
  final double radius;

  Offset get center => Offset(size.width / 2, 12 + radius);

  /// 0~1 위치의 호 좌표
  Offset pointAt(double ratio) {
    final angle = startAngle + sweepAngle * ratio.clamp(0.0, 1.0);
    return center + Offset(math.cos(angle) * radius, math.sin(angle) * radius);
  }

  /// 호 끝 아래 스케일 라벨 위치
  double get scaleInset => (size.width / 2 - radius) + Gap.xs;
}

class _GaugePainter extends CustomPainter {
  const _GaugePainter({
    required this.ratio,
    required this.markerRatio,
    required this.fillColor,
  });

  /// null 이면 채우지 않는다
  final double? ratio;
  final double? markerRatio;
  final Color fillColor;

  @override
  void paint(Canvas canvas, Size size) {
    final metrics = _GaugeMetrics(size);
    final rect = Rect.fromCircle(
      center: metrics.center,
      radius: metrics.radius - _GaugeMetrics.stroke / 2,
    );

    final track = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = _GaugeMetrics.stroke
      ..color = AppColors.chartTrack;

    canvas.drawArc(
      rect,
      _GaugeMetrics.startAngle,
      _GaugeMetrics.sweepAngle,
      false,
      track,
    );

    final value = ratio;
    if (value != null && value > 0) {
      final fill = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = _GaugeMetrics.stroke
        ..color = fillColor;

      canvas.drawArc(
        rect,
        _GaugeMetrics.startAngle,
        _GaugeMetrics.sweepAngle * value.clamp(0.0, 1.0),
        false,
        fill,
      );
    }

    final marker = markerRatio;
    if (marker == null) return;

    // 시 평균 — 흰 테두리를 둘러 호 위에서 떨어져 보이게
    final point = metrics.pointAt(marker);
    final inner = Offset(
      metrics.center.dx + (point.dx - metrics.center.dx) * _markerPull,
      metrics.center.dy + (point.dy - metrics.center.dy) * _markerPull,
    );
    canvas.drawCircle(inner, 7, Paint()..color = AppColors.surface);
    canvas.drawCircle(inner, 5, Paint()..color = AppColors.chartInk);
  }

  /// 마커를 호 두께 가운데로 당긴다
  static const _markerPull = 0.9;

  @override
  bool shouldRepaint(_GaugePainter old) =>
      old.ratio != ratio ||
      old.markerRatio != markerRatio ||
      old.fillColor != fillColor;
}
