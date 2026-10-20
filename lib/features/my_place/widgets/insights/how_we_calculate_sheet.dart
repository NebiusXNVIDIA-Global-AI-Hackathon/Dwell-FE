import 'package:material_ui/material_ui.dart';

import '../../../../core/app_colors.dart';
import '../../../../core/theme.dart';
import '../../models/landlord_insight.dart';
import '../charts/gauge_mark.dart';
import 'insights_badge.dart';

/// 점수를 어떻게 내는지 — 데이터가 없으면 점수도 없다는 걸 못 박는 화면
class HowWeCalculateSheet extends StatelessWidget {
  const HowWeCalculateSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: const Color(0x73121A26),
      isScrollControlled: true,
      useRootNavigator: true,
      builder: (context) => const HowWeCalculateSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(Gap.screenH)),
      ),
      padding: const EdgeInsets.fromLTRB(Gap.screenH, 10, Gap.screenH, 34),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: Gap.md,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.divider,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const Text(
              'How we calculate',
              style: TextStyle(
                color: AppColors.chartInk,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const Column(
              spacing: Gap.card,
              children: [
                _Step(
                  number: 1,
                  title: 'HPD records',
                  description: 'Public NYC data',
                  badge: InsightsBadge(
                    label: 'Always available',
                    tone: BadgeTone.info,
                  ),
                ),
                _Step(
                  number: 2,
                  title: 'Neighbor posts',
                  description: 'Posts about this landlord',
                  badge: InsightsBadge(
                    label: 'Needs 3+ posts',
                    tone: BadgeTone.warning,
                  ),
                ),
                _Step(
                  number: 3,
                  title: 'No guessing',
                  description: 'No data, no score',
                  badge: InsightsBadge(
                    label: 'Not enough data',
                    tone: BadgeTone.neutral,
                  ),
                ),
              ],
            ),
            const Divider(height: 1, color: AppColors.chartTrack),
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                spacing: Gap.sm,
                children: [
                  for (final rating in const [
                    LandlordRating.fixesQuickly,
                    LandlordRating.aboutAverage,
                    LandlordRating.slowToFix,
                  ])
                    Expanded(child: _RatingSample(rating: rating)),
                ],
              ),
            ),
            SizedBox(
              width: double.infinity,
              child: Material(
                color: AppColors.chartInk,
                borderRadius: BorderRadius.circular(Gap.card),
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: () => Navigator.of(context).pop(),
                  child: Container(
                    constraints: const BoxConstraints(minHeight: 52),
                    alignment: Alignment.center,
                    child: const Text(
                      'Got it',
                      style: TextStyle(
                        color: AppColors.surface,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Step extends StatelessWidget {
  const _Step({
    required this.number,
    required this.title,
    required this.description,
    required this.badge,
  });

  final int number;
  final String title;
  final String description;
  final Widget badge;

  @override
  Widget build(BuildContext context) {
    return Row(
      spacing: Gap.card,
      children: [
        Container(
          width: 32,
          height: 32,
          alignment: Alignment.center,
          decoration: const BoxDecoration(
            color: AppColors.chartTrack,
            shape: BoxShape.circle,
          ),
          child: Text(
            '$number',
            style: const TextStyle(
              color: AppColors.chartInk,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 2,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: AppColors.chartInk,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                description,
                style: const TextStyle(
                  color: AppColors.textSubtle,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        badge,
      ],
    );
  }
}

/// 배지가 어떤 모양일 때 붙는지 보여주는 샘플
class _RatingSample extends StatelessWidget {
  const _RatingSample({required this.rating});

  final LandlordRating rating;

  @override
  Widget build(BuildContext context) {
    final (ratio, color, tone) = switch (rating) {
      LandlordRating.fixesQuickly => (
        0.18,
        AppColors.chartSuccess,
        BadgeTone.success,
      ),
      LandlordRating.aboutAverage => (
        0.33,
        AppColors.chartNeutral,
        BadgeTone.neutral,
      ),
      _ => (0.65, AppColors.chartDanger, BadgeTone.danger),
    };

    return Container(
      decoration: BoxDecoration(
        color: AppColors.statTile,
        borderRadius: BorderRadius.circular(10),
      ),
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Column(
        spacing: 6,
        children: [
          GaugeMark(ratio: ratio, color: color, width: 72),
          InsightsBadge(label: rating.label, tone: tone),
        ],
      ),
    );
  }
}
