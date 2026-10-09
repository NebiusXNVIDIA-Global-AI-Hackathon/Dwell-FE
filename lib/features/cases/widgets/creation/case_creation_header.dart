import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:material_ui/material_ui.dart';

class CaseCreationHeader extends StatelessWidget {
  const CaseCreationHeader({
    super.key,
    required this.title,
    required this.currentStep,
    required this.onBack,
    this.totalSteps = 7,
  }) : assert(totalSteps > 0),
       assert(currentStep >= 1 && currentStep <= totalSteps);

  final String title;
  final int currentStep;
  final int totalSteps;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // 뒤로가기 버튼
                Material(
                  color: Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: const BorderSide(color: Color(0xFFE3E3E3)),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: const SizedBox(
                    width: 33,
                    height: 33,
                    child: Center(
                      child: Icon(
                        LucideIcons.chevronLeft,
                        size: 20,
                        color: Color(0xFF606060),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),

                // 현재 단계 제목
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      color: Color(0xFF243B53),
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 8),

                // 현재 단계 / 전체 단계
                Text(
                  'steps $currentStep of $totalSteps',
                  style: const TextStyle(
                    color: Color(0xFF5E5E5E),
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // 진행바
            LinearProgressIndicator(
              value: currentStep / totalSteps,
              minHeight: 5,
              color: const Color(0xFF243B53),
              backgroundColor: const Color(0xFFE3E3E3),
              borderRadius: BorderRadius.circular(100),
              trackGap: 0,
              stopIndicatorRadius: 0,
            ),
          ],
        ),
        // The entire 44px target stays inside the header's real bounds.
        Positioned(
          left: 0,
          top: 0,
          bottom: 15,
          width: 44,
          child: Align(
            alignment: Alignment.centerLeft,
            child: Semantics(
              label: 'Back',
              button: true,
              onTap: onBack,
              excludeSemantics: true,
              child: Tooltip(
                message: 'Back',
                excludeFromSemantics: true,
                child: SizedBox(
                  width: 44,
                  height: 44,
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: onBack,
                      excludeFromSemantics: true,
                      overlayColor: const WidgetStatePropertyAll(
                        Colors.transparent,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
