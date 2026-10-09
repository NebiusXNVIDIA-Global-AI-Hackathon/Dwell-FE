import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../controllers/evidence_controller.dart';
import '../services/evidence_library.dart';
import 'evidence/evidence_camera_page.dart';

import 'package:material_ui/material_ui.dart';

import '../controllers/case_creation_controller.dart';
import 'evidence_guide_page.dart';
import '../widgets/creation/steps/evidence_step.dart';
import '../widgets/creation/evidence/evidence_add_sheet.dart';
import '../widgets/creation/steps/affected_area_step.dart';
import '../widgets/creation/case_creation_bottom.dart';
import '../widgets/creation/case_creation_header.dart';
import '../widgets/creation/dialogs/case_exit_dialog.dart';
import '../widgets/creation/dialogs/safety_notice_dialog.dart';
import '../widgets/creation/steps/issue_type_step.dart';
import '../widgets/creation/steps/location_step.dart';
import '../widgets/creation/steps/specific_issue_step.dart';

class CaseCreationPage extends ConsumerStatefulWidget {
  const CaseCreationPage({super.key});

  @override
  ConsumerState<CaseCreationPage> createState() => _CaseCreationPageState();
}

class _CaseCreationPageState extends ConsumerState<CaseCreationPage> {
  final _controller = CaseCreationController();
  final _evidence = EvidenceController();

  @override
  void dispose() {
    for (final item in _evidence.items) {
      MemoryImage(item.bytes).evict();
    }
    _evidence.dispose();
    super.dispose();
  }

  int get _currentStep => _controller.currentStep;
  String? get _selectedIssueType => _controller.draft.issueType;
  String? get _selectedSpecificIssue => _controller.draft.specificIssue;
  String? get _selectedLocation => _controller.draft.location;
  String get _issueSummary => _controller.issueSummary;
  bool get _canGoNext => _controller.canGoNext;

  // 안내 페이지 및 모달 중복 표시 방지
  bool _isEvidenceGuideOpen = false;
  bool _isEvidenceSheetOpen = false;
  bool _isLibraryPickerOpen = false;
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
      case 5:
        return 'Add Evidence';
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

  Future<void> _showEvidenceSheet() async {
    if (_isEvidenceSheetOpen ||
        _isLibraryPickerOpen ||
        _isExitNoticeOpen ||
        _allowLeave) {
      return;
    }
    setState(() => _isEvidenceSheetOpen = true);
    try {
      final source = await showModalBottomSheet<EvidenceSource>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        backgroundColor: Colors.white,
        barrierColor: Colors.black.withValues(alpha: 0.2),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        clipBehavior: Clip.antiAlias,
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.85,
        ),
        builder: (context) => EvidenceAddSheet(
          onSelected: (source) {
            if (ModalRoute.of(context)?.isCurrent != true) return;
            Navigator.of(context).pop(source);
          },
        ),
      );
      if (!mounted) return;
      setState(() => _isEvidenceSheetOpen = false);
      if (source == EvidenceSource.photo) {
        final photo = await ref.read(evidenceCameraLauncherProvider)(context);
        if (mounted && photo != null) _evidence.add(photo);
      } else if (source == EvidenceSource.library) {
        await _pickLibraryPhotos();
      }
    } finally {
      if (mounted) setState(() => _isEvidenceSheetOpen = false);
    }
  }

  Future<void> _pickLibraryPhotos() async {
    if (_isLibraryPickerOpen || _allowLeave) return;
    _isLibraryPickerOpen = true;
    try {
      final result = await ref.read(evidenceLibraryPickerProvider)();
      if (!mounted || _allowLeave) return;
      for (final photo in result.photos) {
        _evidence.add(photo);
      }
      if (result.failedCount > 0) {
        _showLibraryMessage(
          'Some photos could not be added. Choose readable JPEG, PNG or WebP photos.',
        );
      }
    } catch (error) {
      if (mounted && !_allowLeave) {
        _showLibraryMessage(evidenceLibraryErrorMessage(error));
      }
    } finally {
      _isLibraryPickerOpen = false;
    }
  }

  void _showLibraryMessage(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _handleNext() async {
    if (!_canGoNext ||
        _isEvidenceGuideOpen ||
        _isSafetyNoticeOpen ||
        _isExitNoticeOpen ||
        _allowLeave) {
      return;
    }

    FocusScope.of(context).unfocus();

    if (_controller.canOpenEvidenceGuide) {
      _isEvidenceGuideOpen = true;
      try {
        final route = MaterialPageRoute<bool>(
          builder: (_) => const EvidenceGuidePage(),
        );
        final start = await Navigator.of(context).push<bool>(route);
        if (mounted && start == true) setState(_controller.beginEvidence);
        await route.completed;
      } finally {
        _isEvidenceGuideOpen = false;
      }
      return;
    }

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

      case 5:
        return EvidenceStep(
          onAdd: _showEvidenceSheet,
          isSheetOpen: _isEvidenceSheetOpen,
          evidence: _evidence,
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
            // SafeArea handles system insets; keep the design gap consistent.
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
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
                CaseCreationBottom(
                  enabled: _canGoNext,
                  onNext: _handleNext,
                  label: _currentStep == 5 ? 'Check' : 'Next',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
