import 'package:dwell/core/widgets/primary_action_button.dart';
import 'package:material_ui/material_ui.dart';

import '../models/case_filters.dart';

class CaseFilterSheet extends StatefulWidget {
  final CaseFilters initialFilters;

  const CaseFilterSheet({super.key, required this.initialFilters});

  @override
  State<CaseFilterSheet> createState() => _CaseFilterSheetState();
}

class _CaseFilterSheetState extends State<CaseFilterSheet> {
  late CaseFilters _draftFilters;

  @override
  void initState() {
    super.initState();
    _draftFilters = widget.initialFilters;
  }

  bool get _canApply => !_draftFilters.sameAs(widget.initialFilters);

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final isLight = colors.brightness == Brightness.light;
    final textColor = isLight ? const Color(0xFF243B53) : colors.onSurface;

    return SizedBox(
      height: MediaQuery.sizeOf(context).height * 0.74,
      child: SafeArea(
        top: false,
        child: Column(
          children: [
            // 상단 바
            Padding(
              padding: const EdgeInsets.only(top: 16, bottom: 12),
              child: Center(
                child: Container(
                  width: 64,
                  height: 6,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE5E5E5),
                    borderRadius: BorderRadius.circular(100),
                  ),
                ),
              ),
            ),

            // 제목 및 Reset 버튼
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 16, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Filter Case',
                      style: TextStyle(
                        color: textColor,
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: _draftFilters.hasSelection
                        ? () {
                            setState(() {
                              _draftFilters = CaseFilters();
                            });
                          }
                        : null,
                    style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFF007AFF),
                      disabledForegroundColor: const Color(0xFF667685),
                      textStyle: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    child: const Text('Reset'),
                  ),
                ],
              ),
            ),

            // 필터 선택 영역
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (final group in CaseFilterGroup.values)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              group.label,
                              style: TextStyle(
                                color: textColor,
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                for (final value
                                    in CaseFilterOptions.values[group]!)
                                  _FilterOption(
                                    label: value,
                                    selected: _draftFilters
                                        .selectedFor(group)
                                        .contains(value),
                                    onTap: () {
                                      setState(() {
                                        _draftFilters = _draftFilters.toggle(
                                          group,
                                          value,
                                        );
                                      });
                                    },
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),

            // 적용 버튼
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              child: PrimaryActionButton(
                label: 'Apply Filters',
                enabled: _canApply,
                onPressed: () {
                  Navigator.of(context).pop(_draftFilters);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 선택 여부는 시트에서 전달받는다.
class _FilterOption extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterOption({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final isLight = colors.brightness == Brightness.light;

    final background = selected
        ? const Color(0xFF243B53)
        : isLight
        ? const Color(0xFFD3D9DF)
        : colors.surfaceContainerHighest;

    final foreground = selected
        ? Colors.white
        : isLight
        ? const Color(0xFF243B53)
        : colors.onSurface;

    return Semantics(
      button: true,
      selected: selected,
      child: Material(
        color: background,
        borderRadius: BorderRadius.circular(4),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(4),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: Text(
              label,
              style: TextStyle(
                color: foreground,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
