import 'package:flutter/gestures.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../core/app_colors.dart';
import '../../../../core/theme.dart';

/// 밑줄 탭 — 커뮤니티 3탭 · 집주인 언급 글 4탭
class UnderlineTabs extends StatelessWidget {
  const UnderlineTabs({
    super.key,
    required this.labels,
    required this.selected,
    required this.onSelected,
    this.fontSize = 13,
    this.showBaseline = false,
  });

  final List<String> labels;
  final int selected;
  final ValueChanged<int> onSelected;
  final double fontSize;

  /// 탭 아래로 화면을 가로지르는 회색 선 — 커뮤니티만 쓴다
  final bool showBaseline;

  @override
  Widget build(BuildContext context) {
    // 탭이 많으면 390 폭을 넘는다 — 웹 마우스 드래그까지 열어 둔다
    final tabs = ScrollConfiguration(
      behavior: ScrollConfiguration.of(context).copyWith(
        dragDevices: {
          PointerDeviceKind.touch,
          PointerDeviceKind.mouse,
          PointerDeviceKind.stylus,
          PointerDeviceKind.invertedStylus,
          PointerDeviceKind.trackpad,
        },
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: Gap.screenH),
        child: Row(
          spacing: Gap.md,
          children: [
            for (var i = 0; i < labels.length; i++)
              _Tab(
                label: labels[i],
                selected: i == selected,
                fontSize: fontSize,
                onTap: () => onSelected(i),
              ),
          ],
        ),
      ),
    );

    if (!showBaseline) return tabs;

    // 바탕선은 화면을 가로지르고, 탭은 왼쪽에서 시작한다
    return Stack(
      alignment: Alignment.bottomLeft,
      children: [
        Container(height: 3, color: AppColors.divider),
        tabs,
      ],
    );
  }
}

class _Tab extends StatelessWidget {
  const _Tab({
    required this.label,
    required this.selected,
    required this.fontSize,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final double fontSize;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        // 밑줄이 글자 폭을 따라간다 — 가로 스크롤 안이라 폭을 재어 줘야 한다
        child: IntrinsicWidth(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: 6,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  label,
                  style: TextStyle(
                    color: selected
                        ? AppColors.textTitle
                        : AppColors.textSubtle,
                    fontSize: fontSize,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              ),
              Container(
                height: 3,
                decoration: BoxDecoration(
                  color: selected ? AppColors.textTitle : Colors.transparent,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
