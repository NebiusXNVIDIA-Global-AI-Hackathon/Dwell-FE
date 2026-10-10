import 'package:material_ui/material_ui.dart';

import '../../../data/case_creation_options.dart';
import '../case_option_card.dart';

class IssueTypeStep extends StatelessWidget {
  const IssueTypeStep({
    super.key,
    required this.selectedIssueType,
    required this.onChanged,
  });

  final String? selectedIssueType;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'What issue are you experiencing?',
            style: TextStyle(
              color: Color(0xFF243B53),
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 3),
          const Text(
            'Select the issue that best describes the problem',
            style: TextStyle(
              color: Color(0xFF637381),
              fontSize: 15,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 20),

          // 문제 유형 목록
          for (final option in CaseCreationOptions.issueTypes.entries)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: CaseOptionCard(
                label: option.key,
                iconPath: option.value,
                selected: selectedIssueType == option.key,
                onTap: () => onChanged(option.key),
              ),
            ),
        ],
      ),
    );
  }
}
