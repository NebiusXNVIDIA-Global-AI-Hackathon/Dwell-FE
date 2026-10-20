import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../core/app_colors.dart';
import '../../../../core/theme.dart';

/// 목록 상단 검색 — 커뮤니티 · 집주인 언급 글 공용
///
/// 커뮤니티 목록은 눌러서 검색 화면으로 넘어간다 — 그때는 [onTap] 만 준다
class MyPlaceSearchField extends StatelessWidget {
  const MyPlaceSearchField({
    super.key,
    required this.hintText,
    this.controller,
    this.onChanged,
    this.onTap,
  }) : assert(
         onTap != null || (controller != null && onChanged != null),
         'needs either a tap target or a controller',
       );

  final String hintText;
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onTap;

  static const _hintStyle = TextStyle(
    color: AppColors.textMuted,
    fontSize: 15,
    fontWeight: FontWeight.w500,
  );

  @override
  Widget build(BuildContext context) {
    if (onTap != null) {
      return Semantics(
        button: true,
        child: GestureDetector(
          onTap: onTap,
          behavior: HitTestBehavior.opaque,
          child: _frame(Text(hintText, style: _hintStyle)),
        ),
      );
    }

    return _frame(
      TextField(
        controller: controller,
        onChanged: onChanged,
        style: const TextStyle(
          color: AppColors.textTitle,
          fontSize: 15,
          fontWeight: FontWeight.w500,
        ),
        decoration: InputDecoration(
          isDense: true,
          border: InputBorder.none,
          hintText: hintText,
          hintStyle: _hintStyle,
        ),
      ),
    );
  }

  Widget _frame(Widget field) {
    return Container(
      constraints: const BoxConstraints(minHeight: 52),
      decoration: BoxDecoration(
        color: AppColors.systemPill,
        borderRadius: BorderRadius.circular(10),
      ),
      padding: const EdgeInsets.symmetric(horizontal: Gap.md),
      child: Row(
        spacing: Gap.card,
        children: [
          const Icon(LucideIcons.search, size: 22, color: AppColors.textSubtle),
          Expanded(child: field),
        ],
      ),
    );
  }
}
