import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../controllers/evidence_analysis_controller.dart';
import '../models/evidence_analysis_input.dart';
import '../widgets/creation/analysis_progress_item.dart';
import '../widgets/creation/evidence_analysis_preview.dart';

class AnalyzingEvidencePage extends ConsumerStatefulWidget {
  const AnalyzingEvidencePage({
    super.key,
    required this.input,
    this.onMockCompleted,
  });
  final EvidenceAnalysisInput input;

  /// A progress-only event for a future flow; not confirmation of case creation.
  final VoidCallback? onMockCompleted;

  @override
  ConsumerState<AnalyzingEvidencePage> createState() =>
      _AnalyzingEvidencePageState();
}

class _AnalyzingEvidencePageState extends ConsumerState<AnalyzingEvidencePage> {
  late final EvidenceAnalysisController _analysis;
  bool _completionNotified = false;

  @override
  void initState() {
    super.initState();
    _analysis = ref.read(evidenceAnalysisControllerFactoryProvider)();
    _analysis.addListener(_completed);
    _analysis.start();
  }

  void _completed() {
    if (!mounted || !_analysis.isComplete || _completionNotified) return;
    _completionNotified = true;
    widget.onMockCompleted?.call();
  }

  @override
  void dispose() {
    _analysis.removeListener(_completed);
    _analysis.dispose();
    // Creation remains the evidence owner. Media widgets release their readers;
    // popping analysis must not delete attachments needed by Step 6 reentry.
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFFF8F8F8),
    body: SafeArea(
      child: SingleChildScrollView(
        key: const ValueKey('analysis-scroll'),
        padding: EdgeInsets.fromLTRB(
          widget.input.evidence.length > 1 ? 16 : 27,
          84,
          widget.input.evidence.length > 1 ? 16 : 18,
          widget.input.evidence.length > 1 ? 16 : 32,
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Analyzing evidence...',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Color(0xFF243B53),
                    fontSize: 30,
                    fontWeight: FontWeight.w700,
                    height: 1.3,
                  ),
                ),
                SizedBox(height: widget.input.evidence.length > 1 ? 32 : 34),
                EvidenceAnalysisPreview(evidence: widget.input.evidence),
                SizedBox(height: widget.input.evidence.length > 1 ? 24 : 32),
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: widget.input.evidence.length > 1 ? 20 : 13,
                  ),
                  child: ListenableBuilder(
                    listenable: _analysis,
                    builder: (context, _) => Column(
                      children: [
                        for (
                          var index = 0;
                          index < evidenceAnalysisLabels.length;
                          index++
                        )
                          AnalysisProgressItem(
                            key: ValueKey('analysis-progress-$index'),
                            label: evidenceAnalysisLabels[index],
                            state: _analysis.stateAt(index),
                          ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: widget.input.evidence.length > 1 ? 24 : 62),
                const Text(
                  'This usually takes a few seconds ...',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Color(0xFF858E96),
                    fontSize: 20,
                    fontWeight: FontWeight.w500,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
