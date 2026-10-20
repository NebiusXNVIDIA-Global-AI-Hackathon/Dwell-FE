import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../core/app_colors.dart';
import '../../../../core/theme.dart';

/// 체크 항목 — 타일 전체가 탭 영역
class SymptomTile extends StatelessWidget {
  const SymptomTile({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      checked: selected,
      child: Material(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(Gap.sm),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Container(
            constraints: const BoxConstraints(minHeight: 64),
            decoration: BoxDecoration(
              border: Border.all(
                color: selected ? AppColors.navy : AppColors.divider,
                width: selected ? 1.5 : 1,
              ),
              borderRadius: BorderRadius.circular(Gap.sm),
            ),
            padding: const EdgeInsets.symmetric(
              horizontal: Gap.md,
              vertical: Gap.md,
            ),
            child: Row(
              spacing: Gap.card,
              children: [
                _CheckBox(selected: selected),
                Expanded(
                  child: Text(
                    label,
                    maxLines: 2,
                    style: const TextStyle(
                      color: AppColors.textStrong,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      height: 1.3,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CheckBox extends StatelessWidget {
  const _CheckBox({required this.selected});

  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        color: selected ? AppColors.navy : AppColors.surface,
        border: Border.all(
          color: selected ? AppColors.navy : AppColors.textMuted,
          width: 1.5,
        ),
        borderRadius: BorderRadius.circular(6),
      ),
      child: selected
          ? const Icon(LucideIcons.check, size: 16, color: AppColors.surface)
          : null,
    );
  }
}
