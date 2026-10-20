import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/app_colors.dart';
import '../../core/theme.dart';
import '../../shared/widgets/state_views.dart';
import '../assistant/data/shared_mock.dart';
import '../auth/providers/profile_provider.dart';
import 'models/building_signal.dart';
import 'providers/my_place_providers.dart';
import 'widgets/main/all_clear_card.dart';
import 'widgets/main/my_place_header.dart';
import 'widgets/main/rising_issue_card.dart';
import 'widgets/main/rising_issue_carousel.dart';
import 'widgets/main/section_tile.dart';

class MyPlacePage extends ConsumerWidget {
  const MyPlacePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final place = ref.watch(placeSummaryProvider);
    final nickname = ref.watch(profileNicknameProvider) ?? demoUserInitials;

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: place.when(
        loading: () => const LoadingView(),
        error: (error, _) => AppErrorView(
          error: error,
          onRetry: () => ref.invalidate(placeSummaryProvider),
        ),
        data: (summary) => SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              MyPlaceHeader(
                address: summary.address,
                nickname: nickname,
                card: _IssueArea(
                  signals: summary.risingIssues,
                  onCheckUnit: (signal) => _openCheckUnit(context, signal),
                ),
              ),
              const SizedBox(height: Gap.lg),
              const _SectionTitle('Need to know'),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: Gap.md),
                child: Column(
                  spacing: Gap.card,
                  children: [
                    SectionTile(
                      icon: LucideIcons.satelliteDish,
                      title: 'Building Signals',
                      description:
                          'Spot recurring issues and check your unit early.',
                      onTap: () => _openSignals(context),
                    ),
                    SectionTile(
                      icon: LucideIcons.fileText,
                      title: 'Building Insights',
                      description:
                          "See your landlord's past responses and building "
                          'records.',
                      onTap: () => context.push('/my-place/insights'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: Gap.lg),
              const _SectionTitle('Explore'),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: Gap.md),
                child: SectionTile(
                  icon: LucideIcons.houses,
                  title: 'Neighbor Community',
                  description:
                      'Ask neighbors and share tips about your building',
                  onTap: () => context.push('/my-place/community'),
                ),
              ),
              const SizedBox(height: Gap.xl),
            ],
          ),
        ),
      ),
    );
  }

  void _openCheckUnit(BuildContext context, BuildingSignal signal) =>
      context.push('/my-place/check-unit/${signal.signalId}');

  void _openSignals(BuildContext context) => context.push('/my-place/signals');
}

/// 이슈 0 / 1 / 2개 이상으로 갈린다
class _IssueArea extends StatelessWidget {
  const _IssueArea({required this.signals, required this.onCheckUnit});

  final List<BuildingSignal> signals;
  final void Function(BuildingSignal signal) onCheckUnit;

  @override
  Widget build(BuildContext context) {
    if (signals.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(horizontal: Gap.lg),
        child: AllClearCard(),
      );
    }

    if (signals.length == 1) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: Gap.lg),
        child: RisingIssueCard(
          signal: signals.first,
          onCheckUnit: () => onCheckUnit(signals.first),
        ),
      );
    }

    return RisingIssueCarousel(signals: signals, onCheckUnit: onCheckUnit);
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(Gap.md, 0, Gap.md, Gap.card),
      child: Text(
        text,
        style: const TextStyle(
          color: AppColors.textTitle,
          fontSize: 17,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
