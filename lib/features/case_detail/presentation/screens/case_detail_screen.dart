import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../core/theme.dart';
import '../../models/case_deletion_notice.dart';
import '../../models/case_detail.dart';
import '../../models/checklist_item.dart';
import '../../models/status_banner.dart';
import '../../state/case_detail_controller.dart';
import '../case_detail_routes.dart';
import '../case_detail_tokens.dart';
import '../widgets/add_checklist_tile.dart';
import '../widgets/case_detail_app_bar.dart';
import '../widgets/case_header.dart';
import '../widgets/case_overflow_menu.dart';
import '../widgets/case_section_header.dart';
import '../widgets/case_stage_sheet.dart';
import '../widgets/case_timeline.dart';
import '../widgets/checklist_item_tile.dart';
import '../widgets/current_status_card.dart';
import '../widgets/delete_case_dialog.dart';
import '../widgets/evidence_folder_card.dart';
import 'case_placeholder_screen.dart';

class CaseDetailScreen extends ConsumerStatefulWidget {
  const CaseDetailScreen({super.key, required this.caseId});

  final String caseId;

  @override
  ConsumerState<CaseDetailScreen> createState() => _CaseDetailScreenState();
}

class _CaseDetailScreenState extends ConsumerState<CaseDetailScreen> {
  bool _editMode = false;
  String? _editingId;
  String? _newItemId;
  String _draft = '';

  CaseDetailController get _controller =>
      ref.read(caseDetailProvider(widget.caseId).notifier);

