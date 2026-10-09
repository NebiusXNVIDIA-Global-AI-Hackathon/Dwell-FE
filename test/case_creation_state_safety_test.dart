import 'package:dwell/features/cases/controllers/case_creation_controller.dart';
import 'package:dwell/features/cases/data/case_creation_options.dart';
import 'package:dwell/features/cases/models/case_draft.dart';
import 'package:flutter_test/flutter_test.dart';

List<Object?> state(CaseCreationController c) => [
  c.draft.issueType,
  c.draft.specificIssue,
  c.draft.location,
  c.draft.affectedArea,
  c.draft.otherIssue,
  c.draft.otherLocation,
  c.draft.otherAffectedArea,
  c.currentStep,
  c.canGoNext,
  c.issueSummary,
  c.locationSummary,
];
CaseCreationController populated() {
  final c = CaseCreationController();
  c.selectIssueType('Plumbing');
  c.next();
  c.selectSpecificIssue('Other');
  c.setOtherIssue(' leak ');
  c.next();
  c.selectLocation('Other');
  c.setOtherLocation(' garage ');
  c.next();
  c.selectAffectedArea('Other');
  c.setOtherAffectedArea(' corner ');
  return c;
}

void main() {
  test(
    'One read-only live view exposes state without leaking a mutable draft',
    () {
      final c = CaseCreationController();
      final view = c.draft;
      expect(view, isA<CaseDraftView>());
      expect(view, same(c.draft));
      c.selectIssueType('Plumbing');
      expect(view.issueType, 'Plumbing');
      final external = CaseDraft()..issueType = view.issueType;
      external.issueType = 'Gas';
      external.location = 'Kitchen';
      expect(view.issueType, 'Plumbing');
      expect(view.location, isNull);
      expect(c.canGoNext, isTrue);
      // Setter access is checked by static analysis, not dynamic invocation.
    },
  );
  for (final value in ['', 'Other', ' Plumbing ']) {
    test('Invalid Issue Type "$value" preserves all state', () {
      final c = populated();
      final before = state(c);
      expect(() => c.selectIssueType(value), throwsArgumentError);
      expect(state(c), before);
    });
  }
  final invalid = <String, void Function(CaseCreationController)>{
    'different type Specific Issue': (c) => c.selectSpecificIssue('Gas Smell'),
    'unknown Specific Issue': (c) => c.selectSpecificIssue('Unknown'),
    'unknown Location': (c) => c.selectLocation('Unknown'),
    'different Location Area': (c) => c.selectAffectedArea('Cabinet'),
    'unknown Area': (c) => c.selectAffectedArea('Unknown'),
    'Other Appliance as Area': (c) => c.selectAffectedArea('Other Appliance'),
  };
  for (final entry in invalid.entries) {
    final name = entry.key;
    test('Reject $name atomically without changing text, step or Next', () {
      final c = populated();
      final before = state(c);
      expect(() => entry.value(c), throwsArgumentError);
      expect(state(c), before);
    });
  }
  final missing = <String, void Function(CaseCreationController)>{
    'Specific Issue without Issue Type': (c) => c.selectSpecificIssue('Other'),
    'Location without Issue Type': (c) => c.selectLocation('Kitchen'),
    'Area without Location': (c) => c.selectAffectedArea('Ceiling'),
  };
  for (final entry in missing.entries) {
    final name = entry.key;
    test('Reject $name before mutation', () {
      final c = CaseCreationController();
      final before = state(c);
      expect(() => entry.value(c), throwsStateError);
      expect(state(c), before);
    });
  }
  final inactive = <String, void Function(CaseCreationController)>{
    'issue': (c) => c.setOtherIssue('text'),
    'location': (c) => c.setOtherLocation('text'),
    'area': (c) => c.setOtherAffectedArea('text'),
  };
  for (final entry in inactive.entries) {
    final name = entry.key;
    test('Reject inactive Other $name input without storing hidden text', () {
      final c = CaseCreationController();
      c.selectIssueType('Plumbing');
      c.selectSpecificIssue('Sink Issue');
      c.selectLocation('Kitchen');
      c.selectAffectedArea('Sink');
      final before = state(c);
      expect(() => entry.value(c), throwsStateError);
      expect(state(c), before);
    });
  }
  test('Same selections preserve all descendants and raw Other input', () {
    final c = populated();
    final before = state(c);
    c.selectIssueType('Plumbing');
    c.selectSpecificIssue('Other');
    c.selectLocation('Other');
    c.selectAffectedArea('Other');
    expect(state(c), before);
    expect(c.issueSummary, 'Plumbing - leak');
    expect(c.locationSummary, 'garage');
  });
  for (final level in ['type', 'issue', 'location', 'area']) {
    test('Changing $level clears only dependent fields', () {
      final c = populated();
      switch (level) {
        case 'type':
          c.selectIssueType('Gas');
        case 'issue':
          c.selectSpecificIssue('Sink Issue');
        case 'location':
          c.selectLocation('Kitchen');
        case 'area':
          c.selectAffectedArea('Ceiling');
      }
      expect(c.draft.otherAffectedArea, isEmpty);
      if (level != 'area') expect(c.draft.affectedArea, isNull);
      if (level == 'type' || level == 'issue') {
        expect(c.draft.location, isNull);
        expect(c.draft.otherLocation, isEmpty);
        expect(c.draft.otherIssue, isEmpty);
      } else {
        expect(c.draft.otherIssue, ' leak ');
      }
      if (level == 'type') expect(c.draft.specificIssue, isNull);
      if (level == 'area') expect(c.draft.otherLocation, ' garage ');
      if (level == 'location') expect(c.draft.otherLocation, isEmpty);
      expect(c.currentStep, 4);
      expect(c.canGoNext, level == 'area');
    });
  }
  test('Next requires valid ancestors even after Edit calls', () {
    final c = CaseCreationController();
    c.editLocation();
    expect(c.canGoNext, isFalse);
    c.next();
    expect(c.currentStep, 3);
    c.selectIssueType('Plumbing');
    c.selectLocation('Kitchen');
    expect(c.canGoNext, isFalse);
    c.selectSpecificIssue('Other');
    c.selectLocation('Kitchen');
    c.setOtherIssue('  ');
    expect(c.canGoNext, isFalse);
    c.setOtherIssue('leak');
    expect(c.canGoNext, isTrue);
    c.next();
    c.selectAffectedArea('Ceiling');
    expect(c.canGoNext, isTrue);
    c.setOtherIssue('');
    expect(c.canGoNext, isFalse);
    c.next();
    expect(c.currentStep, 4);
  });
  test('Step 4 Next requires parent Other text and current Area text', () {
    final c = populated();
    c.setOtherLocation(' \t\n ');
    expect(c.canGoNext, isFalse);
    c.setOtherLocation('garage');
    c.setOtherAffectedArea(' \t\n ');
    expect(c.canGoNext, isFalse);
    c.setOtherAffectedArea('corner');
    expect(c.canGoNext, isTrue);
  });
  test('Entire Unit has no Area options and retains Step 5 TODO', () {
    final c = populated();
    c.editLocation();
    c.selectLocation('Entire Unit');
    final before = state(c);
    expect(() => c.selectAffectedArea('Ceiling'), throwsArgumentError);
    expect(state(c), before);
    c.next();
    expect(c.currentStep, 3);
    expect(c.draft.affectedArea, isNull);
  });
  test('Every actual type, specific issue, shared location and matching Area is accepted', () {
    final c = CaseCreationController();
    for (final type in CaseCreationOptions.issueTypes.keys) {
      c.selectIssueType(type);
      for (final issue in CaseCreationOptions.specificIssues[type]!) {
        c.selectSpecificIssue(issue);
        expect(c.draft.specificIssue, issue);
        if (CaseCreationOptions.requiresOtherInput(issue)) {
          c.setOtherIssue('detail');
        }
      }
      for (final location in CaseCreationOptions.locations.keys) {
        c.selectLocation(location);
        expect(c.draft.location, location);
        if (location == 'Other') c.setOtherLocation('garage');
        for (final area
            in (CaseCreationOptions.affectedAreas[location] ??
                    const <String, String>{})
                .keys) {
          c.selectAffectedArea(area);
          expect(c.draft.affectedArea, area);
          if (area == 'Other') c.setOtherAffectedArea('corner');
        }
      }
    }
  });
}
