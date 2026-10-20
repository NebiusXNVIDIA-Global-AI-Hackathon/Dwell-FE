import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/app_colors.dart';
import '../../../core/theme.dart';
import '../../../shared/widgets/state_views.dart';
import '../models/hpd_history.dart';
import '../providers/my_place_providers.dart';
import '../widgets/charts/chart_legend.dart';
import '../widgets/charts/class_donut.dart';
import '../widgets/charts/quarterly_bar_chart.dart';
import '../widgets/common/my_place_app_bar.dart';
import '../widgets/common/segmented_tabs.dart';
import '../widgets/insights/hpd_summary_tile.dart';
import '../widgets/insights/insights_card.dart';

/// 공공기록 원문 — Overview 만 설계돼 있다
class HpdHistoryPage extends ConsumerStatefulWidget {
  const HpdHistoryPage({super.key});

  @override
  ConsumerState<HpdHistoryPage> createState() => _HpdHistoryPageState();
}

class _HpdHistoryPageState extends ConsumerState<HpdHistoryPage> {
  static const _tabs = ['Overview', 'Complaints', 'Violations'];

  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    final history = ref.watch(hpdHistoryProvider);

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            MyPlaceAppBar(
              title: 'HPD History',
              subtitle: 'NYC HPD public records',
              onBack: () => context.pop(),
            ),
            Expanded(
              child: history.when(
                loading: () => const LoadingView(),
                error: (error, _) => AppErrorView(
                  error: error,
                  onRetry: () => ref.invalidate(hpdHistoryProvider),
                ),
                data: (data) => ListView(
                  padding: const EdgeInsets.fromLTRB(
                    Gap.screenH,
                    Gap.sm,
                    Gap.screenH,
                    Gap.xl,
                  ),
                  children: [
                    SegmentedTabs(
                      labels: _tabs,
                      selected: _tab,
                      onSelected: (index) => setState(() => _tab = index),
                    ),
                    const SizedBox(height: Gap.card),
                    if (_tab == 0)
                      _Overview(history: data)
                    else
                      // 목록 화면은 아직 설계되지 않았다
                      const Padding(
                        padding: EdgeInsets.only(top: Gap.xl),
                        child: EmptyView(message: 'Coming soon'),
                      ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                Gap.screenH,
                0,
                Gap.screenH,
                Gap.lg,
              ),
              child: _HpdOnlineButton(url: history.value?.hpdOnlineUrl),
            ),
          ],
        ),
      ),
    );
  }
}

class _Overview extends StatelessWidget {
  const _Overview({required this.history});

  final HpdHistory history;

  @override
  Widget build(BuildContext context) {
    return Column(
      spacing: Gap.card,
      children: [
        InsightsCard(
          title: 'Violations by class',
          source: history.source,
          child: ClassDonut(
            centerCaption: 'total',
            sections: [
              for (final tally in history.violationsByClass)
                ClassDonutSection(
                  label: tally.violationClass,
                  total: tally.total,
                  open: tally.open,
                  color: _classColor(tally.violationClass),
                ),
            ],
          ),
        ),
        InsightsCard(
          title: 'Per quarter',
          badge: const ChartLegend(
            items: [
              ChartLegendItem(label: 'Complaints', color: AppColors.chartInk),
              ChartLegendItem(
                label: 'Violations',
                color: AppColors.chartDanger,
              ),
            ],
          ),
          source: history.source,
          child: QuarterlyBarChart(
            quarters: [
              for (final quarter in history.perQuarter)
                (
                  complaints: quarter.complaints,
                  violations: quarter.violations,
                ),
            ],
            startYear: _startYear,
          ),
        ),
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: Gap.sm,
            children: [
              Expanded(
                child: HpdSummaryTile(
                  count: history.complaints,
                  label: 'Complaints',
                  openColor: AppColors.chartWarning,
                ),
              ),
              Expanded(
                child: HpdSummaryTile(
                  count: history.violations,
                  label: 'Violations',
                  openColor: AppColors.chartDanger,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// `2024Q1` 에서 연도만
  int get _startYear => history.perQuarter.isEmpty
      ? DateTime.now().year
      : int.parse(history.perQuarter.first.quarter.split('Q').first);

  Color _classColor(String violationClass) =>
      switch (violationClass.characters.last) {
        'C' => AppColors.chartDanger,
        'B' => AppColors.chartWarning,
        _ => AppColors.chartNeutral,
      };
}

class _HpdOnlineButton extends StatelessWidget {
  const _HpdOnlineButton({required this.url});

  final String? url;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: url == null ? null : () => _open(context, url!),
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(48),
          side: const BorderSide(color: AppColors.navy, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(Gap.card),
          ),
        ),
        child: const Text(
          'HPD Online ↗',
          style: TextStyle(
            color: AppColors.navy,
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Future<void> _open(BuildContext context, String url) async {
    final opened = await launchUrl(
      Uri.parse(url),
      mode: LaunchMode.externalApplication,
    );
    if (opened || !context.mounted) return;
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
        const SnackBar(content: Text('Could not open HPD Online')),
      );
  }
}
