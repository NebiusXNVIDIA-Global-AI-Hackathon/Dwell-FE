import 'package:material_ui/material_ui.dart';

import '../../../../core/app_colors.dart';
import '../../../../core/theme.dart';

/// `Sort by Newest ˅` — 목록 우측 정렬 메뉴
class MyPlaceSortMenu<T> extends StatelessWidget {
  const MyPlaceSortMenu({
    super.key,
    required this.value,
    required this.options,
    required this.labelOf,
    required this.onSelected,
  });

  final T value;
  final List<T> options;
  final String Function(T option) labelOf;
  final ValueChanged<T> onSelected;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<T>(
      initialValue: value,
      onSelected: onSelected,
      position: PopupMenuPosition.under,
      itemBuilder: (context) => [
        for (final option in options)
          PopupMenuItem(
            value: option,
            child: Text(
              labelOf(option),
              style: const TextStyle(
                color: AppColors.textTitle,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
      ],
      child: Row(
        mainAxisSize: MainAxisSize.min,
        spacing: Gap.xs,
        children: [
          const Text(
            'Sort by',
            style: TextStyle(
              color: AppColors.textTitle,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            '${labelOf(value)} ˅',
            style: const TextStyle(
              color: AppColors.textTitle,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
