import 'package:flutter_svg/flutter_svg.dart';
import 'package:material_ui/material_ui.dart';

import '../../../data/case_creation_options.dart';
import '../other_input_field.dart';

class SpecificIssueStep extends StatefulWidget {
  const SpecificIssueStep({
    super.key,
    required this.issueType,
    required this.selectedIssue,
    required this.onChanged,
    required this.onEdit,
    required this.otherText,
    required this.onOtherChanged,
  });

  final String issueType;
  final String? selectedIssue;
  final ValueChanged<String> onChanged;
  final VoidCallback onEdit;
  final String otherText;
  final ValueChanged<String> onOtherChanged;

  @override
  State<SpecificIssueStep> createState() => _SpecificIssueStepState();
}

class _SpecificIssueStepState extends State<SpecificIssueStep> {
  late final TextEditingController otherController;
  String get issueType => widget.issueType;
  String? get selectedIssue => widget.selectedIssue;
  ValueChanged<String> get onChanged => widget.onChanged;
  VoidCallback get onEdit => widget.onEdit;
  ValueChanged<String> get onOtherChanged => widget.onOtherChanged;
  @override
  void initState() {
    super.initState();
    otherController = TextEditingController(text: widget.otherText);
  }

  @override
  void didUpdateWidget(covariant SpecificIssueStep oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (otherController.text != widget.otherText) {
      otherController.value = TextEditingValue(
        text: widget.otherText,
        selection: TextSelection.collapsed(offset: widget.otherText.length),
      );
    }
  }

  @override
  void dispose() {
    otherController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final options =
        CaseCreationOptions.specificIssues[issueType] ?? const <String>[];
    final iconPath = CaseCreationOptions.issueTypes[issueType];
    final showOtherInput = CaseCreationOptions.requiresOtherInput(
      selectedIssue,
    );

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Specifying Issue',
            style: TextStyle(
              color: Color(0xFF243B53),
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Select the issue that best describes the problem',
            style: TextStyle(
              color: Color(0xFF637381),
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 20),

          // 1단계에서 선택한 문제 유형
          Container(
            width: double.infinity,
            constraints: const BoxConstraints(minHeight: 64),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFF7F7F7),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFF243B53), width: 1.5),
            ),
            child: Row(
              children: [
                if (iconPath != null) ...[
                  SvgPicture.asset(
                    iconPath,
                    width: 40,
                    height: 40,
                    excludeFromSemantics: true,
                  ),
                  const SizedBox(width: 18),
                ],
                Expanded(
                  child: Text(
                    issueType,
                    style: const TextStyle(
                      color: Color(0xFF243B53),
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                TextButton(
                  onPressed: onEdit,
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFF2F80ED),
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    minimumSize: const Size(0, 32),
                    textStyle: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  child: const Text('Edit'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // 세부 이슈: 한 항목만 선택
          Wrap(
            spacing: 8,
            runSpacing: 10,
            children: [
              for (final option in options)
                _SpecificIssueChip(
                  label: option,
                  selected: selectedIssue == option,
                  hasSelection: selectedIssue != null,
                  onTap: () => onChanged(option),
                ),
            ],
          ),

          // Other 선택 시 직접 입력
          if (showOtherInput) ...[
            const SizedBox(height: 24),
            OtherInputField(
              controller: otherController,
              onChanged: onOtherChanged,
              hintText: issueType == 'Water & Flooding'
                  ? 'e.g. Rainwater coming in'
                  : 'Describe the issue',
            ),
          ],
        ],
      ),
    );
  }
}

class _SpecificIssueChip extends StatelessWidget {
  const _SpecificIssueChip({
    required this.label,
    required this.selected,
    required this.hasSelection,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final bool hasSelection;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      child: Material(
        color: const Color(0xFFF7F7F7),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(100),
          side: BorderSide(
            color: selected ? const Color(0xFF243B53) : const Color(0xFFE3E3E3),
            width: selected ? 1.5 : 1,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Text(
              label,
              style: TextStyle(
                color: selected || !hasSelection
                    ? const Color(0xFF243B53)
                    : const Color(0xFFA6A6A6),
                fontSize: 14,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
