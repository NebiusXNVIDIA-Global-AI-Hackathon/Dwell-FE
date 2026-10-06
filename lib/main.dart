import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fquery/fquery.dart';
import 'package:fquery_core/fquery_core.dart';
import 'package:material_ui/material_ui.dart';

import 'app.dart';

void main() {
  runApp(
    ProviderScope(
      // fquery 캐시 — 아직 미사용
      child: CacheProvider(cache: QueryCache(), child: const DwellApp()),
    ),
  );
}
