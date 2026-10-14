import 'case_creation_result.dart';

/// One-shot presentation event. Not a persisted case or a URL success flag.
final class ReportsCreationNotice {
  ReportsCreationNotice.fromResult(CaseCreationResult result)
    : isDemo = result.isDemo;

  final bool isDemo;
  bool _consumed = false;
  String get message =>
      isDemo ? 'Demo case created' : 'Case created successfully';

  bool consume() {
    if (_consumed) return false;
    _consumed = true;
    return true;
  }
}
