import 'package:material_ui/material_ui.dart';

class CaseLocationCard extends StatelessWidget {
  const CaseLocationCard({
    super.key,
    required this.label,
    required this.icon,
    required this.onTap,
    this.selected = false,
    this.hasSelection = false,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final bool selected;
  final bool hasSelection;

  @override
  Widget build(BuildContext context) {
    // 선택 전에는 모두 남색, 선택 후에는 선택한 카드만 남색
    final contentColor = selected || !hasSelection
        ? const Color(0xFF243B53)
        : const Color(0xFF9FA6AA);

    return Semantics(
      button: true,
      selected: selected,
      child: Material(
        color: selected ? const Color(0xFFDDE6EF) : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: selected ? const Color(0xFF007AFF) : const Color(0xFFE3E3E3),
            width: 1,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // 위치 아이콘
                ExcludeSemantics(
                  child: Icon(icon, size: 32, color: contentColor),
                ),
                const SizedBox(height: 8),

                // 위치 이름
                Flexible(
                  child: Text(
                    label,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    style: TextStyle(
                      color: contentColor,
                      fontSize: 16,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                      height: 1.2,
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
