import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../models/timeline_step.dart';
import '../../state/case_detail_controller.dart';
import '../case_detail_tokens.dart';
import '../widgets/case_detail_app_bar.dart';
import '../widgets/case_header.dart';
import '../widgets/timeline_event_tile.dart';

class CaseTimelineScreen extends ConsumerWidget {
  const CaseTimelineScreen({super.key, required this.caseId});

  final String caseId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detail = ref.watch(caseDetailProvider(caseId));
    final events = [
      for (final step in detail?.timeline ?? const <TimelineStepData>[])
        if (step.state != TimelineStepState.upcoming) step,
    ];

    return Scaffold(
      backgroundColor: CaseDetailColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: CaseDetailGaps.ctaBottom),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              CaseDetailAppBar(title: 'Case Timeline', onBack: context.pop),
              if (detail != null) ...[
                const SizedBox(height: CaseDetailGaps.appBarToHeader),
                CaseHeader(detail: detail),
                const SizedBox(height: CaseDetailGaps.headerToEvents),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: CaseDetailSizes.statusInset,
                  ),
                  child: Column(
                    children: [
                      for (final (index, step) in events.indexed)
                        TimelineEventTile(
                          step: step,
                          isFirst: index == 0,
                          isLast: index == events.length - 1,
                        ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
