import '../data/case_creation_options.dart';
import '../models/case_draft.dart';

// The page owns this controller and rebuilds with setState.
class CaseCreationController {
  final CaseDraft draft = CaseDraft();
  int _currentStep = 1;
  int get currentStep => _currentStep;
  static const totalSteps = 7;
  String get issueSummary {
    final issue = CaseCreationOptions.requiresOtherInput(draft.specificIssue)
        ? draft.otherIssue.trim()
        : draft.specificIssue ?? '';
    return '${draft.issueType ?? ''} - $issue';
  }

  String get locationSummary =>
      CaseCreationOptions.requiresOtherLocationInput(draft.location)
      ? draft.otherLocation.trim()
      : draft.location ?? '';
  bool get canGoNext => switch (_currentStep) {
    1 => draft.issueType != null,
    2 =>
      draft.specificIssue != null &&
          (!CaseCreationOptions.requiresOtherInput(draft.specificIssue) ||
              draft.otherIssue.trim().isNotEmpty),
    3 =>
      draft.location != null &&
          (!CaseCreationOptions.requiresOtherLocationInput(draft.location) ||
              draft.otherLocation.trim().isNotEmpty),
    4 =>
      draft.affectedArea != null &&
          (!CaseCreationOptions.requiresOtherAffectedAreaInput(
                draft.affectedArea,
              ) ||
              draft.otherAffectedArea.trim().isNotEmpty),
    _ => false,
  };
  void selectIssueType(String value) {
    if (draft.issueType == value) return;
    draft.issueType = value;
    draft.specificIssue = null;
    draft.otherIssue = '';
    _resetLocation();
  }

  void selectSpecificIssue(String value) {
    if (draft.specificIssue == value) return;
    draft.specificIssue = value;
    draft.otherIssue = '';
    _resetLocation();
  }

  void _resetLocation() {
    draft.location = null;
    draft.otherLocation = '';
    _resetAffectedArea();
  }

  void _resetAffectedArea() {
    draft.affectedArea = null;
    draft.otherAffectedArea = '';
  }

  void selectLocation(String value) {
    if (draft.location == value) return;
    draft.location = value;
    draft.otherLocation = '';
    _resetAffectedArea();
  }

  void selectAffectedArea(String value) {
    if (draft.affectedArea == value) return;
    draft.affectedArea = value;
    draft.otherAffectedArea = '';
  }

  void setOtherIssue(String value) => draft.otherIssue = value;
  void setOtherLocation(String value) => draft.otherLocation = value;
  void setOtherAffectedArea(String value) => draft.otherAffectedArea = value;
  void editIssue() => _currentStep = 1;
  void editLocation() => _currentStep = 3;
  void next() {
    if (!canGoNext) return;
    switch (_currentStep) {
      case 1:
      case 2:
        _currentStep++;
        return;
      case 3:
        if (CaseCreationOptions.skipsAffectedArea(draft.location)) {
          // TODO: Move Entire Unit directly to Step 5 · Add Evidence when implemented.
          return;
        }
        _currentStep = 4;
        return;
      case 4:
        // TODO: Move to Step 5 · Add Evidence when implemented.
        return;
    }
  }
}
