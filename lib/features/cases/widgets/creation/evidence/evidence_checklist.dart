import 'package:material_ui/material_ui.dart';

import '../../../controllers/mock_evidence_check_controller.dart';

class EvidenceChecklist extends StatelessWidget {
  const EvidenceChecklist({super.key, this.controller});
  final MockEvidenceCheckController? controller;
  static const green = Color(0xFF1E7011);
  @override
  Widget build(BuildContext context) => controller == null
      ? _content(context)
      : ListenableBuilder(
          listenable: controller!,
          builder: (context, _) => _content(context),
        );
  Widget _content(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          controller?.demoEnabled == false
              ? 'AI analysis not connected · Check unavailable'
              : 'Demo preview · AI analysis not connected',
          key: const ValueKey('evidence-check-notice'),
          style: const TextStyle(fontSize: 12, color: Color(0xFF627381)),
        ),
        const SizedBox(height: 12),
        for (var i = 0; i < evidenceCheckLabels.length; i++) ...[
          if (i > 0) const SizedBox(height: 16),
          _item(context, i),
        ],
      ],
    ),
  );
  Widget _item(BuildContext context, int index) {
    final done = index < (controller?.completedCount ?? 0);
    final checking = index == controller?.currentIndex;
    final state = done
        ? 'Demo completed'
        : checking
        ? 'Checking demo'
        : 'Not checked';
    return Semantics(
      key: ValueKey('evidence-check-item-$index'),
      liveRegion: true,
      label: '${evidenceCheckLabels[index]}. $state. No AI analysis.',
      excludeSemantics: true,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 34,
            height: 34,
            child: AnimatedSwitcher(
              duration: MediaQuery.disableAnimationsOf(context)
                  ? Duration.zero
                  : evidenceCheckTransitionDuration,
              transitionBuilder: (child, animation) => FadeTransition(
                opacity: animation,
                child: ScaleTransition(scale: animation, child: child),
              ),
              child: done
                  ? Container(
                      key: ValueKey('evidence-check-done-$index'),
                      decoration: const BoxDecoration(
                        color: green,
                        shape: BoxShape.circle,
                      ),
                      child: const Center(
                        child: Icon(Icons.check, size: 25, color: Colors.white),
                      ),
                    )
                  : checking
                  ? SizedBox(
                      key: ValueKey('evidence-check-loading-$index'),
                      width: 34,
                      height: 34,
                      child: const CircularProgressIndicator(
                        strokeWidth: 2,
                        color: green,
                        backgroundColor: Color(0xFFD6DCD5),
                      ),
                    )
                  : Container(
                      key: ValueKey('evidence-check-idle-$index'),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: const Color(0xFF627381),
                          width: 2,
                        ),
                      ),
                    ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              evidenceCheckLabels[index],
              style: const TextStyle(
                fontSize: 20,
                height: 1.25,
                fontWeight: FontWeight.w400,
                color: Color(0xFF627381),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
