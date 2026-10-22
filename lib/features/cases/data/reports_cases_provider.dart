import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../case_detail/state/deleted_cases_provider.dart';
import '../models/case_model.dart';
import 'mock_cases.dart';

/// Invalidate after a future mutation to reload without resetting list controls.
/// Home has a separate demo source and is never populated from these fixtures.
final reportsCasesProvider = FutureProvider<List<CaseModel>>((ref) {
  // Hide cases deleted from Case Detail
  final deleted = ref.watch(deletedCaseIdsProvider);
  return List<CaseModel>.unmodifiable(
    mockCases.where((item) => !deleted.contains(item.id)),
  );
});
