import 'package:flutter/gestures.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../core/theme.dart';
import '../../models/building_signal.dart';
import 'rising_issue_card.dart';

/// 이슈가 둘 이상일 때 — 다음 카드가 우측에 살짝 보인다
class RisingIssueCarousel extends StatelessWidget {
  const RisingIssueCarousel({
    super.key,
    required this.signals,
    required this.onCheckUnit,
  });

  final List<BuildingSignal> signals;
  final void Function(BuildingSignal signal) onCheckUnit;

  @override
  Widget build(BuildContext context) {
    // 웹 기본 설정에는 마우스가 빠져 있어 드래그가 죽는다
    return ScrollConfiguration(
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
        padding: const EdgeInsets.symmetric(horizontal: Gap.lg),
        // stretch + 높이 미지정은 세로 스크롤 안에서 제약이 순환한다
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: Gap.md,
            children: [
              for (final signal in signals)
                SizedBox(
                  width: 208,
                  child: RisingIssueCard(
                    signal: signal,
                    compact: true,
                    onCheckUnit: () => onCheckUnit(signal),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
