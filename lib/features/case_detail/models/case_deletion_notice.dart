/// One-shot event that tells the Cases screen to show the deletion toast.
final class CaseDeletionNotice {
  CaseDeletionNotice(this.caseId);

  final String caseId;
  bool _consumed = false;
  String get message => 'Case deleted';

  bool consume() {
    if (_consumed) return false;
    _consumed = true;
    return true;
  }
}
