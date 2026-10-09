import 'package:flutter_svg/flutter_svg.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:material_ui/material_ui.dart';

class CaseOptionCard extends StatelessWidget {
  const CaseOptionCard({
    super.key,
    required this.label,
    required this.onTap,
    this.iconPath,
    this.selected = false,
  });

  final String label;
  final VoidCallback onTap;
  final String? iconPath;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      child: Material(
        color: selected ? const Color(0xFFEEF2F6) : const Color(0xFFF7F7F7),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(
            color: selected ? const Color(0xFF243B53) : const Color(0xFFE3E3E3),
            width: 1.5,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 64),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              child: Row(
                children: [
                  // 아이콘이 있는 카드에서만 표시
                  if (iconPath != null) ...[
                    SvgPicture.asset(
                      iconPath!,
                      width: 40,
                      height: 40,
                      excludeFromSemantics: true,
                    ),
                    const SizedBox(width: 18),
                  ],

                  // 선택 항목 이름
                  Expanded(
                    child: Text(
                      label,
                      style: TextStyle(
                        color: selected
                            ? const Color(0xFF000000)
                            : const Color(0xFF5E5E5E),
                        fontSize: 16,
                        fontWeight: selected
                            ? FontWeight.w700
                            : FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),

                  // 오른쪽 화살표
                  const Icon(
                    LucideIcons.chevronRight,
                    size: 18,
                    color: Color(0xFFA6A6A6),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
