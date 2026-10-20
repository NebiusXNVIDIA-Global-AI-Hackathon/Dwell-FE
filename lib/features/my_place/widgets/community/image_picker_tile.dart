import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../core/app_colors.dart';
import '../../../../core/theme.dart';

/// 사진 추가 자리 — 고른 뒤 화면이 와프에 없어서 자리만 잡아 둔다
class ImagePickerTile extends StatelessWidget {
  const ImagePickerTile({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Add image',
      child: Material(
        color: AppColors.divider,
        borderRadius: BorderRadius.circular(Gap.sm),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: const SizedBox(
            width: 96,
            height: 96,
            child: Icon(LucideIcons.plus, size: 44, color: AppColors.surface),
          ),
        ),
      ),
    );
  }
}
