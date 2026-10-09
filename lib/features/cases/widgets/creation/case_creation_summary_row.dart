import 'package:flutter/rendering.dart';
import 'package:material_ui/material_ui.dart';

class CaseCreationSummaryRow extends StatelessWidget {
  const CaseCreationSummaryRow({
    super.key,
    required this.stepNumber,
    required this.value,
    required this.onEdit,
  });

  final int stepNumber;
  final String value;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    // Preserve the 32px badge at normal scale; enlarge for accessibility.
    final badgeSize =
        32.0 *
        (MediaQuery.textScalerOf(context).scale(16) / 16).clamp(
          1.0,
          double.infinity,
        );
    return _SummaryTouchStack(
      topExtension: stepNumber == 1 ? 7 : 5,
      bottomExtension: stepNumber == 1 ? 5 : 7,
      children: [
        Positioned(
          right: 0,
          top: stepNumber == 1 ? -7 : -5,
          bottom: stepNumber == 1 ? -5 : -7,
          width: 44,
          child: Semantics(
            label: 'Edit',
            button: true,
            onTap: onEdit,
            excludeSemantics: true,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onEdit,
                canRequestFocus: false,
                excludeFromSemantics: true,
                overlayColor: const WidgetStatePropertyAll(Colors.transparent),
              ),
            ),
          ),
        ),
        Row(
          children: [
            Container(
              width: badgeSize,
              height: badgeSize,
              alignment: Alignment.center,
              decoration: const BoxDecoration(
                color: Color(0xFF243B53),
                shape: BoxShape.circle,
              ),
              child: Text(
                '$stepNumber',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: IgnorePointer(
                child: Text(
                  value,
                  style: const TextStyle(
                    color: Color(0xFF243B53),
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            ExcludeSemantics(
              child: TextButton(
                onPressed: onEdit,
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFF007AFF),
                  minimumSize: const Size(0, 32),
                  padding: EdgeInsets.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  textStyle: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                child: const Text('Edit'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// The parent Column includes the existing gaps around each summary row.
// Admit hits in those gaps explicitly; an overflowing Stack alone cannot.
// The asymmetric extensions keep the two Step 4 targets disjoint (10px gap).
class _SummaryTouchStack extends Stack {
  const _SummaryTouchStack({
    required this.topExtension,
    required this.bottomExtension,
    required super.children,
  });
  final double topExtension;
  final double bottomExtension;
  @override
  RenderStack createRenderObject(BuildContext context) =>
      _SummaryTouchRenderStack(
        topExtension,
        bottomExtension,
        textDirection: Directionality.of(context),
      );
  @override
  void updateRenderObject(
    BuildContext context,
    covariant _SummaryTouchRenderStack renderObject,
  ) {
    super.updateRenderObject(context, renderObject);
    renderObject.topExtension = topExtension;
    renderObject.bottomExtension = bottomExtension;
  }
}

class _SummaryTouchRenderStack extends RenderStack {
  _SummaryTouchRenderStack(
    this.topExtension,
    this.bottomExtension, {
    super.textDirection,
  });
  double topExtension;
  double bottomExtension;
  @override
  Rect get semanticBounds => Rect.fromLTRB(
    0,
    -topExtension,
    size.width,
    size.height + bottomExtension,
  );
  @override
  bool hitTest(BoxHitTestResult result, {required Offset position}) {
    if (semanticBounds.contains(position) &&
        hitTestChildren(result, position: position)) {
      result.add(BoxHitTestEntry(this, position));
      return true;
    }
    return false;
  }
}
