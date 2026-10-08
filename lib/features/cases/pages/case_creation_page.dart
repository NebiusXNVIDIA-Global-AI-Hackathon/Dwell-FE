import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../data/case_creation_options.dart';
import '../widgets/creation/case_creation_bottom.dart';
import '../widgets/creation/case_creation_header.dart';
import '../widgets/creation/dialogs/safety_notice_dialog.dart';
import '../widgets/creation/steps/issue_type_step.dart';
import '../widgets/creation/steps/specific_issue_step.dart';

class CaseCreationPage extends StatefulWidget {
  const CaseCreationPage({super.key});

  @override
  State<CaseCreationPage> createState() => _CaseCreationPageState();
}

class _CaseCreationPageState extends State<CaseCreationPage> {
  // 현재 단계와 선택한 문제 정보
  int _currentStep = 1;
  String? _selectedIssueType;
  String? _selectedSpecificIssue;

  // 안전 안내 모달 중복 표시 방지
  bool _isSafetyNoticeOpen = false;

  final TextEditingController _otherIssueController = TextEditingController();

  // 단계별 Next 버튼 활성화 조건
  bool get _canGoNext {
    if (_currentStep == 1) {
      return _selectedIssueType != null;
    }

    if (_selectedSpecificIssue == null) {
      return false;
    }

    // Other는 공백을 제외한 내용이 있어야 진행 가능
    if (CaseCreationOptions.requiresOtherInput(_selectedSpecificIssue)) {
      return _otherIssueController.text.trim().isNotEmpty;
    }

    return true;
  }

  void _handleIssueTypeChanged(String value) {
    setState(() {
      // 유형이 바뀌면 기존 세부 이슈 초기화
      if (_selectedIssueType != value) {
        _selectedSpecificIssue = null;
        _otherIssueController.clear();
      }

      _selectedIssueType = value;
    });
  }

  Future<void> _handleSpecificIssueChanged(String value) async {
    if (_isSafetyNoticeOpen) {
      return;
    }

    FocusScope.of(context).unfocus();

    setState(() {
      _selectedSpecificIssue = value;
    });

    // 위험한 전기 항목 선택 시 안내
    if (_selectedIssueType == 'Electricity' &&
        (value == 'Exposed Wiring' || value == 'Sparks / Burning Smell')) {
      await _showSafetyNotice(SafetyNoticeType.electrical);
    } else if (_selectedIssueType == 'Water & Flooding' &&
        value == 'Flooding') {
      // 침수 선택 시 안내
      await _showSafetyNotice(SafetyNoticeType.flooding);
    }
  }

  void _handleOtherChanged(String value) {
    // 입력 내용에 따라 버튼 활성화 갱신
    setState(() {});
  }

  void _handleEdit() {
    FocusScope.of(context).unfocus();

    // 선택을 유지하며 1단계로 복귀
    setState(() {
      _currentStep = 1;
    });
  }

  void _handleBack() {
    if (_currentStep > 1) {
      _handleEdit();
      return;
    }

    _leaveCreation();
  }

  // 등록 화면 종료
  void _leaveCreation() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.goNamed('cases');
    }
  }

  Future<void> _handleNext() async {
    if (!_canGoNext || _isSafetyNoticeOpen) {
      return;
    }

    FocusScope.of(context).unfocus();

    if (_currentStep == 1) {
      setState(() {
        _currentStep = 2;
      });

      // 가스는 2단계 진입 시 안내
      if (_selectedIssueType == 'Gas') {
        await _showSafetyNotice(SafetyNoticeType.gas);
      }

      return;
    }

    // TODO: 3단계 Location 이동 연결
  }

  Future<void> _showSafetyNotice(SafetyNoticeType type) async {
    if (_isSafetyNoticeOpen) {
      return;
    }

    _isSafetyNoticeOpen = true;

    SafetyNoticeResult? result;

    try {
      result = await showDialog<SafetyNoticeResult>(
        context: context,
        barrierDismissible: false,
        builder: (context) {
          // 바깥 클릭과 시스템 뒤로가기로 닫히지 않도록 설정
          return PopScope(canPop: false, child: SafetyNoticeDialog(type: type));
        },
      );
    } finally {
      _isSafetyNoticeOpen = false;
    }

    if (!mounted) {
      return;
    }

    // Leave는 화면 종료, Continue는 현재 화면 유지
    if (result == SafetyNoticeResult.leave) {
      _leaveCreation();
    }
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
              // 공통 헤더와 진행바
              CaseCreationHeader(
                title: _currentStep == 1 ? 'Issue Type' : 'Specify Issue',
                currentStep: _currentStep,
                totalSteps: 7,
                onBack: _handleBack,
              ),
              const SizedBox(height: 20),

              // 현재 단계에 맞는 입력 화면
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

              // 하단 Next 버튼
              CaseCreationBottom(enabled: _canGoNext, onNext: _handleNext),
            ],
          ),
        ),
      ),
    );
  }
}
