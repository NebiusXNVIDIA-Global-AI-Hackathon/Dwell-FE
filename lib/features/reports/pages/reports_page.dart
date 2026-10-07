import 'package:dwell/core/widgets/profile_avatar.dart';
import 'package:material_ui/material_ui.dart';

import '../data/mock_cases.dart';
import '../widgets/case_card.dart';

class ReportsPage extends StatelessWidget {
  const ReportsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textColor = colors.brightness == Brightness.light
        ? const Color(0xFF243B53)
        : colors.onSurface;

    final topInset = MediaQuery.paddingOf(context).top;
    final headerTopPadding = (77.0 - topInset).clamp(0.0, 77.0).toDouble();

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(24, headerTopPadding, 24, 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Cases',
                    style: TextStyle(
                      color: textColor,
                      fontSize: 40,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -1.2,
                    ),
                  ),
                  const ProfileAvatar(nickname: 'SJ'),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Align(
                  alignment: Alignment.topLeft,
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: mockCases.map((caseItem) {
                      return SizedBox(
                        width: 114,
                        child: CaseCard(
                          key: ValueKey(caseItem.id),
                          caseItem: caseItem,
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
