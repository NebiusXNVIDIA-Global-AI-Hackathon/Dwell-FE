import 'package:material_ui/material_ui.dart';

class NextStepChecklist extends StatelessWidget {
  const NextStepChecklist({
    super.key,
    required this.items,
    required this.checked,
    required this.onChanged,
  });
  final List<String> items;
  final Set<int> checked;
  final void Function(int, bool) onChanged;

  @override
  Widget build(BuildContext context) => Container(
    decoration: const BoxDecoration(
      color: Colors.white,
      boxShadow: [
        BoxShadow(
          color: Color(0x33000000),
          blurRadius: 3,
          offset: Offset(0, 4),
        ),
      ],
    ),
    child: Stack(
      children: [
        Positioned(
          top: 0,
          bottom: 0,
          left: 45,
          child: Container(width: 1, color: const Color(0xFFBE8282)),
        ),
        Positioned(
          top: 0,
          bottom: 0,
          left: 49,
          child: Container(width: 1, color: const Color(0xFFBE8282)),
        ),
        Positioned(
          top: 17,
          left: 15,
          child: Column(
            children: [
              for (var i = 0; i < 4; i++) ...[
                Container(
                  width: 18,
                  height: 18,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8F8F8),
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFFD7D7D7)),
                    boxShadow: const [
                      BoxShadow(color: Color(0x18000000), blurRadius: 2),
                    ],
                  ),
                ),
                if (i < 3) const SizedBox(height: 15),
              ],
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(62, 16, 26, 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Checklist for Next Step',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF243B53),
                ),
              ),
              const SizedBox(height: 6),
              for (var i = 0; i < items.length; i++) ...[
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => onChanged(i, !checked.contains(i)),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 23,
                        height: 24,
                        child: Checkbox(
                          key: ValueKey('home-checklist-$i'),
                          value: checked.contains(i),
                          onChanged: (value) => onChanged(i, value == true),
                          fillColor: const WidgetStatePropertyAll(
                            Colors.transparent,
                          ),
                          checkColor: const Color(0xFF243B53),
                          side: WidgetStateBorderSide.resolveWith(
                            (states) => BorderSide(
                              color: states.contains(WidgetState.selected)
                                  ? const Color(0xFF243B53)
                                  : const Color(0xFFE3E3E3),
                            ),
                          ),
                          shape: const RoundedRectangleBorder(),
                          materialTapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                          visualDensity: VisualDensity.compact,
                          semanticLabel: items[i],
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: CustomPaint(
                          painter: _NotebookLines(
                            MediaQuery.textScalerOf(context).scale(12) * 1.85,
                          ),
                          child: Text(
                            items[i],
                            style: const TextStyle(
                              fontSize: 12,
                              height: 1.85,
                              color: Color(0xFF606060),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                if (i < items.length - 1) const SizedBox(height: 12),
              ],
            ],
          ),
        ),
      ],
    ),
  );
}

class _NotebookLines extends CustomPainter {
  const _NotebookLines(this.lineHeight);
  final double lineHeight;
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFE3E3E3)
      ..strokeWidth = 1;
    // Each text line has its own rule, including wrapped checklist entries.
    final lineCount = (size.height / lineHeight).round().clamp(1, 100);
    for (var i = 1; i <= lineCount; i++) {
      final y = size.height * i / lineCount;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(_NotebookLines oldDelegate) =>
      oldDelegate.lineHeight != lineHeight;
}
