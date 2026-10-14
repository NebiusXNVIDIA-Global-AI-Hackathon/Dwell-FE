import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

const evidenceAnalysisLabels = [
  'Attachment received',
  'Checking visible damage',
  'Analyzing the Attachment',
  'Analyzing your description',
  'Assessing severity',
];

enum AnalysisProgressState { waiting, running, completed }

/// Replace this runner with an API-backed implementation when analysis exists.
/// Completion here is progress completion, never evidence validation or a case.
abstract class EvidenceAnalysisController extends ChangeNotifier {
  int get completedCount;
  bool get isRunning;
  bool get isComplete => completedCount == evidenceAnalysisLabels.length;
  AnalysisProgressState stateAt(int index) {
    RangeError.checkValidIndex(index, evidenceAnalysisLabels);
    if (index < completedCount) return AnalysisProgressState.completed;
    if (index == completedCount && isRunning) {
      return AnalysisProgressState.running;
    }
    return AnalysisProgressState.waiting;
  }

  void start();
  void cancel();
}

/// UI demonstration only: does not read files, call AI, assign severity, create
/// cases, generate IDs, or mark attachments as analyzed.
final class MockEvidenceAnalysisController extends EvidenceAnalysisController {
  MockEvidenceAnalysisController({
    this.interval = const Duration(milliseconds: 900),
  }) : assert(interval > Duration.zero);

  final Duration interval;
  Timer? _timer;
  bool _started = false;
  bool _disposed = false;
  int _completedCount = 0;
  @override
  int get completedCount => _completedCount;
  @override
  bool get isRunning => _timer != null;

  @override
  void start() {
    if (_started || _disposed) return;
    _started = true;
    _timer = Timer.periodic(interval, (_) {
      if (_disposed) return;
      _completedCount++;
      if (isComplete) cancel();
      notifyListeners();
    });
    notifyListeners();
  }

  @override
  void cancel() {
    _timer?.cancel();
    _timer = null;
  }

  @override
  void dispose() {
    _disposed = true;
    cancel();
    super.dispose();
  }
}

final evidenceAnalysisControllerFactoryProvider =
    Provider<EvidenceAnalysisController Function()>(
      (ref) =>
          () => MockEvidenceAnalysisController(),
    );
