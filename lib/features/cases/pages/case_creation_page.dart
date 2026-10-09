import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../controllers/case_creation_controller.dart';
import '../widgets/creation/steps/affected_area_step.dart';
import '../widgets/creation/case_creation_bottom.dart';
import '../widgets/creation/case_creation_header.dart';
import '../widgets/creation/dialogs/case_exit_dialog.dart';
import '../widgets/creation/dialogs/safety_notice_dialog.dart';
import '../widgets/creation/steps/issue_type_step.dart';
import '../widgets/creation/steps/location_step.dart';
import '../widgets/creation/steps/specific_issue_step.dart';

class CaseCreationPage extends StatefulWidget {
  const CaseCreationPage({super.key});

  @override
  State<CaseCreationPage> createState() => _CaseCreationPageState();
}

class _CaseCreationPageState extends State<CaseCreationPage> {
  final _controller = CaseCreationController();
  int get _currentStep => _controller.currentStep;
  String? get _selectedIssueType => _controller.draft.issueType;
  String? get _selectedSpecificIssue => _controller.draft.specificIssue;
  String? get _selectedLocation => _controller.draft.location;
  String get _issueSummary => _controller.issueSummary;
  bool get _canGoNext => _controller.canGoNext;

  // 모달 중복 표시 방지
  bool _isSafetyNoticeOpen = false;
  bool _isExitNoticeOpen = false;

  // Leave 선택 후 페이지 종료 허용
  bool _allowLeave = false;

  // 단계별 헤더 제목
  String get _stepTitle {
    switch (_currentStep) {
      case 1:
        return 'Issue Type';
      case 2:
        return 'Specify Issue';
      case 3:
        return 'Issue Location';
      case 4:
        return 'Affected Area';
      default:
        return 'New Case';
    }
  }

  void _handleIssueTypeChanged(String value) {
    setState(() => _controller.selectIssueType(value));
  }

  Future<void> _handleSpecificIssueChanged(String value) async {
    if (_isSafetyNoticeOpen || _isExitNoticeOpen || _allowLeave) {
      return;
    }

    FocusScope.of(context).unfocus();

    setState(() => _controller.selectSpecificIssue(value));

    // 위험한 전기 항목 선택 시 안내
    if (_selectedIssueType == 'Electricity' &&
        (value == 'Exposed Wiring' || value == 'Sparks / Burning Smell')) {
      await _showSafetyNotice(SafetyNoticeType.electrical);
    } else if (_selectedIssueType == 'Water & Flooding' &&
        value == 'Flooding') {
      await _showSafetyNotice(SafetyNoticeType.flooding);
    }
  }

  void _handleOtherIssueChanged(String value) {
    setState(() => _controller.setOtherIssue(value));
  }

  void _handleLocationChanged(String value) {
    FocusScope.of(context).unfocus();
    setState(() => _controller.selectLocation(value));
  }

  void _handleOtherLocationChanged(String value) {
    setState(() => _controller.setOtherLocation(value));
  }

  void _handleEdit() {
    FocusScope.of(context).unfocus();
    setState(_controller.editIssue);
  }

  void _handleEditLocation() {
    FocusScope.of(context).unfocus();
    setState(_controller.editLocation);
  }

  void _handleAreaChanged(String value) {
    FocusScope.of(context).unfocus();
    setState(() => _controller.selectAffectedArea(value));
  }

  void _handleOtherAreaChanged(String value) {
    setState(() => _controller.setOtherAffectedArea(value));
  }

  Future<void> _handleBack() async {
    if (_isExitNoticeOpen || _isSafetyNoticeOpen || _allowLeave) {
      return;
    }

    FocusScope.of(context).unfocus();
    _isExitNoticeOpen = true;

    CaseExitResult? result;

    try {
      result = await showDialog<CaseExitResult>(
        context: context,
        barrierDismissible: false,
        builder: (context) {
          return const PopScope<CaseExitResult>(
            canPop: false,
            child: CaseExitDialog(),
          );
        },
      );
    } finally {
      _isExitNoticeOpen = false;
    }

    if (!mounted) {
      return;
    }

    // Stay는 현재 화면 유지, Leave는 등록 화면 종료
    if (result == CaseExitResult.leave) {
      await _leaveCreation();
    }
  }

