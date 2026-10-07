import 'package:dwell/core/widgets/profile_avatar.dart';
import 'package:material_ui/material_ui.dart';

import '../data/mock_cases.dart';
import '../models/case_filters.dart';
import '../models/case_model.dart';
import '../widgets/case_card.dart';
import '../widgets/case_filter_sheet.dart';
import '../widgets/case_filter_tabs.dart';
import '../widgets/case_search_field.dart';
import '../widgets/case_search_tabs.dart';

class ReportsPage extends StatefulWidget {
  const ReportsPage({super.key});

  @override
  State<ReportsPage> createState() => _ReportsPageState();
}

class _ReportsPageState extends State<ReportsPage> {
  String _searchQuery = '';
  CaseStatus? _selectedStatus; // null = All
  CaseFilters _appliedFilters = CaseFilters();

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
      showDragHandle: true,
      backgroundColor: colors.surface,
      clipBehavior: Clip.antiAlias,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return CaseFilterSheet(initialFilters: _appliedFilters);
      },
    );

    // 바깥 탭, 뒤로 가기, 아래로 드래그하면 null. 적용값을 변경하지 않는다.
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
    // 카드 목록만 선택한 상태 탭으로 제한한다.
    final visibleCases = _selectedStatus == null
        ? matchingCases
        : matchingCases
              .where((item) => item.status == _selectedStatus)
              .toList();

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
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
                      fontWeight: FontWeight.w700,
                      letterSpacing: -1.2,
                    ),
                  ),
                  const ProfileAvatar(nickname: 'SJ'),
                ],
              ),
            ),
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
                    child: Material(
                      color: isLight
                          ? const Color(0xFFC4CCD3)
                          : colors.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(10),
                      clipBehavior: Clip.antiAlias,
                      child: IconButton(
                        tooltip: 'Filter Cases',
                        onPressed: _openFilters,
                        icon: Icon(
                          Icons.filter_alt_outlined,
                          color: textColor,
                          size: 28,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
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
            if (_appliedFilters.hasSelection)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: CaseFilterTags(
                  filters: _appliedFilters,
                  onRemove: _removeFilter,
                  onReset: _resetFilters,
                ),
              ),
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
