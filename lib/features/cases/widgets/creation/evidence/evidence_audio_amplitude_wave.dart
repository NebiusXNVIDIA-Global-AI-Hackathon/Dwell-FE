import 'package:flutter/material.dart';

/// Time-ordered dBFS envelope, not decoded PCM. EMA reduces meter jitter.
class EvidenceAudioEnvelope {
  final List<double> _levels = [];
  double _smoothed = 0;
  List<double> get levels => List.unmodifiable(_levels);
  void add(double db) {
    if (!db.isFinite) db = -60;
    final normalized = ((db.clamp(-60, 0) + 60) / 60).toDouble();
    _smoothed = _levels.isEmpty
        ? normalized
        : _smoothed * 0.65 + normalized * 0.35;
    _levels.add(_smoothed);
  }

  void clear() {
    _levels.clear();
    _smoothed = 0;
  }
}

/// A fixed microphone meter: history is retained by the existing recorder,
/// but only the latest smoothed measurement controls this display.
class EvidenceAudioAmplitudeWave extends StatelessWidget {
  const EvidenceAudioAmplitudeWave({
    super.key,
    required this.levels,
    this.animate = true,
  });
  final List<double> levels;
  final bool animate;
  static const barWidth = 6.0;
  static const gap = 10.0;
  static const profile = <double>[
    0.2,
    0.3,
    0.45,
    0.6,
    0.35,
    0.48,
    0.7,
    1,
    0.7,
    0.48,
    0.35,
    0.6,
    0.45,
    0.3,
    0.2,
  ];
  @override
  Widget build(BuildContext context) {
    final latest = levels.isEmpty || !levels.last.isFinite
        ? 0.0
        : levels.last.clamp(0, 1).toDouble();
    return Semantics(
      label: 'Live microphone level',
      child: LayoutBuilder(
        builder: (context, size) {
          const naturalWidth = 15 * barWidth + 14 * gap;
          final scale = (size.maxWidth / naturalWidth).clamp(0, 1).toDouble();
          final width = naturalWidth * scale;
          final minimum = size.maxHeight.clamp(0, 6).toDouble();
          return Center(
            child: SizedBox(
              width: width,
              height: size.maxHeight,
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: latest, end: latest),
                duration: animate
                    ? const Duration(milliseconds: 140)
                    : Duration.zero,
                curve: Curves.easeOut,
                builder: (context, level, _) => Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    for (var i = 0; i < profile.length; i++)
                      Container(
                        key: ValueKey('amplitude-$i'),
                        width: barWidth * scale,
                        height:
                            minimum +
                            (size.maxHeight - minimum) * profile[i] * level,
                        decoration: BoxDecoration(
                          // Expand from the left with level, never with elapsed time.
                          // Retain at least the rightmost light bar even at full input.
                          color: Color.lerp(
                            const Color(0xFFE5E5E5),
                            const Color(0xFF666666),
                            (level * 14 - i).clamp(0, 1).toDouble(),
                          ),
                          borderRadius: BorderRadius.circular(barWidth),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
