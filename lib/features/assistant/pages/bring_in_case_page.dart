import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/app_colors.dart';
import '../../../core/theme.dart';
import '../../../shared/widgets/primary_button.dart';
import '../../../shared/widgets/state_views.dart';
import '../data/assistant_assets.dart';
import '../data/bring_in_case_mock.dart';
import '../models/case_stage.dart';
import '../providers/chat_providers.dart';

/// 채팅이 없는 케이스를 골라 채팅을 연다
class BringInCasePage extends ConsumerStatefulWidget {
  const BringInCasePage({super.key});

  @override
  ConsumerState<BringInCasePage> createState() => _BringInCasePageState();
}

class _BringInCasePageState extends ConsumerState<BringInCasePage> {
  String? _selectedCaseNo;

  void _startChat(BuildContext context, SelectableCase item) {
    ref.read(chatThreadsProvider.notifier).openCaseChat(item);
    context.push('/assistant/chat/${item.caseNo}');
  }

  @override
  Widget build(BuildContext context) {
    final cases = ref.watch(selectableCasesProvider);
    final selected = _selectedCaseNo;

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Column(
          children: [
            _Header(onBack: () => context.pop()),
            Expanded(
              child: cases.isEmpty
                  ? const EmptyView(message: 'No cases to bring in')
                  : ListView(
                      padding: const EdgeInsets.fromLTRB(
                        Gap.screenH,
                        Gap.lg,
                        Gap.screenH,
                        Gap.lg,
                      ),
                      children: [
                        // 상태별로 묶어 라벨을 붙인다
                        for (final group in _groupByStage(cases).entries) ...[
                          Padding(
                            padding: const EdgeInsets.only(bottom: Gap.card),
                            child: Text(
                              group.key.headerBadge,
                              style: const TextStyle(
                                color: AppColors.textTitle,
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                height: 1.35,
                              ),
                            ),
                          ),
                          for (final item in group.value)
                            Padding(
                              padding: const EdgeInsets.only(bottom: Gap.sm),
                              child: _CaseCard(
                                item: item,
                                selected: item.caseNo == selected,
                                onTap: () => setState(
                                  () => _selectedCaseNo = item.caseNo,
                                ),
                              ),
                            ),
                        ],
                      ],
                    ),
            ),
            if (cases.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  Gap.screenH,
                  0,
                  Gap.screenH,
                  36,
                ),
                child: PrimaryButton(
                  label: selected == null
                      ? 'Start chat'
                      : 'Start chat with $selected',
                  onPressed: selected == null
                      ? null
                      : () => _startChat(
                          context,
                          cases.firstWhere((c) => c.caseNo == selected),
                        ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

Map<CaseStage, List<SelectableCase>> _groupByStage(List<SelectableCase> cases) {
  final grouped = <CaseStage, List<SelectableCase>>{};
  for (final item in cases) {
    grouped.putIfAbsent(item.stage, () => []).add(item);
  }
  return grouped;
}

class _Header extends StatelessWidget {
  const _Header({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(Gap.screenH, Gap.md, Gap.screenH, 0),
      child: Row(
        spacing: Gap.md,
        children: [
          Semantics(
            button: true,
            label: 'Back',
            child: InkWell(
              onTap: onBack,
              customBorder: const CircleBorder(),
              child: SizedBox(
                width: 32,
                height: 32,
                child: Center(
                  child: SvgPicture.asset(
                    chatBackIconPath,
                    width: 29,
                    height: 29,
                  ),
                ),
              ),
            ),
          ),
          const Expanded(
            child: Text(
              'Bring in a case',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: AppColors.textTitle,
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CaseCard extends StatelessWidget {
  const _CaseCard({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  final SelectableCase item;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Gap.sm),
        side: selected
            ? const BorderSide(color: AppColors.navy, width: 1.5)
            : const BorderSide(color: AppColors.divider),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(Gap.card),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            spacing: Gap.card,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: AppColors.infoCard,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.image_outlined,
                  size: 20,
                  color: AppColors.textMuted,
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${item.title} · ${item.caseNo}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.textTitle,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      item.location,
                      style: const TextStyle(
                        color: AppColors.textBody,
                        fontSize: 13,
                      ),
                    ),
                    Text(
                      item.createdLabel,
                      style: const TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              _SelectionMark(selected: selected),
            ],
          ),
        ),
      ),
    );
  }
}

class _SelectionMark extends StatelessWidget {
  const _SelectionMark({required this.selected});

  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 22,
      height: 22,
      decoration: ShapeDecoration(
        color: selected ? AppColors.navy : Colors.transparent,
        shape: CircleBorder(
          side: selected
              ? BorderSide.none
              : const BorderSide(color: AppColors.divider, width: 1.5),
        ),
      ),
      child: selected
          ? Center(
              child: Container(
                width: 8,
                height: 8,
                decoration: const ShapeDecoration(
                  color: AppColors.surface,
                  shape: CircleBorder(),
                ),
              ),
            )
          : null,
    );
  }
}
