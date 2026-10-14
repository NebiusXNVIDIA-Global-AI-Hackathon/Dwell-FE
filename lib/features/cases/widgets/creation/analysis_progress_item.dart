import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:material_ui/material_ui.dart';

import '../../controllers/evidence_analysis_controller.dart';

class AnalysisProgressItem extends StatelessWidget {
  const AnalysisProgressItem({
    super.key,
    required this.label,
    required this.state,
  });
  final String label;
  final AnalysisProgressState state;

  @override
  Widget build(BuildContext context) {
    const green = Color(0xFF1F7011);
    return Semantics(
      liveRegion: state == AnalysisProgressState.running,
      label: '$label, ${state.name}',
      excludeSemantics: true,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.5),
        child: Row(
          children: [
            SizedBox(
              width: 34,
              height: 34,
              child: switch (state) {
                AnalysisProgressState.running =>
                  const CircularProgressIndicator(
                    color: green,
                    backgroundColor: Color(0xFFD1D8D1),
                    strokeWidth: 2,
                  ),
                AnalysisProgressState.waiting => DecoratedBox(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFFBFCDBF),
                      width: 2,
                    ),
                  ),
                ),
                AnalysisProgressState.completed => const DecoratedBox(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: green,
                  ),
                  child: Icon(LucideIcons.check, color: Colors.white, size: 22),
                ),
              },
            ),
            const SizedBox(width: 23),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  color: Color(0xFF637381),
                  fontSize: 20,
                  fontWeight: FontWeight.w500,
                  height: 1.25,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
