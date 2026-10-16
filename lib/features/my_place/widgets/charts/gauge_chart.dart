import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

import '../../../../core/app_colors.dart';
import '../../../../core/theme.dart';

/// 아크 게이지 — 값 + 시 평균 마커 + 스케일
/// 값이 null 이면 저데이터: 트랙만 그리고 중앙에 짧은 선
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
    this.height = 176,
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
          final size = Size(constraints.maxWidth, height);
          final metrics = _GaugeMetrics(size);
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
              // 중앙 값
              Positioned(
                left: 0,
                right: 0,
                top: metrics.center.dy - 34,
                child: Column(
                  spacing: Gap.xs,
                  children: [
                    if (value == null)
                      Container(
                        width: 20,
                        height: 2,
                        color: AppColors.textMuted,
                        margin: const EdgeInsets.symmetric(vertical: Gap.card),
                      )
                    else
                      Text(
                        '$value',
                        style: const TextStyle(
                          color: AppColors.textTitle,
                          fontSize: 40,
                          fontWeight: FontWeight.w700,
                          height: 1.1,
                        ),
                      ),
                    Text(
                      caption,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              // 스케일 양끝
              Positioned(
                left: metrics.startLabelLeft,
                top: metrics.labelTop,
                child: _ScaleLabel(text: startLabel),
              ),
              Positioned(
                right: metrics.startLabelLeft,
                top: metrics.labelTop,
                child: _ScaleLabel(text: endLabel),
              ),
              if (marker != null && markerLabel != null)
                Positioned(
                  left: 0,
                  right: 0,
                  top: math.max(marker.dy - 26, 0),
                  child: Align(
                    alignment: Alignment(
                      ((marker.dx / size.width) * 2 - 1).clamp(-1.0, 1.0),
                      0,
                    ),
                    child: Text(
                      markerLabel!,
                      style: const TextStyle(
                        color: AppColors.chartInk,
                        fontSize: 11,
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
        color: AppColors.textMuted,
        fontSize: 11,
        fontWeight: FontWeight.w500,
      ),
    );
  }
}

/// 아크 기하 — 페인터와 라벨 배치가 같은 값을 쓴다
class _GaugeMetrics {
  _GaugeMetrics(this.size)
    : radius = math.min(
        (size.width - 48) / 2,
        (size.height - _markerLabelSpace - 24) / 1.5,
      );

  static const _markerLabelSpace = 26.0;
  static const startAngle = math.pi * 5 / 6; // 7시 30분 방향
  static const sweepAngle = math.pi * 4 / 3; // 240도

  final Size size;
  final double radius;

  Offset get center => Offset(size.width / 2, _markerLabelSpace + radius);

  /// 0~1 위치의 아크 좌표
  Offset pointAt(double ratio) {
    final angle = startAngle + sweepAngle * ratio.clamp(0.0, 1.0);
    return center + Offset(math.cos(angle) * radius, math.sin(angle) * radius);
  }

  /// 아크 끝 아래 스케일 라벨 위치
  double get labelTop => center.dy + radius * 0.5 + Gap.sm;
  double get startLabelLeft => size.width / 2 - radius * 0.92;
}

class _GaugePainter extends CustomPainter {
  const _GaugePainter({
    required this.ratio,
    required this.markerRatio,
    required this.fillColor,
  });

  static const _stroke = 14.0;

  /// null 이면 채우지 않는다
  final double? ratio;
  final double? markerRatio;
  final Color fillColor;

  @override
  void paint(Canvas canvas, Size size) {
    final metrics = _GaugeMetrics(size);
    final rect = Rect.fromCircle(
      center: metrics.center,
      radius: metrics.radius,
    );

    final track = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = _stroke
      ..strokeCap = StrokeCap.round
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
        ..strokeWidth = _stroke
        ..strokeCap = StrokeCap.round
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

    // 시 평균 — 흰 테두리를 둘러 아크 위에서 떨어져 보이게
    final point = metrics.pointAt(marker);
    canvas.drawCircle(point, 6, Paint()..color = AppColors.surface);
    canvas.drawCircle(point, 4, Paint()..color = AppColors.chartInk);
  }

  @override
  bool shouldRepaint(_GaugePainter old) =>
      old.ratio != ratio ||
      old.markerRatio != markerRatio ||
      old.fillColor != fillColor;
}
