class HomeCaseData {
  const HomeCaseData({
    required this.title,
    required this.number,
    required this.location,
    required this.lastUpdate,
    required this.createdDate,
  });
  final String title;
  final String number;
  final String location;
  final String lastUpdate;
  final String createdDate;
}

const homeCurrentCase = HomeCaseData(
  title: 'Water Leak',
  number: 'C-006',
  location: 'Bathroom - Ceiling',
  lastUpdate: 'Sep 29th, 2026',
  createdDate: '9/28',
);

const homeChecklist = [
  'Check the leak daily and add a photo if it gets worse',
  'Put a towel or bucket under the leak',
  'Avoid using the bathroom light if water is near it',
];

const homeAttentionMessage =
    'Pest and heat issues have been reported a lot in your building lately.';
