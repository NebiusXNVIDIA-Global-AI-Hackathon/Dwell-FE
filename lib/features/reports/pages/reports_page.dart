import 'package:material_ui/material_ui.dart';

import '../data/mock_cases.dart';
import '../widgets/case_card.dart';

class ReportsPage extends StatelessWidget {
  const ReportsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: mockCases.map((caseItem) {
              return SizedBox(
                width: 114,
                child: CaseCard(key: ValueKey(caseItem.id), caseItem: caseItem),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}
