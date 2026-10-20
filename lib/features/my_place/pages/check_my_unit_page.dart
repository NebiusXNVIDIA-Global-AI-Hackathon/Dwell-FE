import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/app_colors.dart';
import '../../../core/theme.dart';
import '../../../shared/widgets/primary_button.dart';
import '../../../shared/widgets/state_views.dart';
import '../../assistant/data/chat_scenarios.dart';
import '../../assistant/data/inspection_chat_mock.dart';
import '../../assistant/models/chat_thread.dart';
import '../../assistant/providers/chat_providers.dart';
import '../data/building_signals_mock.dart';
import '../models/inspection.dart';
import '../providers/my_place_providers.dart';
import '../widgets/common/my_place_app_bar.dart';
import '../widgets/inspection/inspection_result_dialog.dart';
import '../widgets/inspection/symptom_tile.dart';

/// 체크 결과에 따라 상담 또는 케이스 생성으로 갈라진다
class CheckMyUnitPage extends ConsumerStatefulWidget {
  const CheckMyUnitPage({super.key, required this.signalId});

  final int signalId;

  @override
  ConsumerState<CheckMyUnitPage> createState() => _CheckMyUnitPageState();
}

class _CheckMyUnitPageState extends ConsumerState<CheckMyUnitPage> {
  final _checked = <String>{};

  @override
  Widget build(BuildContext context) {
    final guide = ref.watch(inspectionGuideProvider(widget.signalId));

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: guide.when(
          loading: () => const LoadingView(),
          error: (error, _) => AppErrorView(
            error: error,
            onRetry: () =>
                ref.invalidate(inspectionGuideProvider(widget.signalId)),
          ),
          data: (data) => data == null
              ? const EmptyView(message: 'Nothing to check for this signal')
              : _buildForm(data),
        ),
      ),
    );
  }

  Widget _buildForm(InspectionGuide guide) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        MyPlaceAppBar(title: 'Check My Unit', onBack: () => context.pop()),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
              Gap.screenH,
              Gap.md,
              Gap.screenH,
              Gap.md,
            ),
            children: [
              const Text(
                'Check what you notice in your unit',
                style: TextStyle(
                  color: AppColors.textTitle,
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  height: 1.3,
                ),
              ),
              const SizedBox(height: Gap.sm),
              Text(
                guide.subtitle,
                style: const TextStyle(
                  color: AppColors.textSubtle,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  height: 1.3,
                ),
              ),
              const SizedBox(height: Gap.lg),
              for (final symptom in guide.symptoms)
                Padding(
                  padding: const EdgeInsets.only(bottom: Gap.sm),
                  child: SymptomTile(
                    label: symptom.label.en,
                    selected: _checked.contains(symptom.key),
                    onTap: () => _toggle(symptom.key),
                  ),
                ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(
            Gap.screenH,
            0,
            Gap.screenH,
            Gap.lg,
          ),
          child: PrimaryButton(
            label: 'Next',
            // 하나도 고르지 않으면 결과 화면이 생기지 않는다
            onPressed: _checked.isEmpty ? null : () => _submit(guide),
          ),
        ),
      ],
    );
  }

  void _toggle(String key) {
    setState(() {
      if (!_checked.remove(key)) _checked.add(key);
    });
  }

  Future<void> _submit(InspectionGuide guide) async {
    final choice = await InspectionResultDialog.show(context);
    if (choice == null || !mounted) return;

    switch (choice) {
      case InspectionChoice.talkToDeaver:
        _openDeaverChat(guide);
      case InspectionChoice.createCase:
        // 위저드가 아직 초기값을 받지 못한다 — 빈 상태로 연다
        context.push('/cases/new');
    }
  }

  void _openDeaverChat(InspectionGuide guide) {
    final threadId = 'inspection-${guide.signalId}';
    final label = signalShortLabel(guide.signalId);
    final checked = [
      for (final symptom in guide.symptoms)
        if (_checked.contains(symptom.key)) symptom.label.en,
    ];

    registerScenario(
      threadId,
      inspectionChatScenario(issueKey: guide.category.name, symptoms: checked),
    );

    if (ref.read(chatThreadProvider(threadId)) == null) {
      ref
          .read(chatThreadsProvider.notifier)
          .addGeneral(
            ChatThread(
              id: threadId,
              kind: ChatKind.general,
              title: 'Possible $label Issue',
              preview: 'Deaver: Can you upload a few photos…',
              timeLabel: 'now',
            ),
          );
    }

    context.push('/assistant/chat/$threadId');
  }
}
