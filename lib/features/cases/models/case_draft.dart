class CaseDraft {
  String? issueType;
  String? specificIssue;
  String? location;
  String? affectedArea;
  String otherIssue = '';
  String otherLocation = '';
  String otherAffectedArea = '';
}

/// Read-only live view; the controller keeps ownership of the mutable draft.
/// No setters or mutable objects are exposed, and reads do not allocate copies.
final class CaseDraftView {
  CaseDraftView(this._draft);

  final CaseDraft _draft;

  String? get issueType => _draft.issueType;
  String? get specificIssue => _draft.specificIssue;
  String? get location => _draft.location;
  String? get affectedArea => _draft.affectedArea;
  String get otherIssue => _draft.otherIssue;
  String get otherLocation => _draft.otherLocation;
  String get otherAffectedArea => _draft.otherAffectedArea;
}
