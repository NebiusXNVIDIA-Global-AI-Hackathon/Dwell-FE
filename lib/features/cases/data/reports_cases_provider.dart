import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/case_model.dart';
import 'mock_cases.dart';

/// Invalidate after a future mutation to reload without resetting list controls.
/// Home has a separate demo source and is never populated from these fixtures.
final reportsCasesProvider = FutureProvider<List<CaseModel>>(
  (ref) => List<CaseModel>.unmodifiable(mockCases),
);
