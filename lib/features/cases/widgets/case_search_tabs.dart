import 'package:material_ui/material_ui.dart';

import '../models/case_model.dart';

class CaseStatusTabs extends StatelessWidget {
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

    const duration = Duration(milliseconds: 220);
    const curve = Curves.easeInOut;
    const underlineWidth = 3.0;
    const underlineGap = 1.0;
    const verticalPadding = 10.0;

    final tabs = <({String label, CaseStatus? status})>[
      (label: 'Active', status: CaseStatus.active),
      (label: 'Logged', status: CaseStatus.logged),
      (label: 'Resolved', status: CaseStatus.resolved),
      (label: 'All', status: null),
    ];

    final labels = [
      for (final tab in tabs)
        '${tab.label}(${tab.status == null ? cases.length : cases.where((item) => item.status == tab.status).length})',
    ];

    final baseStyle = DefaultTextStyle.of(context).style
        .merge(const TextStyle(fontSize: 16));

    final styles = [
      for (final tab in tabs)
        baseStyle.copyWith(
          color: selectedStatus == tab.status
              ? selectedColor
              : const Color(0xFF667685),
          fontWeight: selectedStatus == tab.status
              ? FontWeight.w800
              : FontWeight.w500,
        ),
    ];

    // 밑줄이 이동할 목적지와 글씨 너비를 계산한다.
    final labelWidths = <double>[];

    for (var index = 0; index < tabs.length; index++) {
      final painter = TextPainter(
        text: TextSpan(text: labels[index], style: styles[index]),
        textDirection: Directionality.of(context),
        textScaler: MediaQuery.textScalerOf(context),
        locale: Localizations.maybeLocaleOf(context),
        maxLines: 1,
      )..layout();

      labelWidths.add(painter.width);
      painter.dispose();
    }

    final selectedIndex = tabs.indexWhere(
      (tab) => tab.status == selectedStatus,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final totalWidth = labelWidths.fold<double>(
          0,
          (sum, width) => sum + width,
        );

        final needsScroll = totalWidth > constraints.maxWidth;
        final contentWidth = needsScroll ? totalWidth : constraints.maxWidth;
        final gap = ((contentWidth - totalWidth) / 3)
            .clamp(0.0, double.infinity)
            .toDouble();

        final beforeWidth = labelWidths
            .take(selectedIndex)
            .fold<double>(0, (sum, width) => sum + width);

        final isRtl = Directionality.of(context) == TextDirection.rtl;
        final leadingOffset = beforeWidth + gap * selectedIndex;
        final indicatorLeft = isRtl
            ? contentWidth - leadingOffset - labelWidths[selectedIndex]
            : leadingOffset;

        final tabContent = SizedBox(
          width: contentWidth,
          child: Stack(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  for (var index = 0; index < tabs.length; index++)
                    Semantics(
                      button: true,
                      selected: selectedStatus == tabs[index].status,
                      child: InkWell(
                        onTap: () => onChanged(tabs[index].status),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            vertical: verticalPadding,
                          ),
                          child: Padding(
                            padding: const EdgeInsets.only(
                              bottom: underlineGap + underlineWidth,
                            ),
                            child: AnimatedDefaultTextStyle(
                              duration: duration,
                              curve: curve,
                              style: styles[index],
                              child: Text(
                                labels[index],
                                maxLines: 1,
                                softWrap: false,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),

              // 밑줄 하나가 선택한 탭 아래로 이동한다.
              AnimatedPositioned(
                duration: duration,
                curve: curve,
                left: indicatorLeft,
                bottom: verticalPadding,
                width: labelWidths[selectedIndex],
                height: underlineWidth,
                child: IgnorePointer(child: ColoredBox(color: selectedColor)),
              ),
            ],
          ),
        );
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: needsScroll ? null : const NeverScrollableScrollPhysics(),
          child: tabContent,
        );
      },
    );
  }
}