  Future<void> _leaveCreation() async {
    if (!mounted || _allowLeave) {
      return;
    }

    setState(() {
      _allowLeave = true;
    });

    // 종료 허용 상태가 화면에 반영된 뒤 이동
    await WidgetsBinding.instance.endOfFrame;

    if (!mounted) {
      return;
    }

    if (context.canPop()) {
      context.pop();
    } else {
      context.goNamed('cases');
    }
  }

  Future<void> _handleNext() async {
    if (!_canGoNext ||
        _isSafetyNoticeOpen ||
        _isExitNoticeOpen ||
        _allowLeave) {
      return;
    }

    FocusScope.of(context).unfocus();

    final previousStep = _currentStep;
    setState(_controller.next);
    if (previousStep == 1 && _currentStep == 2 && _selectedIssueType == 'Gas') {
      await _showSafetyNotice(SafetyNoticeType.gas);
    }
  }

  Future<void> _showSafetyNotice(SafetyNoticeType type) async {
    if (_isSafetyNoticeOpen || _isExitNoticeOpen || _allowLeave) {
      return;
    }

    _isSafetyNoticeOpen = true;

    SafetyNoticeResult? result;

    try {
      result = await showDialog<SafetyNoticeResult>(
        context: context,
        barrierDismissible: false,
        builder: (context) {
          return PopScope<SafetyNoticeResult>(
            canPop: false,
            child: SafetyNoticeDialog(type: type),
          );
        },
      );
    } finally {
      _isSafetyNoticeOpen = false;
    }

    if (!mounted) {
      return;
    }

    // 안전 안내의 Leave는 추가 확인 없이 화면 종료
    if (result == SafetyNoticeResult.leave) {
      await _leaveCreation();
    }
  }

  // 현재 단계에 맞는 입력 화면
  Widget _buildStep() {
    switch (_currentStep) {
      case 1:
        return IssueTypeStep(
          selectedIssueType: _selectedIssueType,
          onChanged: _handleIssueTypeChanged,
        );

      case 2:
        return SpecificIssueStep(
          issueType: _selectedIssueType!,
          selectedIssue: _selectedSpecificIssue,
          onChanged: _handleSpecificIssueChanged,
          onEdit: _handleEdit,
          otherText: _controller.draft.otherIssue,
          onOtherChanged: _handleOtherIssueChanged,
        );

      case 3:
        return LocationStep(
          issueSummary: _issueSummary,
          selectedLocation: _selectedLocation,
          onChanged: _handleLocationChanged,
          onEdit: _handleEdit,
          otherText: _controller.draft.otherLocation,
          onOtherChanged: _handleOtherLocationChanged,
        );

      case 4:
        return AffectedAreaStep(
          issueSummary: _issueSummary,
          location: _selectedLocation!,
          locationSummary: _controller.locationSummary,
          selectedArea: _controller.draft.affectedArea,
          onChanged: _handleAreaChanged,
          onEdit: _handleEdit,
          onEditLocation: _handleEditLocation,
          otherText: _controller.draft.otherAffectedArea,
          onOtherChanged: _handleOtherAreaChanged,
        );

      default:
        return const SizedBox.shrink();
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope<Object?>(
      canPop: _allowLeave,
      onPopInvokedWithResult: (didPop, result) {
        // 시스템 뒤로가기 시에도 중도 이탈 확인
        if (!didPop) {
          _handleBack();
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF7F7F7),
        body: SafeArea(
          child: Padding(
            // Leave room for scrollable inputs when the keyboard is open.
            padding: EdgeInsets.fromLTRB(
              20,
              MediaQuery.viewInsetsOf(context).bottom > 0 ? 20 : 60,
              20,
              24,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 공통 헤더와 진행바
                CaseCreationHeader(
                  title: _stepTitle,
                  currentStep: _currentStep,
                  totalSteps: CaseCreationController.totalSteps,
                  onBack: _handleBack,
                ),
                const SizedBox(height: 20),

                // 단계별 입력 화면
                Expanded(child: _buildStep()),
                const SizedBox(height: 16),

                // 하단 Next 버튼
                CaseCreationBottom(enabled: _canGoNext, onNext: _handleNext),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
