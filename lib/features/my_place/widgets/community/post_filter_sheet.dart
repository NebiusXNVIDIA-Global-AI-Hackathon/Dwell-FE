import 'package:material_ui/material_ui.dart';

import '../../../../core/app_colors.dart';
import '../../../../core/theme.dart';
import '../../models/issue_category.dart';
import '../../models/landlord_post_query.dart';
import '../../models/neighbor_post.dart';

/// 집주인 언급 글 필터 — 적용을 누르기 전까지는 임시 선택만 들고 있는다
class PostFilterSheet extends StatefulWidget {
  const PostFilterSheet({super.key, required this.query});

  final LandlordPostQuery query;

  static Future<LandlordPostQuery?> show(
    BuildContext context,
    LandlordPostQuery query,
  ) {
    return showModalBottomSheet<LandlordPostQuery>(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: AppColors.scrim,
      isScrollControlled: true,
      useRootNavigator: true,
      builder: (context) => PostFilterSheet(query: query),
    );
  }

  @override
  State<PostFilterSheet> createState() => _PostFilterSheetState();
}

class _PostFilterSheetState extends State<PostFilterSheet> {
  late Set<PostTopic> _topics = {...widget.query.topics};
  late Set<IssueCategory> _issueTypes = {...widget.query.issueTypes};
  late Set<PostFloorBand> _floors = {...widget.query.floorBands};
  late PostedWindow? _posted = widget.query.posted;

  /// 와프에 있는 네 가지만 — 전체 카테고리를 늘어놓지 않는다
  static const _issueOptions = [
    IssueCategory.waterFlooding,
    IssueCategory.heatHotWater,
    IssueCategory.pests,
    IssueCategory.moldMoisture,
  ];

  static const _issueLabels = {
    IssueCategory.waterFlooding: 'Water leak',
    IssueCategory.heatHotWater: 'Heat',
    IssueCategory.pests: 'Pests',
    IssueCategory.moldMoisture: 'Mold',
  };

  bool get _hasSelection =>
      _topics.isNotEmpty ||
      _issueTypes.isNotEmpty ||
      _floors.isNotEmpty ||
      _posted != null;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(Gap.screenH)),
      ),
      padding: const EdgeInsets.fromLTRB(Gap.lg, 14, Gap.lg, 30),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 14,
          children: [
            Center(
              child: Container(
                width: 67,
                height: 6,
                decoration: BoxDecoration(
                  color: AppColors.divider,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Filter Posts',
                    style: TextStyle(
                      color: AppColors.textTitle,
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                // 선택만 비우고 시트는 닫지 않는다
                GestureDetector(
                  onTap: () => setState(() {
                    _topics = {};
                    _issueTypes = {};
                    _floors = {};
                    _posted = null;
                  }),
                  behavior: HitTestBehavior.opaque,
                  child: const Text(
                    'Reset',
                    style: TextStyle(
                      color: AppColors.link,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const _GroupLabel('Topic'),
            _ChipGroup(
              children: [
                for (final topic in PostTopic.values)
                  _FilterChip(
                    label: topic.label,
                    selected: _topics.contains(topic),
                    onTap: () => setState(() => _toggle(_topics, topic)),
                  ),
              ],
            ),
            const _GroupLabel('Issue type'),
            _ChipGroup(
              children: [
                for (final category in _issueOptions)
                  _FilterChip(
                    label: _issueLabels[category]!,
                    selected: _issueTypes.contains(category),
                    onTap: () => setState(() => _toggle(_issueTypes, category)),
                  ),
              ],
            ),
            const _GroupLabel('Floor'),
            _ChipGroup(
              children: [
                for (final band in PostFloorBand.values)
                  _FilterChip(
                    label: band.label,
                    selected: _floors.contains(band),
                    onTap: () => setState(() => _toggle(_floors, band)),
                  ),
              ],
            ),
            const _GroupLabel('Posted'),
            _ChipGroup(
              children: [
                for (final window in PostedWindow.values)
                  _FilterChip(
                    label: window.label,
                    selected: _posted == window,
                    onTap: () => setState(
                      () => _posted = _posted == window ? null : window,
                    ),
                  ),
              ],
            ),
            SizedBox(
              width: double.infinity,
              child: Material(
                color: _hasSelection
                    ? AppColors.applyAction
                    : AppColors.divider,
                borderRadius: BorderRadius.circular(Gap.sm),
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: _hasSelection ? _apply : null,
                  child: Container(
                    constraints: const BoxConstraints(minHeight: 48),
                    alignment: Alignment.center,
                    child: Text(
                      'Apply Filters',
                      style: TextStyle(
                        color: _hasSelection
                            ? AppColors.surface
                            : AppColors.textMuted,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _toggle<T>(Set<T> target, T value) {
    if (!target.remove(value)) target.add(value);
  }

  void _apply() {
    Navigator.of(context).pop(
      widget.query.copyWith(
        topics: _topics,
        issueTypes: _issueTypes,
        floorBands: _floors,
        posted: _posted,
        clearPosted: _posted == null,
        page: 0,
      ),
    );
  }
}

class _GroupLabel extends StatelessWidget {
  const _GroupLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Text(
    text,
    style: const TextStyle(
      color: AppColors.textTitle,
      fontSize: 16,
      fontWeight: FontWeight.w700,
    ),
  );
}

class _ChipGroup extends StatelessWidget {
  const _ChipGroup({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) =>
      Wrap(spacing: Gap.sm, runSpacing: Gap.sm, children: children);
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.textTitle : AppColors.filterChip,
      borderRadius: BorderRadius.circular(Gap.xs),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: Gap.md, vertical: 7),
          child: Text(
            label,
            style: TextStyle(
              color: selected ? AppColors.surface : AppColors.textTitle,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}
