import 'package:dwell/features/cases/controllers/case_creation_controller.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  CaseCreationController atLocation() {
    final c = CaseCreationController();
    c.selectIssueType('Plumbing');
    c.next();
    c.selectSpecificIssue('Other');
    c.setOtherIssue(' leak ');
    c.next();
    return c;
  }

  test('Other requires trimmed input at each implemented step', () {
    final c = CaseCreationController();
    c.selectIssueType('Appliances');
    c.next();
    c.selectSpecificIssue('Other Appliance');
    c.setOtherIssue('  ');
    expect(c.canGoNext, isFalse);
    c.setOtherIssue(' oven ');
    c.next();
    c.selectLocation('Other');
    c.setOtherLocation('  ');
    expect(c.canGoNext, isFalse);
    c.setOtherLocation(' garage ');
    c.next();
    expect(c.currentStep, 4);
    c.selectAffectedArea('Other');
    c.setOtherAffectedArea('  ');
    expect(c.canGoNext, isFalse);
    c.setOtherAffectedArea(' corner ');
    expect(c.canGoNext, isTrue);
    c.next();
    expect(c.currentStep, 4);
  });
  test(
    'Edit and reselect preserve input; changed parent resets descendants',
    () {
      final c = atLocation();
      c.selectLocation('Other');
      c.setOtherLocation('garage');
      c.next();
      c.selectAffectedArea('Other');
      c.setOtherAffectedArea('corner');
      c.editIssue();
      c.selectIssueType('Plumbing');
      c.next();
      c.selectSpecificIssue('Other');
      expect(c.draft.otherIssue, ' leak ');
      c.next();
      c.selectLocation('Other');
      expect(c.draft.otherLocation, 'garage');
      c.next();
      c.selectAffectedArea('Other');
      expect(c.draft.otherAffectedArea, 'corner');
      c.editLocation();
      expect(c.currentStep, 3);
      c.selectLocation('Kitchen');
      expect(c.draft.affectedArea, isNull);
      expect(c.draft.otherAffectedArea, isEmpty);
      c.editIssue();
      c.next();
      c.selectSpecificIssue('Sink Issue');
      expect(c.draft.otherIssue, isEmpty);
      expect(c.draft.location, isNull);
      expect(c.draft.otherLocation, isEmpty);
      c.editIssue();
      c.selectIssueType('Gas');
      expect(c.draft.specificIssue, isNull);
    },
  );
  test('Entire Unit skips affected area until evidence is implemented', () {
    final c = atLocation();
    c.selectLocation('Entire Unit');
    c.next();
    expect(c.currentStep, 3);
    expect(c.draft.affectedArea, isNull);
    expect(CaseCreationController.totalSteps, 7);
  });
}
