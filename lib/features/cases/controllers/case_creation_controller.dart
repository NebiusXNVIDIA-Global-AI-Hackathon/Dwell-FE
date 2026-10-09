import '../data/case_creation_options.dart';
import '../models/case_draft.dart';

// The page owns this controller and rebuilds with setState.
class CaseCreationController {
  final CaseDraft _draft = CaseDraft();
  late final CaseDraftView _draftView = CaseDraftView(_draft);
  CaseDraftView get draft => _draftView;
  int _currentStep = 1;
  int get currentStep => _currentStep;
  static const totalSteps = 7;
  String get issueSummary {
    final issue = CaseCreationOptions.requiresOtherInput(_draft.specificIssue)
        ? _draft.otherIssue.trim()
        : _draft.specificIssue ?? '';
    return '${_draft.issueType ?? ''} - $issue';
  }

  String get locationSummary =>
      CaseCreationOptions.requiresOtherLocationInput(_draft.location)
      ? _draft.otherLocation.trim()
      : _draft.location ?? '';
  bool get canGoNext => switch (_currentStep) {
    1 => _hasIssueType,
    2 => _hasSpecificIssue,
    3 => _hasSpecificIssue && _hasLocation,
    4 =>
      _hasSpecificIssue &&
          _hasLocation &&
          _hasAffectedArea &&
          (!CaseCreationOptions.requiresOtherAffectedAreaInput(
                _draft.affectedArea,
              ) ||
              _draft.otherAffectedArea.trim().isNotEmpty),
    _ => false,
  };
  bool get _hasIssueType =>
      CaseCreationOptions.issueTypes.containsKey(_draft.issueType);
  bool get _hasSpecificIssue =>
      _hasIssueType &&
      (CaseCreationOptions.specificIssues[_draft.issueType]?.contains(
            _draft.specificIssue,
          ) ??
          false) &&
      (!CaseCreationOptions.requiresOtherInput(_draft.specificIssue) ||
          _draft.otherIssue.trim().isNotEmpty);
  bool get _hasLocation =>
      _hasIssueType &&
      CaseCreationOptions.locations.containsKey(_draft.location) &&
      (!CaseCreationOptions.requiresOtherLocationInput(_draft.location) ||
          _draft.otherLocation.trim().isNotEmpty);
  bool get _hasAffectedArea =>
      (_affectedAreas?.containsKey(_draft.affectedArea) ?? false);
  Map<String, String>? get _affectedAreas =>
      CaseCreationOptions.affectedAreas[_draft.location];

  void selectIssueType(String value) {
    if (!CaseCreationOptions.issueTypes.containsKey(value)) {
      throw ArgumentError.value(value, 'value', 'Unknown issue type');
    }
    if (_draft.issueType == value) return;
    _draft.issueType = value;
    _draft.specificIssue = null;
    _draft.otherIssue = '';
    _resetLocation();
  }

  void selectSpecificIssue(String value) {
    if (!_hasIssueType) throw StateError('Select an issue type first');
    if (!CaseCreationOptions.specificIssues[_draft.issueType]!.contains(
      value,
    )) {
      throw ArgumentError.value(
        value,
        'value',
        'Issue does not belong to the selected type',
      );
    }
    if (_draft.specificIssue == value) return;
    _draft.specificIssue = value;
    _draft.otherIssue = '';
    _resetLocation();
  }

  void _resetLocation() {
    _draft.location = null;
    _draft.otherLocation = '';
    _resetAffectedArea();
  }

  void _resetAffectedArea() {
    _draft.affectedArea = null;
    _draft.otherAffectedArea = '';
  }

  void selectLocation(String value) {
    if (!_hasIssueType) throw StateError('Select an issue type first');
    // Locations are shared by all issue types in the current options data.
    if (!CaseCreationOptions.locations.containsKey(value)) {
      throw ArgumentError.value(value, 'value', 'Unknown location');
    }
    if (_draft.location == value) return;
    _draft.location = value;
    _draft.otherLocation = '';
    _resetAffectedArea();
  }

  void selectAffectedArea(String value) {
    if (!CaseCreationOptions.locations.containsKey(_draft.location)) {
      throw StateError('Select a location first');
    }
    if (!(_affectedAreas?.containsKey(value) ?? false)) {
      throw ArgumentError.value(
        value,
        'value',
        'Area does not belong to the selected location',
      );
    }
    if (_draft.affectedArea == value) return;
    _draft.affectedArea = value;
    _draft.otherAffectedArea = '';
  }

  void setOtherIssue(String value) {
    if (!CaseCreationOptions.requiresOtherInput(_draft.specificIssue)) {
      throw StateError(
        'Select Other or Other Appliance before entering an issue',
      );
    }
    _draft.otherIssue = value;
  }

  void setOtherLocation(String value) {
    if (!CaseCreationOptions.requiresOtherLocationInput(_draft.location)) {
      throw StateError('Select Other before entering a location');
    }
    _draft.otherLocation = value;
  }

  void setOtherAffectedArea(String value) {
    if (!CaseCreationOptions.requiresOtherAffectedAreaInput(
      _draft.affectedArea,
    )) {
      throw StateError('Select Other before entering an affected area');
    }
    _draft.otherAffectedArea = value;
  }

  bool get canOpenEvidenceGuide =>
      canGoNext &&
      (_currentStep == 4 ||
          (_currentStep == 3 &&
              CaseCreationOptions.skipsAffectedArea(_draft.location)));

  void beginEvidence() {
    if (canOpenEvidenceGuide) _currentStep = 5;
  }

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
        if (CaseCreationOptions.skipsAffectedArea(_draft.location)) {
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
