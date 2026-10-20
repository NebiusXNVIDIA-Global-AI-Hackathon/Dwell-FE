import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/app_colors.dart';
import '../../../core/theme.dart';
import '../../../shared/widgets/state_views.dart';
import '../data/building_signals_mock.dart';
import '../models/issue_category.dart';
import '../models/landlord_post_query.dart';
import '../models/neighbor_post.dart';
import '../providers/my_place_providers.dart';
import '../widgets/common/my_place_app_bar.dart';
import '../widgets/common/my_place_search_field.dart';
import '../widgets/common/my_place_sort_menu.dart';
import '../widgets/common/underline_tabs.dart';
import '../widgets/community/neighbor_post_card.dart';
import '../widgets/community/post_filter_sheet.dart';

/// 집주인을 언급한 이웃 글 전체 — 주제 탭 · 검색 · 정렬 · 필터
class LandlordPostsPage extends ConsumerStatefulWidget {
  const LandlordPostsPage({super.key});

  @override
  ConsumerState<LandlordPostsPage> createState() => _LandlordPostsPageState();
}

class _LandlordPostsPageState extends ConsumerState<LandlordPostsPage> {
  final _searchController = TextEditingController();

  LandlordPostQuery _query = const LandlordPostQuery();

  /// 탭은 따로 들고 있지 않는다 — 고른 주제가 곧 탭이다
  int get _tab => _query.topics.length == 1
      ? PostTopic.values.indexOf(_query.topics.first) + 1
      : 0;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final all = ref.watch(landlordPostsProvider);
    final page = ref.watch(landlordPostPageProvider(_query));

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            MyPlaceAppBar(
              title: 'Posts about landlord',
              subtitle: '$demoBuildingAddressShort · from Neighbor Community',
              onBack: () => context.pop(),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                Gap.screenH,
                Gap.card,
                Gap.screenH,
                Gap.md,
              ),
              child: Row(
                spacing: Gap.card,
                children: [
                  Expanded(
                    child: MyPlaceSearchField(
                      hintText: 'Search posts',
                      controller: _searchController,
                      onChanged: (value) => setState(
                        () => _query = _query.copyWith(query: value, page: 0),
                      ),
                    ),
                  ),
                  _FilterButton(onTap: _openFilters),
                ],
              ),
            ),
            UnderlineTabs(
              labels: _tabLabels(all),
              selected: _tab,
              onSelected: _selectTab,
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                Gap.screenH,
                Gap.card,
                Gap.screenH,
                Gap.sm,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  MyPlaceSortMenu<PostSort>(
                    value: _query.sort,
                    options: PostSort.values,
                    labelOf: (option) => option.label,
                    onSelected: (option) => setState(
                      () => _query = _query.copyWith(sort: option, page: 0),
                    ),
                  ),
                ],
              ),
            ),
            if (_query.hasRefinements)
              _AppliedFilters(query: _query, onChanged: _setQuery),
            Expanded(
              child: page.when(
                loading: () => const LoadingView(),
                error: (error, _) => AppErrorView(
                  error: error,
                  onRetry: () =>
                      ref.invalidate(landlordPostPageProvider(_query)),
                ),
                data: (data) => data.content.isEmpty
                    ? const EmptyView(message: 'No posts match these filters')
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(
                          Gap.screenH,
                          Gap.sm,
                          Gap.screenH,
                          Gap.xl,
                        ),
                        itemCount: data.content.length,
                        separatorBuilder: (context, index) =>
                            const SizedBox(height: 10),
                        itemBuilder: (context, index) => NeighborPostCard(
                          post: data.content[index],
                          showTopic: true,
                          showDate: true,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 탭 숫자는 필터 전 전체 기준이다
  List<String> _tabLabels(List<NeighborPost> posts) {
    final counts = {for (final topic in PostTopic.values) topic: 0};
    for (final post in posts) {
      final topic = post.landlordTopic;
      if (topic != null) counts[topic] = counts[topic]! + 1;
    }

    return [
      'All(${posts.length})',
      for (final topic in PostTopic.values) '${topic.label}(${counts[topic]})',
    ];
  }

  void _selectTab(int index) {
    setState(() {
      _query = _query.copyWith(
        topics: index == 0 ? const {} : {PostTopic.values[index - 1]},
        page: 0,
      );
    });
  }

  void _setQuery(LandlordPostQuery query) => setState(() => _query = query);

  Future<void> _openFilters() async {
    final applied = await PostFilterSheet.show(context, _query);
    if (applied == null || !mounted) return;
    setState(() => _query = applied);
  }
}

class _FilterButton extends StatelessWidget {
  const _FilterButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.systemPill,
      borderRadius: BorderRadius.circular(10),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          width: 52,
          height: 52,
          alignment: Alignment.center,
          child: const Icon(
            LucideIcons.funnel,
            size: 22,
            color: AppColors.textTitle,
          ),
        ),
      ),
    );
  }
}

/// 적용된 조건을 칩으로 보여주고 하나씩 뗄 수 있게 한다
class _AppliedFilters extends StatelessWidget {
  const _AppliedFilters({required this.query, required this.onChanged});

  final LandlordPostQuery query;
  final ValueChanged<LandlordPostQuery> onChanged;

  static const _issueLabels = {
    IssueCategory.waterFlooding: 'Water leak',
    IssueCategory.heatHotWater: 'Heat',
    IssueCategory.pests: 'Pests',
    IssueCategory.moldMoisture: 'Mold',
  };

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(Gap.screenH, 0, Gap.screenH, Gap.sm),
      child: Row(
        children: [
          Expanded(
            child: Wrap(
              spacing: Gap.sm,
              runSpacing: Gap.sm,
              children: [
                if (query.topics.length > 1)
                  for (final topic in query.topics)
                    _AppliedChip(
                      label: topic.label,
                      onRemove: () => onChanged(
                        query.copyWith(
                          topics: {...query.topics}..remove(topic),
                        ),
                      ),
                    ),
                for (final category in query.issueTypes)
                  _AppliedChip(
                    label: _issueLabels[category] ?? category.label,
                    onRemove: () => onChanged(
                      query.copyWith(
                        issueTypes: {...query.issueTypes}..remove(category),
                      ),
                    ),
                  ),
                for (final band in query.floorBands)
                  _AppliedChip(
                    label: band.label,
                    onRemove: () => onChanged(
                      query.copyWith(
                        floorBands: {...query.floorBands}..remove(band),
                      ),
                    ),
                  ),
                if (query.posted != null)
                  _AppliedChip(
                    label: query.posted!.label,
                    onRemove: () =>
                        onChanged(query.copyWith(clearPosted: true)),
                  ),
              ],
            ),
          ),
          const SizedBox(width: Gap.sm),
          GestureDetector(
            onTap: () => onChanged(
              query.copyWith(
                issueTypes: const {},
                floorBands: const {},
                clearPosted: true,
                page: 0,
              ),
            ),
            behavior: HitTestBehavior.opaque,
            child: const Text(
              'Reset',
              style: TextStyle(
                color: AppColors.link,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AppliedChip extends StatelessWidget {
  const _AppliedChip({required this.label, required this.onRemove});

  final String label;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onRemove,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: Gap.xs),
        decoration: BoxDecoration(
          color: AppColors.chartTrack,
          borderRadius: BorderRadius.circular(100),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          spacing: 6,
          children: [
            Text(
              label,
              style: const TextStyle(
                color: AppColors.textTitle,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            const Icon(LucideIcons.x, size: 12, color: AppColors.textSubtle),
          ],
        ),
      ),
    );
  }
}
