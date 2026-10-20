import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/app_colors.dart';
import '../../../core/theme.dart';
import '../../../shared/widgets/state_views.dart';
import '../providers/my_place_providers.dart';
import '../widgets/common/my_place_app_bar.dart';
import '../widgets/common/segmented_tabs.dart';
import '../widgets/insights/follow_up_timer_card.dart';
import '../widgets/insights/how_we_calculate_sheet.dart';
import '../widgets/insights/landlord_track_record_card.dart';
import '../widgets/insights/building_records_card.dart';
import '../widgets/insights/neighbor_posts_card.dart';
import '../widgets/insights/same_owner_card.dart';

/// 집주인 이력 · 이웃 말 · 공공기록 · 소유주를 한 화면에서 탭으로 본다
class BuildingInsightsPage extends ConsumerStatefulWidget {
  const BuildingInsightsPage({super.key});

  @override
  ConsumerState<BuildingInsightsPage> createState() =>
      _BuildingInsightsPageState();
}

class _BuildingInsightsPageState extends ConsumerState<BuildingInsightsPage> {
  static const _tabs = ['Landlord', 'Tenants', 'Records', 'Owner'];

  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            MyPlaceAppBar(
              title: 'Building Insights',
              onBack: () => context.pop(),
            ),
            Expanded(
              child: ListView(
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
                  const SizedBox(height: Gap.md),
                  switch (_tab) {
                    0 => const _LandlordTab(),
                    1 => const _TenantsTab(),
                    2 => const _RecordsTab(),
                    _ => const _OwnerTab(),
                  },
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LandlordTab extends ConsumerWidget {
  const _LandlordTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final insight = ref.watch(landlordInsightProvider);

    return insight.when(
      loading: () => const Padding(
        padding: EdgeInsets.only(top: Gap.xl),
        child: LoadingView(),
      ),
      error: (error, _) => AppErrorView(
        error: error,
        onRetry: () => ref.invalidate(landlordInsightProvider),
      ),
      data: (data) => Column(
        spacing: Gap.md,
        children: [
          LandlordTrackRecordCard(
            record: data.trackRecord,
            onInfoTap: () => HowWeCalculateSheet.show(context),
          ),
          FollowUpTimerCard(timer: data.followUpTimer),
          // 평가가 아니라는 고지 — 빼지 않는다
          const Padding(
            padding: EdgeInsets.only(top: Gap.sm),
            child: Text(
              'Not a landlord rating.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.chartNeutral,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TenantsTab extends ConsumerWidget {
  const _TenantsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summary = ref.watch(landlordPostSummaryProvider);

    return summary.when(
      loading: () => const Padding(
        padding: EdgeInsets.only(top: Gap.xl),
        child: LoadingView(),
      ),
      error: (error, _) => AppErrorView(
        error: error,
        onRetry: () => ref.invalidate(landlordPostSummaryProvider),
      ),
      data: (data) => NeighborPostsCard(
        summary: data,
        onViewAll: () => context.push('/my-place/insights/landlord-posts'),
        onGoToCommunity: () => context.push('/my-place/community'),
      ),
    );
  }
}

class _RecordsTab extends ConsumerWidget {
  const _RecordsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final records = ref.watch(recordsInsightProvider);

    return records.when(
      loading: () => const Padding(
        padding: EdgeInsets.only(top: Gap.xl),
        child: LoadingView(),
      ),
      error: (error, _) => AppErrorView(
        error: error,
        onRetry: () => ref.invalidate(recordsInsightProvider),
      ),
      data: (data) => BuildingRecordsCard(
        records: data,
        onHpdHistoryTap: () => context.push('/my-place/insights/hpd'),
      ),
    );
  }
}

class _OwnerTab extends ConsumerWidget {
  const _OwnerTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SameOwnerCard(
      portfolio: ref.watch(ownerPortfolioProvider),
      onOtherBuildingsTap: () =>
          context.push('/my-place/insights/owner-buildings'),
    );
  }
}
