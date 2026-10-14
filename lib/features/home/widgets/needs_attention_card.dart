import 'package:material_ui/material_ui.dart';

class NeedsAttentionCard extends StatelessWidget {
  const NeedsAttentionCard({
    super.key,
    required this.message,
    this.onCheckUnit,
  });
  final String message;
  final VoidCallback? onCheckUnit;

  Widget _details() => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    mainAxisSize: MainAxisSize.min,
    children: [
      Text(
        message,
        style: const TextStyle(
          fontSize: 16,
          height: 1.15,
          fontWeight: FontWeight.w600,
          color: Color(0xFF243B53),
        ),
      ),
      const SizedBox(height: 14),
      ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 32),
        child: FilledButton(
          key: const ValueKey('home-check-unit'),
          onPressed: onCheckUnit,
          style:
              FilledButton.styleFrom(
                backgroundColor: const Color(0xFF2C5861),
                foregroundColor: Colors.white,
                splashFactory: NoSplash.splashFactory,
                overlayColor: Colors.transparent,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                minimumSize: const Size(0, 32),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                textStyle: const TextStyle(
                  fontFamily: 'Pretendard Variable',
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
                shape: const StadiumBorder(),
              ).copyWith(
                backgroundColor: WidgetStateProperty.resolveWith(
                  (states) => states.contains(WidgetState.pressed)
                      ? const Color(0xFF416D76)
                      : const Color(0xFF2C5861),
                ),
              ),
          child: const Text('Check my unit', textAlign: TextAlign.center),
        ),
      ),
    ],
  );

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final stacked =
          constraints.maxWidth < 320 ||
          MediaQuery.textScalerOf(context).scale(16) > 22;
      // The PNG is the unmodified bitmap embedded in the supplied Figma SVG.
      final image = Image.asset(
        'assets/images/beaver_inspection.png',
        fit: BoxFit.contain,
      );
      return Padding(
        padding: const EdgeInsets.only(top: 16),
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFFF8F6F1),
            border: Border.all(color: const Color(0xFFE3E3E3)),
            borderRadius: BorderRadius.circular(8),
          ),
          child: stacked
              ? Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      SizedBox(height: 160, child: image),
                      const SizedBox(height: 12),
                      _details(),
                    ],
                  ),
                )
              : Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(171, 13, 15, 8),
                      child: _details(),
                    ),
                    Positioned(
                      left: 3,
                      top: -28,
                      bottom: -8,
                      width: 166,
                      child: Transform.scale(scale: 1.2, child: image),
                    ),
                  ],
                ),
        ),
      );
    },
  );
}
