import 'package:dwell/features/cases/controllers/case_creation_controller.dart';
import 'package:flutter_test/flutter_test.dart';

CaseCreationController descriptionController() {
  final controller = CaseCreationController();
  controller.selectIssueType('Plumbing');
  controller.next();
  controller.selectSpecificIssue('Sink Issue');
  controller.next();
  controller.selectLocation('Kitchen');
  controller.next();
  controller.selectAffectedArea('Ceiling');
  controller.beginEvidence();
  controller.beginDescription();
  return controller;
}

void main() {
  test(
    'Description validity, clear, back and reentry preserve the live draft',
    () {
      final c = descriptionController();
      final view = c.draft;
      expect(c.currentStep, 6);
      expect(c.canSubmit, false);
      c.setDescription(' \n\t ');
      expect(c.canSubmit, false);
      c.setDescription(' Water is leaking. ');
      expect(view.description, ' Water is leaking. ');
      expect(c.canSubmit, true);
      c.backToEvidence();
      expect(c.currentStep, 5);
      expect(c.canSubmit, false);
      c.beginDescription();
      expect(c.draft.description, ' Water is leaking. ');
      expect(c.draft.affectedArea, 'Ceiling');
      c.setDescription('');
      expect(view.description, '');
      expect(c.canSubmit, false);
    },
  );

  test('500 grapheme limit applies to controller updates including emoji', () {
    final c = descriptionController();
    c.setDescription(List.filled(501, '👨‍👩‍👧‍👦').join());
    expect(c.draft.description, List.filled(500, '👨‍👩‍👧‍👦').join());
  });

  test(
    'Submit and Skip produce detached data without claiming case success',
    () {
      final c = descriptionController();
      expect(() => c.completeDescription(skip: false), throwsStateError);
      expect(c.completeDescription(skip: true).description, '');
      c.setDescription(' Original description ');
      final submitted = c.completeDescription(skip: false);
      final skipped = c.completeDescription(skip: true);
      c.setDescription('Edited');
      expect(submitted.description, ' Original description ');
      expect(skipped.description, '');
      expect(skipped.issueType, submitted.issueType);
      expect(c.currentStep, 6);
      c.backToEvidence();
      expect(() => c.completeDescription(skip: true), throwsStateError);
      final fresh = CaseCreationController();
      expect(fresh.draft.description, '');
      fresh.beginDescription();
      expect(fresh.currentStep, 1);
    },
  );
}
