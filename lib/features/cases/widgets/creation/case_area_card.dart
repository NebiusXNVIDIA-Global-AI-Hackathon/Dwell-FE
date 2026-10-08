import 'package:flutter_svg/flutter_svg.dart';
import 'package:material_ui/material_ui.dart';

class CaseAreaCard extends StatelessWidget {
  const CaseAreaCard({
    super.key,
    required this.label,
    required this.iconPath,
    required this.onTap,
    this.selected = false,
  });

  final String label;
  final String iconPath;
  final VoidCallback onTap;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    const selectionColor = Color(0xFF007AFF);

    return Semantics(
      button: true,
      selected: selected,
      child: Material(
        color: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(
            // 선택 전에도 같은 공간을 확보해 크기 변화 방지
            color: selected ? selectionColor : Colors.transparent,
            width: 2,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(6),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 아이콘 영역
                AspectRatio(
                  aspectRatio: 1,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      DecoratedBox(
                        decoration: BoxDecoration(
                          color: const Color(0xFFE4E4E4),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(8),
                          child: SvgPicture.asset(
                            iconPath,
                            fit: BoxFit.contain,
                            excludeFromSemantics: true,
                          ),
                        ),
                      ),

                      // 선택한 카드의 오른쪽 위 체크
                      if (selected)
                        const Positioned(
                          top: 4,
                          right: 4,
                          child: ExcludeSemantics(
                            child: SizedBox(
                              width: 18,
                              height: 18,
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  color: selectionColor,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.check,
                                  size: 12,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),

                // 이름이 여러 줄이어도 카드 높이를 일정하게 유지
                SizedBox(
                  height: 48,
                  child: Text(
                    label,
                    textAlign: TextAlign.center,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: const Color(0xFF243B53),
                      fontSize: 13,
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
