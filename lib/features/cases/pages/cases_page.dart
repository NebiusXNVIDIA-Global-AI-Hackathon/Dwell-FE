import 'dart:math' as math;

import 'package:dwell/core/widgets/app_screen_header.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/reports_cases_provider.dart';
import '../models/reports_case_query.dart';
import '../models/case_filters.dart';
import '../models/case_model.dart';
import '../models/case_sort_order.dart';
import '../models/reports_creation_notice.dart';
import '../widgets/list/case_creation_toast.dart';
import '../widgets/list/case_card.dart';
import '../widgets/list/case_filter_sheet.dart';
import '../widgets/list/case_filter_tabs.dart';
import '../widgets/list/case_search_field.dart';
import '../widgets/list/case_search_tabs.dart';
import '../widgets/list/case_sort_menu.dart';
import '../../case_detail/models/case_deletion_notice.dart';
import '../../case_detail/presentation/case_detail_routes.dart';
import '../../case_detail/presentation/case_detail_tokens.dart';
import '../../case_detail/presentation/widgets/case_deleted_toast.dart';

import 'package:go_router/go_router.dart';

class CasesPage extends ConsumerStatefulWidget {
  const CasesPage({super.key, this.creationNotice, this.deletionNotice});
  final ReportsCreationNotice? creationNotice;
  final CaseDeletionNotice? deletionNotice;

  @override
  ConsumerState<CasesPage> createState() => _CasesPageState();
}

class _CasesPageState extends ConsumerState<CasesPage> {
  String _searchQuery = '';
  CaseStatus? _selectedStatus; // null = All
  CaseFilters _appliedFilters = CaseFilters();
  CaseSortOrder _selectedSortOrder = CaseSortOrder.newest;
  String? _selectedCaseId;
  ReportsCreationNotice? _toastNotice;
  CaseDeletionNotice? _deletionToast;
  GoRouter? _router;

  void _acceptNotice() {
    final notice = widget.creationNotice;
    if (notice != null && notice.consume()) {
      _selectedStatus = CaseStatus.logged;
      _toastNotice = notice;
    }
  }

  // Show the toast once after a case is deleted
  void _acceptDeletion() {
    final notice = widget.deletionNotice;
    if (notice != null && notice.consume()) _deletionToast = notice;
  }

  @override
  void initState() {
    super.initState();
    _acceptNotice();
    _acceptDeletion();
  }

  @override
  void didUpdateWidget(covariant CasesPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.creationNotice != widget.creationNotice) {
      _toastNotice = null;
      _acceptNotice();
    }
    if (oldWidget.deletionNotice != widget.deletionNotice) {
      _acceptDeletion();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final router = GoRouter.maybeOf(context);
    if (_router != router) {
      _router?.routerDelegate.removeListener(_routeChanged);
      _router = router;
      _router?.routerDelegate.addListener(_routeChanged);
    }
  }

  void _routeChanged() {
    if (mounted && _toastNotice != null && _router?.state.name != 'cases') {
      setState(() => _toastNotice = null);
    }
  }

  double _toastTop(BuildContext context, BoxConstraints constraints) {
    final width = math.min(260.0, math.max(1.0, constraints.maxWidth - 32));
    final painter = TextPainter(
      text: TextSpan(
        text: _toastNotice?.message ?? '',
        style: const TextStyle(
          fontFamily: 'Pretendard Variable',
          fontSize: 16,
          fontWeight: FontWeight.w500,
          height: 1.25,
        ),
      ),
      textDirection: Directionality.of(context),
      textScaler: MediaQuery.textScalerOf(context),
    )..layout(maxWidth: math.max(1, width - 68));
    final height = math.max(20.0, painter.height) + 26;
    painter.dispose();
    // Float 8px inside the grid's 16px padding; move upward on short screens
    // to reserve the New Case button and its shadow without shrinking text.
    return math.min(24, constraints.maxHeight - 82 - height);
  }

