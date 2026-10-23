import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/case_detail_mock.dart';
import '../models/case_detail.dart';
import '../models/case_stage.dart';
import '../models/checklist_item.dart';
import 'deleted_cases_provider.dart';

final caseDetailProvider =
    NotifierProvider.family<CaseDetailController, CaseDetail?, String>(
      CaseDetailController.new,
    );

class CaseDetailController extends Notifier<CaseDetail?> {
  CaseDetailController(this.caseId);

  final String caseId;

  @override
  CaseDetail? build() {
    if (ref.read(deletedCaseIdsProvider).contains(caseId)) return null;
    return findMockCaseDetail(caseId);
  }

  void _updateChecklist(
    List<ChecklistItem> Function(List<ChecklistItem>) update,
  ) {
    final detail = state;
    if (detail == null) return;
    state = detail.copyWith(checklist: update(detail.checklist));
  }

  // Toggle checklist completion
  void toggle(String id) => _updateChecklist(
    (items) => [
      for (final item in items)
        item.id == id ? item.copyWith(isDone: !item.isDone) : item,
    ],
  );

  // Append an empty item for inline input
  String addEmpty() {
    final id = '$caseId-check-${DateTime.now().microsecondsSinceEpoch}';
    _updateChecklist((items) => [...items, ChecklistItem(id: id, text: '')]);
    return id;
  }

  void rename(String id, String text) => _updateChecklist(
    (items) => [
      for (final item in items)
        item.id == id ? item.copyWith(text: text) : item,
    ],
  );

  void remove(String id) => _updateChecklist(
    (items) => [
      for (final item in items)
        if (item.id != id) item,
    ],
  );

  // Move the case to another stage and reset the stage checklist
  void setStage(CaseStage stage) {
    final detail = state;
    if (detail == null || detail.stage == stage) return;
    state = withStage(detail, stage);
  }

  // Remove the case from the mock data
  void deleteCase() => ref.read(deletedCaseIdsProvider.notifier).add(caseId);
}
