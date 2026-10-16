import '../../cases/models/case_model.dart';

enum HomeCaseProgress { created, notifiedLandlord, waitingForResponse }

/// Presentation data only; these demo models are never added to Reports.
class HomeCaseData {
  const HomeCaseData({
    required this.caseItem,
    required this.lastUpdate,
    required this.createdDate,
    required this.checklist,
    this.progress = HomeCaseProgress.notifiedLandlord,
  });
  final CaseModel caseItem;
  final String lastUpdate;
  final String createdDate;
  final List<String> checklist;
  final HomeCaseProgress progress;
  String get title => caseItem.title;
  String get number => caseItem.id;
  String get location => '${caseItem.location} - ${caseItem.affectedArea}';
  CaseSeverity get severity => caseItem.severity;
}

const homeChecklist = [
  'Check the leak daily and add a photo if it gets worse',
  'Put a towel or bucket under the leak',
  'Avoid using the bathroom light if water is near it',
];

final homeCases = List<HomeCaseData>.unmodifiable([
  HomeCaseData(
    caseItem: CaseModel(
      id: 'C-006',
      title: 'Water Leak',
      status: CaseStatus.logged,
      severity: CaseSeverity.high,
      issueType: 'Plumbing',
      location: 'Bathroom',
      affectedArea: 'Ceiling',
      isPublic: false,
      createdAt: DateTime(2026, 9, 28),
      updatedAt: DateTime(2026, 9, 29),
    ),
    lastUpdate: 'Sep 29th, 2026',
    createdDate: '9/28',
    checklist: homeChecklist,
  ),
  HomeCaseData(
    caseItem: CaseModel(
      id: 'C-005',
      title: 'Roaches',
      status: CaseStatus.logged,
      severity: CaseSeverity.medium,
      issueType: 'Pests',
      location: 'Livingroom',
      affectedArea: 'Corner',
      isPublic: false,
      createdAt: DateTime(2026, 9, 28),
      updatedAt: DateTime(2026, 9, 29),
    ),
    lastUpdate: 'Sep 29th, 2026',
    createdDate: '9/28',
    checklist: const [
      'Take a photo or video when you spot them',
      'Note where and when you see them most',
      'Store food in sealed containers',
      'Take out trash daily and keep it sealed',
    ],
  ),
]);
const homeAttentionMessage =
    'Pest and heat issues have been reported a lot in your building lately.';
