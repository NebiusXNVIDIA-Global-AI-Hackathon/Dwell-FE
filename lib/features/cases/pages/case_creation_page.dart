import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../data/case_creation_options.dart';
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
  // 현재 단계와 선택한 정보
  int _currentStep = 1;
  String? _selectedIssueType;
  String? _selectedSpecificIssue;
  String? _selectedLocation;

  // 모달 중복 표시 방지
  bool _isSafetyNoticeOpen = false;
  bool _isExitNoticeOpen = false;

  // Leave 선택 후 페이지 종료 허용
  bool _allowLeave = false;

  // 문제와 위치의 직접 입력을 각각 관리
  final TextEditingController _otherIssueController = TextEditingController();
  final TextEditingController _otherLocationController =
      TextEditingController();

  // 단계별 헤더 제목
  String get _stepTitle {
    switch (_currentStep) {
      case 1:
        return 'Issue Type';
      case 2:
        return 'Specify Issue';
      case 3:
        return 'Issue Location';
      default:
        return 'New Case';
    }
  }

  // Other 문제는 입력한 내용을 요약에 표시
  String get _issueSummary {
    final specificIssue =
        CaseCreationOptions.requiresOtherInput(_selectedSpecificIssue)
        ? _otherIssueController.text.trim()
        : _selectedSpecificIssue ?? '';

    return '${_selectedIssueType ?? ''} - $specificIssue';
  }

  // 단계별 Next 버튼 활성화 조건
  bool get _canGoNext {
    switch (_currentStep) {
      case 1:
        return _selectedIssueType != null;

      case 2:
        if (_selectedSpecificIssue == null) {
          return false;
        }

        if (CaseCreationOptions.requiresOtherInput(_selectedSpecificIssue)) {
          return _otherIssueController.text.trim().isNotEmpty;
        }

        return true;

      case 3:
        if (_selectedLocation == null) {
          return false;
        }

        if (CaseCreationOptions.requiresOtherLocationInput(_selectedLocation)) {
          return _otherLocationController.text.trim().isNotEmpty;
        }

        return true;

      default:
        return false;
    }
  }

  // 문제 정보 변경 시 이후 위치 정보 초기화
  void _resetLocation() {
    _selectedLocation = null;
    _otherLocationController.clear();
  }

  void _handleIssueTypeChanged(String value) {
    setState(() {
      if (_selectedIssueType != value) {
        _selectedSpecificIssue = null;
        _otherIssueController.clear();
        _resetLocation();
      }

      _selectedIssueType = value;
    });
  }

  Future<void> _handleSpecificIssueChanged(String value) async {
    if (_isSafetyNoticeOpen || _isExitNoticeOpen || _allowLeave) {
      return;
    }

    FocusScope.of(context).unfocus();

    setState(() {
      if (_selectedSpecificIssue != value) {
        _resetLocation();
      }

      _selectedSpecificIssue = value;
    });

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
    setState(() {});
  }

  void _handleLocationChanged(String value) {
    FocusScope.of(context).unfocus();

    setState(() {
      _selectedLocation = value;
    });
  }

  void _handleOtherLocationChanged(String value) {
    setState(() {});
  }

  void _handleEdit() {
    FocusScope.of(context).unfocus();

    // 기존 선택을 유지하며 문제 유형 수정
    setState(() {
      _currentStep = 1;
    });
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

    switch (_currentStep) {
      case 1:
        setState(() {
          _currentStep = 2;
        });

        // 가스는 2단계 진입 시 안내
        if (_selectedIssueType == 'Gas') {
          await _showSafetyNotice(SafetyNoticeType.gas);
        }

        return;

      case 2:
        // 세부 문제 선택 후 위치 선택으로 이동
        setState(() {
          _currentStep = 3;
        });

        return;

      case 3:
        if (CaseCreationOptions.skipsAffectedArea(_selectedLocation)) {
          // TODO: Entire Unit은 5단계 Add Evidence로 이동
          return;
        }

        // TODO: 일반 위치는 4단계 Affected Area로 이동
        return;
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
          otherController: _otherIssueController,
          onOtherChanged: _handleOtherIssueChanged,
        );

      case 3:
        return LocationStep(
          issueSummary: _issueSummary,
          selectedLocation: _selectedLocation,
          onChanged: _handleLocationChanged,
          onEdit: _handleEdit,
          otherController: _otherLocationController,
          onOtherChanged: _handleOtherLocationChanged,
        );

      default:
        return const SizedBox.shrink();
    }
  }

  @override
  void dispose() {
    _otherIssueController.dispose();
    _otherLocationController.dispose();
    super.dispose();
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
            padding: const EdgeInsets.fromLTRB(20, 60, 20, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 공통 헤더와 진행바
                CaseCreationHeader(
                  title: _stepTitle,
                  currentStep: _currentStep,
                  totalSteps: 7,
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
