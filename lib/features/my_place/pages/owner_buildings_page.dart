import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/app_colors.dart';
import '../../../core/theme.dart';
import '../models/owner_portfolio.dart';
import '../providers/my_place_providers.dart';
import '../widgets/common/my_place_app_bar.dart';
import '../widgets/common/my_place_sort_menu.dart';
import '../widgets/insights/insights_card.dart';
import '../widgets/insights/owner_building_card.dart';
import '../widgets/insights/stat_tile.dart';

/// 정렬 기준 — 와프에는 기본값만 있다
enum OwnerBuildingSort {
  mostOpen('Most open'),
  fewestOpen('Fewest open');

  const OwnerBuildingSort(this.label);

  final String label;
}

/// 같은 소유주가 가진 건물 목록
class OwnerBuildingsPage extends ConsumerStatefulWidget {
  const OwnerBuildingsPage({super.key});

  @override
  ConsumerState<OwnerBuildingsPage> createState() => _OwnerBuildingsPageState();
}

class _OwnerBuildingsPageState extends ConsumerState<OwnerBuildingsPage> {
  OwnerBuildingSort _sort = OwnerBuildingSort.mostOpen;

  @override
  Widget build(BuildContext context) {
    final portfolio = ref.watch(ownerPortfolioProvider);
    final buildings = _sorted(portfolio.buildings);

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            MyPlaceAppBar(
              title: 'Same owner',
              subtitle:
                  'HPD registration · ${portfolio.buildingCount} buildings',
              onBack: () => context.pop(),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(
                  Gap.screenH,
                  Gap.xs,
                  Gap.screenH,
                  Gap.xl,
                ),
                children: [
                  IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      spacing: 10,
                      children: [
                        Expanded(
                          child: StatTile(
                            value: '${portfolio.buildingCount}',
                            label: 'Buildings',
                            valueSize: 20,
                          ),
                        ),
                        Expanded(
                          child: StatTile(
                            value: '${portfolio.open}',
                            valueColor: AppColors.chartDanger,
                            label: 'Open',
                            valueSize: 20,
                          ),
                        ),
                        Expanded(
                          child: StatTile(
                            value: '${portfolio.closed}',
                            valueColor: AppColors.textSubtle,
                            label: 'Closed',
                            valueSize: 20,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: Gap.card),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      MyPlaceSortMenu<OwnerBuildingSort>(
                        value: _sort,
                        options: OwnerBuildingSort.values,
                        labelOf: (option) => option.label,
                        onSelected: (option) => setState(() => _sort = option),
                      ),
                    ],
                  ),
                  const SizedBox(height: Gap.card),
                  for (final building in buildings)
                    Padding(
                      padding: const EdgeInsets.only(bottom: Gap.card),
                      child: OwnerBuildingCard(building: building),
                    ),
                  const SourceLabel(
                    text: 'Source: HPD building registration & violations',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<OwnerBuilding> _sorted(List<OwnerBuilding> buildings) {
    final sorted = [...buildings];
    sorted.sort(
      (a, b) => _sort == OwnerBuildingSort.mostOpen
          ? b.open.compareTo(a.open)
          : a.open.compareTo(b.open),
    );
    return sorted;
  }
}
