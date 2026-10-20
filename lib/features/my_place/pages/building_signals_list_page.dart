import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/app_colors.dart';
import '../../../core/theme.dart';
import '../../../shared/widgets/state_views.dart';
import '../models/building_signal.dart';
import '../providers/my_place_providers.dart';
import '../widgets/common/my_place_app_bar.dart';
import '../widgets/main/rising_issue_row.dart';
import '../widgets/main/signal_pattern_card.dart';

/// 건물에서 올라오는 시그널 모음 — 대표 패턴 + 나머지 이슈
class BuildingSignalsListPage extends ConsumerWidget {
  const BuildingSignalsListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final signals = ref.watch(buildingSignalsProvider);

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            MyPlaceAppBar(
              title: 'Building Signals',
              onBack: () => context.pop(),
            ),
            Expanded(
              child: signals.when(
                loading: () => const LoadingView(),
                error: (error, _) => AppErrorView(
                  error: error,
                  onRetry: () => ref.invalidate(buildingSignalsProvider),
                ),
                data: (data) => _Content(signals: data),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Content extends StatelessWidget {
  const _Content({required this.signals});

  final BuildingSignals signals;

  @override
  Widget build(BuildContext context) {
    final primary = signals.primary;

    if (primary == null && signals.risingIssues.isEmpty) {
      return const EmptyView(message: 'No signals in your building yet');
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        Gap.screenH,
        Gap.sm,
        Gap.screenH,
        Gap.xl,
      ),
      children: [
        if (primary != null) ...[
          SignalPatternCard(
            signal: primary,
            onViewDetails: () =>
                context.push('/my-place/signals/${primary.signalId}'),
          ),
          const SizedBox(height: Gap.lg),
        ],
        const Padding(
          padding: EdgeInsets.only(bottom: Gap.card),
          child: Text(
            'Rising Issue',
            style: TextStyle(
              color: AppColors.textTitle,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        for (final signal in signals.risingIssues)
          Padding(
            padding: const EdgeInsets.only(bottom: Gap.sm),
            child: RisingIssueRow(
              signal: signal,
              onTap: () => context.push('/my-place/signals/${signal.signalId}'),
            ),
          ),
      ],
    );
  }
}
