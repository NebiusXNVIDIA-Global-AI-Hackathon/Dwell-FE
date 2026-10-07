import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../widgets/creation/case_creation_header.dart';

class CaseCreationPage extends StatefulWidget {
  const CaseCreationPage({super.key});

  @override
  State<CaseCreationPage> createState() => _CaseCreationPageState();
}

class _CaseCreationPageState extends State<CaseCreationPage> {
  final int _currentStep = 1;

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

              // 다음 작업: 단계별 입력 화면
              const Expanded(child: SizedBox.expand()),
            ],
          ),
        ),
      ),
    );
  }
}
