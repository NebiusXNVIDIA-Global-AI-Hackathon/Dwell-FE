import 'dart:async';

import 'package:flutter/foundation.dart';

import 'evidence_controller.dart';

const mockEvidenceCheckInterval = Duration(milliseconds: 700);
const evidenceCheckTransitionDuration = Duration(milliseconds: 200);
const evidenceCheckLabels = [
  'Damage is visible',
  'Every item is clear and steady',
  'Surrounding area included',
];

enum MockEvidenceCheckStatus { idle, checking, completed }

/// Presentation-only demo. Never writes to EvidenceModel or CaseDraft and
/// never interprets file content. Replace the runner when a real API exists.
class MockEvidenceCheckController extends ChangeNotifier {
  MockEvidenceCheckController(
    this.evidence, {
    this.interval = mockEvidenceCheckInterval,
  }) {
    _ids = evidence.items.map((item) => item.id).toList();
    evidence.addListener(_evidenceChanged);
  }
  final EvidenceController evidence;
  final Duration interval;
  late List<String> _ids;
  Timer? _timer;
  int _generation = 0;
  bool _disposed = false;
  MockEvidenceCheckStatus _status = MockEvidenceCheckStatus.idle;
  int _completedCount = 0;
  MockEvidenceCheckStatus get status => _status;
  int get completedCount => _completedCount;
  int? get currentIndex =>
      status == MockEvidenceCheckStatus.checking ? _completedCount : null;
  bool get buttonEnabled =>
      !_disposed &&
      _ids.isNotEmpty &&
      status != MockEvidenceCheckStatus.checking;
  String get buttonLabel => switch (status) {
    MockEvidenceCheckStatus.idle => 'Check',
    MockEvidenceCheckStatus.checking => 'Checking your evidence...',
    MockEvidenceCheckStatus.completed => 'Next',
  };

  void start() {
    if (!buttonEnabled) return;
    final generation = ++_generation;
    _completedCount = 0;
    _status = MockEvidenceCheckStatus.checking;
    _timer = Timer.periodic(interval, (_) {
      if (_disposed ||
          generation != _generation ||
          status != MockEvidenceCheckStatus.checking) {
        return;
      }
      _completedCount++;
      if (_completedCount == evidenceCheckLabels.length) {
        _timer?.cancel();
        _timer = null;
        _status = MockEvidenceCheckStatus.completed;
      }
      notifyListeners();
    });
    notifyListeners();
  }

  void _evidenceChanged() {
    final ids = evidence.items.map((item) => item.id).toList();
    // Selection and playback updates must not invalidate the demo.
    if (listEquals(ids, _ids)) return;
    _ids = ids;
    _reset();
    notifyListeners();
  }

  void _reset() {
    ++_generation;
    _timer?.cancel();
    _timer = null;
    _status = MockEvidenceCheckStatus.idle;
    _completedCount = 0;
  }

  void cancelChecking() {
    if (_disposed || status != MockEvidenceCheckStatus.checking) return;
    _reset();
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    evidence.removeListener(_evidenceChanged);
    _reset();
    super.dispose();
  }
}