  @override
  void dispose() {
    _router?.routerDelegate.removeListener(_routeChanged);
    super.dispose();
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

    // 탭 숫자는 검색·필터 결과로 계산한다.
    final state = ref.watch(reportsCasesProvider);
    final matchingCases = matchingReportsCases(
      state.asData?.value ?? const [],
      search: _searchQuery,
      filters: _appliedFilters,
    );

    // 선택한 상태에 해당하는 목록을 복사한 후 생성일로 정렬한다.
    final visibleCases = visibleReportsCases(
      matchingCases,
      status: _selectedStatus,
      sort: _selectedSortOrder,
    );

    return Scaffold(
      floatingActionButton: SizedBox(
        height: 45,
        child: ElevatedButton(
          onPressed: () {
            context.pushNamed('case-creation');
          },
          style: ButtonStyle(
            backgroundColor: WidgetStateProperty.resolveWith<Color>((states) {
              if (states.contains(WidgetState.pressed)) {
                return const Color(0xFF506275);
              }

              return const Color(0xFF243B53);
            }),
            foregroundColor: const WidgetStatePropertyAll(Colors.white),
            overlayColor: const WidgetStatePropertyAll(Colors.transparent),
            surfaceTintColor: const WidgetStatePropertyAll(Colors.transparent),
            shadowColor: const WidgetStatePropertyAll(Colors.black),
            elevation: WidgetStateProperty.resolveWith<double>((states) {
              if (states.contains(WidgetState.pressed) ||
                  states.contains(WidgetState.hovered)) {
                return 8;
              }

              return 6;
            }),
            shape: const WidgetStatePropertyAll(StadiumBorder()),
            padding: const WidgetStatePropertyAll(
              EdgeInsets.symmetric(horizontal: 10),
            ),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(LucideIcons.plus, size: 26),
              SizedBox(width: 2),
              Text(
                'New Case',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      body: Padding(
        padding: EdgeInsets.only(top: AppScreenHeader.systemTopInset(context)),
        child: SafeArea(
          top: false,
          child: Column(
            children: [
              // 헤더
              AppScreenHeader(
                title: Text(
                  'Cases',
                  style: TextStyle(
                    color: textColor,
                    fontSize: 40,
                    height: 1.2,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(height: 16),

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
                          fixedSize: const WidgetStatePropertyAll(Size(48, 56)),
                          visualDensity: VisualDensity.standard,
                          backgroundColor:
                              WidgetStateProperty.resolveWith<Color>((states) {
                                if (states.contains(WidgetState.pressed)) {
                                  return isLight
                                      ? const Color(0xFFC0C6CC)
                                      : colors.surfaceContainerHigh;
                                }

                                return isLight
                                    ? const Color(0xFFE4E8EC)
                                    : colors.surfaceContainerHighest;
                              }),
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
                      if (_selectedStatus != status) _toastNotice = null;
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
                child: LayoutBuilder(
                  builder: (context, constraints) => Stack(
                    fit: StackFit.expand,
                    clipBehavior: Clip.none,
                    children: [
                      state.isLoading
                          ? const Center(child: CircularProgressIndicator())
                          : state.hasError
                          ? Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Text('Unable to load cases.'),
                                  TextButton(
                                    onPressed: () =>
                                        ref.invalidate(reportsCasesProvider),
                                    child: const Text('Retry'),
                                  ),
                                ],
                              ),
                            )
                          : visibleCases.isEmpty
                          ? Align(
                              alignment: const Alignment(0, -0.2),
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
                                  final columns =
                                      (constraints.maxWidth - 16) / 3 < 114
                                      ? 2
                                      : 3;
                                  final cardWidth =
                                      (constraints.maxWidth -
                                          8 * (columns - 1)) /
                                      columns;

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
                                              isSelected:
                                                  _selectedCaseId == item.id,
                                              onTap: () {
                                                setState(() {
                                                  _selectedCaseId = item.id;
                                                });
                                                // Open Case Detail
                                                _router?.pushNamed(
                                                  CaseDetailRoutes.detail,
                                                  pathParameters:
                                                      CaseDetailRoutes.params(
                                                        item.id,
                                                      ),
                                                );
                                              },
                                            ),
                                          ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ),
                      if (_toastNotice case final notice?)
                        Positioned(
                          top: _toastTop(context, constraints),
                          left: 16,
                          right: 16,
                          child: Align(
                            alignment: Alignment.topCenter,
                            child: CaseCreationToast(
                              key: ObjectKey(notice),
                              message: notice.message,
                              onDismissed: () {
                                if (mounted && _toastNotice == notice) {
                                  setState(() => _toastNotice = null);
                                }
                              },
                            ),
                          ),
                        ),
                      if (_deletionToast case final notice?)
                        Positioned(
                          top: CaseDetailSizes.toastTop,
                          left: 16,
                          right: 16,
                          child: Align(
                            alignment: Alignment.topCenter,
                            child: CaseDeletedToast(
                              key: ObjectKey(notice),
                              message: notice.message,
                              onDismissed: () {
                                if (mounted && _deletionToast == notice) {
                                  setState(() => _deletionToast = null);
                                }
                              },
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
