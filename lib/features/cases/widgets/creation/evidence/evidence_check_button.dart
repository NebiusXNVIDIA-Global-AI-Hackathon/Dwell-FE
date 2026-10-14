import 'package:material_ui/material_ui.dart';

import '../../../controllers/mock_evidence_check_controller.dart';
import '../case_creation_bottom.dart';

/// Measure the longest label once per layout so larger text remains readable,
/// and the pinned button never jumps between Check, Checking and Next.
class EvidenceCheckButton extends StatelessWidget {
  const EvidenceCheckButton({
    super.key,
    required this.controller,
    required this.onPressed,
    this.active = true,
  });
  final MockEvidenceCheckController controller;
  final VoidCallback onPressed;
  final bool active;
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final painter =
          TextPainter(
            text: TextSpan(
              text: 'Checking your evidence...',
              style: Theme.of(context).textTheme.labelLarge
                  ?.copyWith(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            textScaler: MediaQuery.textScalerOf(context),
            textDirection: Directionality.of(context),
            textAlign: TextAlign.center,
          )..layout(
            maxWidth: (constraints.maxWidth - 32).clamp(1, double.infinity),
          );
      final height = (painter.height + 24)
          .clamp(56, double.infinity)
          .toDouble();
      painter.dispose();
      return ListenableBuilder(
        listenable: controller,
        builder: (context, _) => CaseCreationBottom(
          enabled: active && controller.buttonEnabled,
          onNext: onPressed,
          label: controller.buttonLabel,
          height: height,
          textStyle: Theme.of(context).textTheme.labelLarge
              ?.copyWith(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      );
    },
  );
}
