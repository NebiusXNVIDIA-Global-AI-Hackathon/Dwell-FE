import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../data/case_creation_options.dart';
import '../widgets/creation/case_creation_bottom.dart';
import '../widgets/creation/case_creation_header.dart';
import '../widgets/creation/steps/issue_type_step.dart';
import '../widgets/creation/steps/specific_issue_step.dart';

class CaseCreationPage extends StatefulWidget {
  const CaseCreationPage({super.key});

  @override
  State<CaseCreationPage> createState() => _CaseCreationPageState();
}

class _CaseCreationPageState extends State<CaseCreationPage> {
  int _currentStep = 1;

  String? _selectedIssueType;
  String? _selectedSpecificIssue;

  final TextEditingController _otherIssueController = TextEditingController();

  // 현재 단계의 Next 버튼 활성화 조건
  bool get _canGoNext {
    if (_currentStep == 1) {
      return _selectedIssueType != null;
    }

    if (_selectedSpecificIssue == null) {
      return false;
    }

    if (CaseCreationOptions.requiresOtherInput(_selectedSpecificIssue)) {
      return _otherIssueController.text.trim().isNotEmpty;
    }

    return true;
  }

  void _handleIssueTypeChanged(String value) {
    setState(() {
      // 문제 유형이 바뀌면 이전 세부 이슈와 직접 입력 초기화
      if (_selectedIssueType != value) {
        _selectedSpecificIssue = null;
        _otherIssueController.clear();
      }

      _selectedIssueType = value;
    });
  }

  void _handleSpecificIssueChanged(String value) {
    FocusScope.of(context).unfocus();

    setState(() {
      _selectedSpecificIssue = value;
    });
  }

  void _handleOtherChanged(String value) {
    // 입력할 때마다 Next 버튼 활성화 조건 다시 확인
    setState(() {});
  }

  void _handleEdit() {
    FocusScope.of(context).unfocus();

    setState(() {
      _currentStep = 1;
    });
  }

  void _handleBack() {
    if (_currentStep > 1) {
      _handleEdit();
      return;
    }

    if (context.canPop()) {
      context.pop();
    } else {
      context.goNamed('cases');
    }
  }

  void _handleNext() {
    if (!_canGoNext) {
      return;
    }

    FocusScope.of(context).unfocus();

    if (_currentStep == 1) {
      setState(() {
        _currentStep = 2;
      });
      return;
    }

    // TODO: 3단계 Location 화면을 만든 뒤 이동 연결
  }

  @override
  void dispose() {
    _otherIssueController.dispose();
    super.dispose();
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
                title: _currentStep == 1 ? 'Issue Type' : 'Specify Issue',
                currentStep: _currentStep,
                totalSteps: 7,
                onBack: _handleBack,
              ),
              const SizedBox(height: 20),

              // 단계별 입력 화면
              Expanded(
                child: _currentStep == 1
                    ? IssueTypeStep(
                        selectedIssueType: _selectedIssueType,
                        onChanged: _handleIssueTypeChanged,
                      )
                    : SpecificIssueStep(
                        issueType: _selectedIssueType!,
                        selectedIssue: _selectedSpecificIssue,
                        onChanged: _handleSpecificIssueChanged,
                        onEdit: _handleEdit,
                        otherController: _otherIssueController,
                        onOtherChanged: _handleOtherChanged,
                      ),
              ),
              const SizedBox(height: 16),

              // 하단 버튼
              CaseCreationBottom(enabled: _canGoNext, onNext: _handleNext),
            ],
          ),
        ),
      ),
    );
  }
}
