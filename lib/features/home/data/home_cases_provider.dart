import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'home_mock_data.dart';

/// Override this source for API data; Home and Reports remain independent.
final homeCasesProvider = FutureProvider<List<HomeCaseData>>(
  (ref) => homeCases,
);
