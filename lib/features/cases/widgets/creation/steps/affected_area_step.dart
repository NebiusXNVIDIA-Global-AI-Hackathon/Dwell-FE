import 'package:material_ui/material_ui.dart';

import '../../../data/case_creation_options.dart';
import '../case_area_card.dart';

class AffectedAreaStep extends StatefulWidget {
  const AffectedAreaStep({
    super.key,
    required this.issueSummary,
    required this.location,
    required this.locationSummary,
    required this.onEditLocation,
    required this.selectedArea,
    required this.onChanged,
    required this.onEdit,
    required this.otherText,
    required this.onOtherChanged,
  });

  final String issueSummary;
  final String location;
  final String locationSummary;
  final VoidCallback onEditLocation;
  final String? selectedArea;
  final ValueChanged<String> onChanged;
  final VoidCallback onEdit;
  final String otherText;
  final ValueChanged<String> onOtherChanged;

  @override
  State<AffectedAreaStep> createState() => _AffectedAreaStepState();
}

class _AffectedAreaStepState extends State<AffectedAreaStep> {
  late final TextEditingController otherController;
  String get issueSummary => widget.issueSummary;
  String get location => widget.location;
  String get locationSummary => widget.locationSummary;
  String? get selectedArea => widget.selectedArea;
  ValueChanged<String> get onChanged => widget.onChanged;
  VoidCallback get onEdit => widget.onEdit;
  ValueChanged<String> get onOtherChanged => widget.onOtherChanged;
  @override
  void initState() {
    super.initState();
    otherController = TextEditingController(text: widget.otherText);
  }

  @override
  void didUpdateWidget(covariant AffectedAreaStep oldWidget) {
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
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'What exactly is the issue',
            style: TextStyle(
              color: Color(0xFF243B53),
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Select affected area',
            style: TextStyle(
              color: Color(0xFF627381),
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),

          // 선택한 문제 정보
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  color: Color(0xFF243B53),
                  shape: BoxShape.circle,
                ),
                child: const Text(
                  '1',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  issueSummary,
                  style: const TextStyle(
                    color: Color(0xFF243B53),
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              TextButton(
                onPressed: onEdit,
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFF007AFF),
                  minimumSize: const Size(0, 32),
                  padding: EdgeInsets.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  textStyle: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                child: const Text('Edit'),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  color: Color(0xFF243B53),
                  shape: BoxShape.circle,
                ),
                child: const Text(
                  '2',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  "$locationSummary - ${CaseCreationOptions.requiresOtherAffectedAreaInput(selectedArea) ? widget.otherText.trim() : selectedArea ?? ''}",
                  style: const TextStyle(
                    color: Color(0xFF243B53),
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              TextButton(
                onPressed: widget.onEditLocation,
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFF007AFF),
                  minimumSize: const Size(0, 32),
                  padding: EdgeInsets.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  textStyle: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                child: const Text('Edit'),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // 위치 카드: 3열 배치
          LayoutBuilder(
            builder: (context, constraints) {
              const spacing = 8.0;
              final cardWidth = (constraints.maxWidth - spacing * 3) / 4;
              return Wrap(
                spacing: spacing,
                runSpacing: 18,
                children: [
                  for (final entry
                      in (CaseCreationOptions.affectedAreas[location] ??
                              CaseCreationOptions.affectedAreas['Other']!)
                          .entries)
                    SizedBox(
                      width: cardWidth,
                      child: CaseAreaCard(
                        label: entry.key,
                        iconPath: entry.value,
                        selected: selectedArea == entry.key,
                        onTap: () => onChanged(entry.key),
                      ),
                    ),
                ],
              );
            },
          ),

          // Other 선택 시 직접 입력
          if (CaseCreationOptions.requiresOtherAffectedAreaInput(
            selectedArea,
          )) ...[
            const SizedBox(height: 16),
            _buildOtherInput(),
          ],
        ],
      ),
    );
  }

  Widget _buildOtherInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Enter the affected area',
          style: TextStyle(
            color: Color(0xFF243B53),
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 10),
        ValueListenableBuilder<TextEditingValue>(
          valueListenable: otherController,
          builder: (context, value, child) {
            return TextField(
              controller: otherController,
              onChanged: onOtherChanged,
              maxLength: 50,
              maxLines: 1,
              style: const TextStyle(
                color: Colors.black,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
              decoration: InputDecoration(
                hintText: 'Describe the affected area',
                hintStyle: const TextStyle(
                  color: Color(0xFFA6A6A6),
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 12,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Color(0xFFA6A6A6)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(
                    color: Color(0xFF007AFF),
                    width: 1.5,
                  ),
                ),
                counterStyle: const TextStyle(
                  color: Color(0xFFA6A6A6),
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                ),
                suffixIcon: value.text.isEmpty
                    ? null
                    : IconButton(
                        tooltip: 'Clear',
                        onPressed: () {
                          otherController.clear();
                          onOtherChanged('');
                        },
                        icon: const Icon(
                          Icons.cancel,
                          size: 20,
                          color: Color(0xFFA6A6A6),
                        ),
                      ),
              ),
            );
          },
        ),
      ],
    );
  }
}
