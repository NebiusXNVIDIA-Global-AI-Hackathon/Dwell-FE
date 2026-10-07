import 'case_model.dart';

enum CaseFilterGroup { severity, issueType, location, affectedArea, visibility }

extension CaseFilterGroupLabel on CaseFilterGroup {
  String get label => switch (this) {
    CaseFilterGroup.severity => 'Severity',
    CaseFilterGroup.issueType => 'Issue type',
    CaseFilterGroup.location => 'Location',
    CaseFilterGroup.affectedArea => 'Affected Area',
    CaseFilterGroup.visibility => 'Visibility',
  };
}

/// 디자인에 나온 순서와 선택지를 한 곳에서 관리한다.
abstract final class CaseFilterOptions {
  static const Map<CaseFilterGroup, List<String>> values = {
    CaseFilterGroup.severity: ['High', 'Medium', 'Low'],
    CaseFilterGroup.issueType: [
      'Water Intrusion',
      'Mold',
      'Heating',
      'Wall damage',
    ],
    CaseFilterGroup.location: ['Bathroom', 'Living Room', 'Bedroom'],
    CaseFilterGroup.affectedArea: ['Ceiling', 'Wall', 'Under Sink'],
    CaseFilterGroup.visibility: ['Public', 'Private'],
  };
}

typedef CaseFilterTag = ({CaseFilterGroup group, String value});

/// 원본을 수정하지 않는 값 객체. 적용값과 임시값을 안전하게 분리한다.
class CaseFilters {
  final Map<CaseFilterGroup, Set<String>> _selections;

  CaseFilters({Map<CaseFilterGroup, Set<String>> selections = const {}})
    : _selections = Map<CaseFilterGroup, Set<String>>.unmodifiable({
        for (final group in CaseFilterGroup.values)
          group: Set<String>.unmodifiable(
            selections[group] ?? const <String>{},
          ),
      });

  Set<String> selectedFor(CaseFilterGroup group) => _selections[group]!;

  bool get hasSelection =>
      _selections.values.any((values) => values.isNotEmpty);

  List<CaseFilterTag> get tags => [
    for (final group in CaseFilterGroup.values)
      for (final value in CaseFilterOptions.values[group]!)
        if (selectedFor(group).contains(value)) (group: group, value: value),
  ];

  CaseFilters _replace(CaseFilterGroup group, Set<String> values) {
    return CaseFilters(selections: {..._selections, group: values});
  }

  CaseFilters toggle(CaseFilterGroup group, String value) {
    final next = {...selectedFor(group)};
    if (!next.remove(value)) {
      next.add(value);
    }
    return _replace(group, next);
  }

  CaseFilters remove(CaseFilterGroup group, String value) {
    final next = {...selectedFor(group)}..remove(value);
    return _replace(group, next);
  }

  /// Set 비교이므로 선택한 순서가 달라도 같은 조건으로 판단
  bool sameAs(CaseFilters other) {
    return CaseFilterGroup.values.every((group) {
      final current = selectedFor(group);
      final target = other.selectedFor(group);
      return current.length == target.length && current.containsAll(target);
    });
  }

  bool matches(CaseModel item) {
    final values = <CaseFilterGroup, String>{
      CaseFilterGroup.severity: switch (item.severity) {
        CaseSeverity.high => 'High',
        CaseSeverity.medium => 'Medium',
        CaseSeverity.low => 'Low',
      },
      CaseFilterGroup.issueType: item.issueType,
      CaseFilterGroup.location: item.location,
      CaseFilterGroup.affectedArea: item.affectedArea,
      CaseFilterGroup.visibility: item.isPublic ? 'Public' : 'Private',
    };

    return CaseFilterGroup.values.every((group) {
      final selected = selectedFor(group);
      return selected.isEmpty || selected.contains(values[group]);
    });
  }
}
