import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../widgets/creation/case_creation_bottom.dart';
import '../widgets/creation/case_creation_header.dart';
import '../widgets/creation/steps/issue_type_step.dart';

class CaseCreationPage extends StatefulWidget {
  const CaseCreationPage({super.key});

  @override
  State<CaseCreationPage> createState() => _CaseCreationPageState();
}

class _CaseCreationPageState extends State<CaseCreationPage> {
  final int _currentStep = 1;
  String? _selectedIssueType;

  void _handleBack() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.goNamed('cases');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 60, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CaseCreationHeader(
                title: 'Issue Type',
                currentStep: _currentStep,
                totalSteps: 7,
                onBack: _handleBack,
              ),
              const SizedBox(height: 20),

              // 1단계: 문제 유형 선택
              Expanded(
                child: IssueTypeStep(
                  selectedIssueType: _selectedIssueType,
                  onChanged: (value) {
                    setState(() {
                      _selectedIssueType = value;
                    });
                  },
                ),
              ),
              const SizedBox(height: 16),

              // 하단 버튼
              CaseCreationBottom(
                enabled: _selectedIssueType != null,
                onNext: () {
                  // 다음 작업에서 2단계 화면 이동 연결
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