  void _goBack() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.goNamed('cases');
    }
  }

  void _push(String name) => context.pushNamed(
    name,
    pathParameters: CaseDetailRoutes.params(widget.caseId),
  );

  // Switch to edit mode
  void _toggleEditMode() {
    _finishEditing();
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() => _editMode = !_editMode);
  }

  void _startEditing(ChecklistItem item, {bool isNew = false}) {
    _finishEditing();
    setState(() {
      _editingId = item.id;
      _newItemId = isNew ? item.id : null;
      _draft = item.text;
    });
  }

  // Save inline text; an empty new item is removed
  void _finishEditing() {
    final id = _editingId;
    if (id == null) return;
    final text = _draft.trim();
    if (text.isEmpty) {
      if (id == _newItemId) _controller.remove(id);
    } else {
      _controller.rename(id, text);
    }
    setState(() {
      _editingId = null;
      _newItemId = null;
    });
  }

  // Add an empty item and focus its input
  void _addItem() {
    _finishEditing();
    final id = _controller.addEmpty();
    _startEditing(ChecklistItem(id: id, text: ''), isNew: true);
  }

  void _removeItem(String id) {
    if (id == _editingId) {
      setState(() {
        _editingId = null;
        _newItemId = null;
      });
    }
    _controller.remove(id);
  }

  // Route the banner button by its action type
  void _runAction(CaseDetail detail) {
    final action = detail.banner.action;
    switch (action.type) {
      case StatusActionType.sendNotice:
        _push(CaseDetailRoutes.notice);
      case StatusActionType.addPhotos:
        _push(CaseDetailRoutes.addEvidence);
      case StatusActionType.talkToDeaver:
        context.pushNamed(
          'assistant-chat',
          pathParameters: {'caseNo': detail.caseNumber},
        );
      case StatusActionType.updateStatus:
        _changeStage(detail);
      case StatusActionType.addToCalendar ||
          StatusActionType.escalate ||
          StatusActionType.saveReport ||
          StatusActionType.sendClaim:
        Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => CasePlaceholderScreen(title: action.label),
          ),
        );
    }
  }

  // Pick a new stage from the sheet
  Future<void> _changeStage(CaseDetail detail) async {
    final stage = await CaseStageSheet.show(context, detail.stage);
    if (stage == null || !mounted) return;
    _finishEditing();
    setState(() => _editMode = false);
    _controller.setStage(stage);
  }

  Future<void> _deleteCase() async {
    final confirmed = await DeleteCaseDialog.show(context);
    if (!confirmed || !mounted) return;
    _controller.deleteCase();
    // Return to Cases screen after deletion
    context.goNamed('cases', extra: CaseDeletionNotice(widget.caseId));
  }

  @override
  Widget build(BuildContext context) {
    final detail = ref.watch(caseDetailProvider(widget.caseId));

    return Scaffold(
      backgroundColor: CaseDetailColors.background,
      body: SafeArea(
        child: detail == null
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  CaseDetailAppBar(title: 'Case Detail', onBack: _goBack),
                  const Expanded(
                    child: Center(
                      child: Text(
                        'This case is no longer available.',
                        style: CaseDetailText.statusMeta,
                      ),
                    ),
                  ),
                ],
              )
            : SingleChildScrollView(
                padding: const EdgeInsets.only(
                  bottom: CaseDetailGaps.ctaBottom,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    CaseDetailAppBar(
                      title: 'Case Detail',
                      onBack: _goBack,
                      trailing: CaseOverflowMenu(
                        onAddEvidence: () =>
                            _push(CaseDetailRoutes.addEvidence),
                        onDelete: _deleteCase,
                      ),
                    ),
                    const SizedBox(height: CaseDetailGaps.appBarToHeader),
                    CaseHeader(detail: detail),
                    const SizedBox(height: CaseDetailGaps.headerToStatus),
                    CurrentStatusCard(
                      banner: detail.banner,
                      onAction: () => _runAction(detail),
                    ),
                    const SizedBox(height: CaseDetailGaps.statusToTimeline),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: CaseDetailSizes.pageInset,
                      ),
                      child: _buildSections(detail),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildSections(CaseDetail detail) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        CaseSectionHeader(
          title: 'Case Timeline',
          trailing: CaseTextLink(
            label: 'View Detail',
            trailingIcon: LucideIcons.chevronRight,
            onTap: () => _push(CaseDetailRoutes.timeline),
          ),
        ),
        const SizedBox(height: CaseDetailGaps.titleToTimeline),
        CaseTimeline(
          steps: detail.timeline,
          hasEarlierSteps: detail.timelineHasEarlierSteps,
          bleedStart: CaseDetailSizes.pageInset,
          bleedEnd: CaseDetailSizes.pageInset,
        ),
        const SizedBox(height: CaseDetailGaps.timelineToChecklist),
        CaseSectionHeader(
          title: 'Checklist',
          trailing: CaseTextLink(
            label: 'Edit',
            active: _editMode,
            onTap: _toggleEditMode,
          ),
        ),
        const SizedBox(height: CaseDetailGaps.titleToList),
        for (final item in detail.checklist) ...[
          ChecklistItemTile(
            key: ValueKey(item.id),
            item: item,
            editMode: _editMode,
            editing: item.id == _editingId,
            onToggle: () => _controller.toggle(item.id),
            onEdit: () => _startEditing(item),
            onChanged: (value) => _draft = value,
            onDone: _finishEditing,
            onDelete: () => _removeItem(item.id),
          ),
          const SizedBox(height: Gap.sm),
        ],
        AddChecklistTile(onTap: _addItem),
        const SizedBox(height: CaseDetailGaps.checklistToEvidence),
        CaseSectionHeader(title: 'Evidence (${detail.evidence.length})'),
        const SizedBox(height: CaseDetailGaps.titleToList),
        Wrap(
          spacing: Gap.sm,
          runSpacing: Gap.sm,
          children: [
            for (final group in detail.evidence)
              EvidenceFolderCard(group: group),
          ],
        ),
        const SizedBox(height: CaseDetailGaps.evidenceToCta),
        _CaseAnalysisButton(onTap: () => _push(CaseDetailRoutes.analysis)),
      ],
    );
  }
}

class _CaseAnalysisButton extends StatelessWidget {
  const _CaseAnalysisButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: CaseDetailColors.navy,
      borderRadius: BorderRadius.circular(CaseDetailSizes.ctaRadius),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: const SizedBox(
          height: CaseDetailSizes.ctaHeight,
          child: Center(
            child: Text(
              'View Case Analysis',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: CaseDetailText.cta,
            ),
          ),
        ),
      ),
    );
  }
}
