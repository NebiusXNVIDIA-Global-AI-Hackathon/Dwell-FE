import 'package:material_ui/material_ui.dart';

import '../models/case_model.dart';

class CaseStatusTabs extends StatelessWidget {
  /// 검색·필터를 통과한 목록. 선택한 상태 탭으로 제한하기 전의 데이터.
  final List<CaseModel> cases;
  final CaseStatus? selectedStatus;
  final ValueChanged<CaseStatus?> onChanged;

  const CaseStatusTabs({
    super.key,
    required this.cases,
    required this.selectedStatus,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final selectedColor = colors.brightness == Brightness.light
        ? const Color(0xFF243B53)
        : colors.onSurface;
    final tabs = <({String label, CaseStatus? status})>[
      (label: 'Active', status: CaseStatus.active),
      (label: 'Logged', status: CaseStatus.logged),
      (label: 'Resolved', status: CaseStatus.resolved),
      (label: 'All', status: null),
    ];

    return Row(
      children: [
        for (final tab in tabs)
          Expanded(
            child: Builder(
              builder: (context) {
                final selected = selectedStatus == tab.status;
                final count = tab.status == null
                    ? cases.length
                    : cases.where((item) => item.status == tab.status).length;

                return Semantics(
                  button: true,
                  selected: selected,
                  child: InkWell(
                    onTap: () => onChanged(tab.status),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      child: Align(
                        child: Container(
                          padding: const EdgeInsets.only(bottom: 4),
                          decoration: BoxDecoration(
                            border: Border(
                              bottom: BorderSide(
                                color: selected
                                    ? selectedColor
                                    : Colors.transparent,
                                width: 2,
                              ),
                            ),
                          ),
                          child: Text(
                            tab.label + '(' + count.toString() + ')',
                            maxLines: 1,
                            style: TextStyle(
                              color: selected
                                  ? selectedColor
                                  : colors.onSurfaceVariant,
                              fontSize: 14,
                              fontWeight: selected
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }
}
