import 'case_draft.dart';
import 'evidence_model.dart';

/// Route payload, not a second draft store. The creation route remains mounted
/// underneath its analysis child and owns these models until the flow exits.
/// Preview widgets use the existing player/thumbnail reader leases.
final class EvidenceAnalysisInput {
  EvidenceAnalysisInput(CaseDraftView draft, List<EvidenceModel> evidence)
    : draft = draft.snapshot(),
      evidence = List.unmodifiable(evidence);

  final CaseDraftView draft;
  final List<EvidenceModel> evidence;
  bool get isAvailable =>
      evidence.isNotEmpty && evidence.every((item) => !item.isDisposed);
}
