import 'package:dwell/core/widgets/profile_avatar.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:material_ui/material_ui.dart';

import '../data/mock_cases.dart';
import '../models/case_filters.dart';
import '../models/case_model.dart';
import '../models/case_sort_order.dart';
import '../widgets/case_card.dart';
import '../widgets/case_filter_sheet.dart';
import '../widgets/case_filter_tabs.dart';
import '../widgets/case_search_field.dart';
import '../widgets/case_search_tabs.dart';
import '../widgets/case_sort_menu.dart';

class CasesPage extends StatefulWidget {
  const CasesPage({super.key});

  @override
  State<CasesPage> createState() => _CasesPageState();
}

class _CasesPageState extends State<CasesPage> {
  String _searchQuery = '';
  CaseStatus? _selectedStatus; // null = All
  CaseFilters _appliedFilters = CaseFilters();
  CaseSortOrder _selectedSortOrder = CaseSortOrder.newest;
  String? _selectedCaseId;
  List<CaseModel> get _matchingCases {
    final query = _searchQuery.trim().toLowerCase();

    return mockCases.where((item) {
      final matchesSearch =
          query.isEmpty || item.title.toLowerCase().startsWith(query);

      return matchesSearch && _appliedFilters.matches(item);
    }).toList();
  }

  Future<void> _openFilters() async {
    FocusManager.instance.primaryFocus?.unfocus();
    final colors = Theme.of(context).colorScheme;

    final result = await showModalBottomSheet<CaseFilters>(
      context: context,
      useRootNavigator: true,
      useSafeArea: true,
      isScrollControlled: true,
      showDragHandle: false,
      backgroundColor: colors.surface,
      clipBehavior: Clip.antiAlias,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return CaseFilterSheet(initialFilters: _appliedFilters);
      },
    );

    // 적용하지 않고 닫으면 기존 필터를 유지한다.
    if (!mounted || result == null) return;

    setState(() {
      _appliedFilters = result;
    });
  }

  void _removeFilter(CaseFilterGroup group, String value) {
    setState(() {
      _appliedFilters = _appliedFilters.remove(group, value);
    });
  }

  void _resetFilters() {
    setState(() {
      _appliedFilters = CaseFilters();
    });
  }

  String _emptyMessage(List<CaseModel> matchingCases) {
    if (matchingCases.isEmpty) return 'No cases found.';

    return switch (_selectedStatus) {
      CaseStatus.active => "You don't have any active cases.",
      CaseStatus.logged => "You don't have any logged cases.",
      CaseStatus.resolved => "You don't have any resolved cases.",
      null => 'No cases found.',
    };
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final isLight = colors.brightness == Brightness.light;
    final textColor = isLight ? const Color(0xFF243B53) : colors.onSurface;

    final topInset = MediaQuery.paddingOf(context).top;
    final headerTopPadding = (77.0 - topInset).clamp(0.0, 77.0).toDouble();

    // 탭 숫자는 검색·필터 결과로 계산한다.
    final matchingCases = _matchingCases;

    // 선택한 상태에 해당하는 목록을 복사한 후 생성일로 정렬한다.
    final visibleCases =
        matchingCases
            .where(
              (item) =>
                  _selectedStatus == null || item.status == _selectedStatus,
            )
            .toList()
          ..sort((a, b) {
            final comparison = switch (_selectedSortOrder) {
              CaseSortOrder.newest => b.createdAt.compareTo(a.createdAt),
              CaseSortOrder.oldest => a.createdAt.compareTo(b.createdAt),
            };

            // 생성일이 같아도 표시 순서를 일정하게 유지한다.
            return comparison != 0 ? comparison : a.id.compareTo(b.id);
          });

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // 헤더
            Padding(
              padding: EdgeInsets.fromLTRB(24, headerTopPadding, 24, 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Cases',
                    style: TextStyle(
                      color: textColor,
                      fontSize: 40,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -1.2,
                    ),
                  ),
                  const ProfileAvatar(nickname: 'SJ'),
                ],
              ),
            ),

            // 검색 및 필터 버튼
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(
                    child: CaseSearchField(
                      onChanged: (value) {
                        setState(() {
                          _searchQuery = value;
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 48,
                    height: 56,
                    child: IconButton(
                      tooltip: 'Filter Cases',
                      onPressed: _openFilters,
                      style: ButtonStyle(
                        backgroundColor: WidgetStateProperty.resolveWith<Color>(
                          (states) {
                            if (states.contains(WidgetState.pressed)) {
                              return isLight
                                  ? const Color(0xFFC0C6CC)
                                  : colors.surfaceContainerHigh;
                            }

                            return isLight
                                ? const Color(0xFFE4E8EC)
                                : colors.surfaceContainerHighest;
                          },
                        ),
                        foregroundColor: WidgetStatePropertyAll(textColor),
                        overlayColor: const WidgetStatePropertyAll(
                          Colors.transparent,
                        ),
                        shape: WidgetStatePropertyAll(
                          RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                      icon: Icon(
                        LucideIcons.funnel,
                        color: textColor,
                        size: 28,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // 상태 탭
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: CaseStatusTabs(
                cases: matchingCases,
                selectedStatus: _selectedStatus,
                onChanged: (status) {
                  setState(() {
                    _selectedStatus = status;
                  });
                },
              ),
            ),

            // 적용된 필터
            if (_appliedFilters.hasSelection)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: CaseFilterTags(
                  filters: _appliedFilters,
                  onRemove: _removeFilter,
                  onReset: _resetFilters,
                ),
              ),

            // 정렬 메뉴
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Align(
                alignment: Alignment.centerRight,
                child: CaseSortMenu(
                  selectedOrder: _selectedSortOrder,
                  onChanged: (order) {
                    setState(() {
                      _selectedSortOrder = order;
                    });
                  },
                ),
              ),
            ),

            // 카드 목록 또는 빈 상태
            Expanded(
              child: visibleCases.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(
                          _emptyMessage(matchingCases),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: colors.onSurfaceVariant,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    )
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          final cardWidth = (constraints.maxWidth - 16) / 3;

                          return Align(
                            alignment: Alignment.topLeft,
                            child: Wrap(
                              spacing: 8,
                              runSpacing: 16,
                              children: [
                                for (final item in visibleCases)
                                  SizedBox(
                                    width: cardWidth,
                                    child: CaseCard(
                                      key: ValueKey(item.id),
                                      caseItem: item,
                                      isSelected: _selectedCaseId == item.id,
                                      onTap: () {
                                        setState(() {
                                          _selectedCaseId = item.id;
                                        });
                                      },
                                    ),
                                  ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
