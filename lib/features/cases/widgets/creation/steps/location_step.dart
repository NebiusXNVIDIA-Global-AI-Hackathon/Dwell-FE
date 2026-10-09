import 'package:material_ui/material_ui.dart';

import '../../../data/case_creation_options.dart';
import '../case_creation_summary_row.dart';
import '../case_creation_text_input.dart';
import '../case_location_card.dart';

class LocationStep extends StatefulWidget {
  const LocationStep({
    super.key,
    required this.issueSummary,
    required this.selectedLocation,
    required this.onChanged,
    required this.onEdit,
    required this.otherText,
    required this.onOtherChanged,
  });

  final String issueSummary;
  final String? selectedLocation;
  final ValueChanged<String> onChanged;
  final VoidCallback onEdit;
  final String otherText;
  final ValueChanged<String> onOtherChanged;

  @override
  State<LocationStep> createState() => _LocationStepState();
}

class _LocationStepState extends State<LocationStep> {
  late final TextEditingController otherController;
  String get issueSummary => widget.issueSummary;
  String? get selectedLocation => widget.selectedLocation;
  ValueChanged<String> get onChanged => widget.onChanged;
  VoidCallback get onEdit => widget.onEdit;
  ValueChanged<String> get onOtherChanged => widget.onOtherChanged;
  @override
  void initState() {
    super.initState();
    otherController = TextEditingController(text: widget.otherText);
  }

  @override
  void didUpdateWidget(covariant LocationStep oldWidget) {
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
            'Where is the issue?',
            style: TextStyle(
              color: Color(0xFF243B53),
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Select the issue location',
            style: TextStyle(
              color: Color(0xFF627381),
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),

          // 선택한 문제 정보
          CaseCreationSummaryRow(
            stepNumber: 1,
            value: issueSummary,
            onEdit: onEdit,
          ),
          const SizedBox(height: 24),

          // 위치 카드: 3열 배치
          LayoutBuilder(
            builder: (context, constraints) {
              final cardWidth = (constraints.maxWidth - 14 * 2) / 3;
              var cardHeight = cardWidth;
              // Keep square cards when labels fit. Measure both font weights
              // so choosing a card does not change the grid height.
              for (final label in CaseCreationOptions.locations.keys) {
                for (final weight in [FontWeight.w600, FontWeight.w700]) {
                  final painter = TextPainter(
                    text: TextSpan(
                      text: label,
                      style: DefaultTextStyle.of(context).style.merge(
                        TextStyle(
                          fontSize: 16,
                          fontWeight: weight,
                          height: 1.2,
                        ),
                      ),
                    ),
                    textDirection: Directionality.of(context),
                    textScaler: MediaQuery.textScalerOf(context),
                    locale: Localizations.maybeLocaleOf(context),
                  )..layout(maxWidth: cardWidth - 8);
                  // Icon (32), gap (8), and vertical padding (16).
                  final requiredHeight = 56 + painter.height;
                  if (requiredHeight > cardHeight) cardHeight = requiredHeight;
                  painter.dispose();
                }
              }
              return GridView.count(
                crossAxisCount: 3,
                crossAxisSpacing: 14,
                mainAxisSpacing: 18,
                mainAxisExtent: cardHeight,
                shrinkWrap: true,
                primary: false,
                padding: EdgeInsets.zero,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  for (final entry in CaseCreationOptions.locations.entries)
                    CaseLocationCard(
                      label: entry.key,
                      icon: entry.value,
                      selected: selectedLocation == entry.key,
                      hasSelection: selectedLocation != null,
                      onTap: () => onChanged(entry.key),
                    ),
                ],
              );
            },
          ),

          // Other 선택 시 직접 입력
          if (CaseCreationOptions.requiresOtherLocationInput(
            selectedLocation,
          )) ...[
            const SizedBox(height: 16),
            CaseCreationTextInput(
              label: 'Enter the issue location',
              controller: otherController,
              onChanged: onOtherChanged,
              hintText: 'e.g. garage',
            ),
          ],

          // Entire Unit 선택 시 단계 생략 안내
          if (CaseCreationOptions.skipsAffectedArea(selectedLocation)) ...[
            const SizedBox(height: 18),
            _buildEntireUnitNotice(),
          ],
        ],
      ),
    );
  }

  Widget _buildEntireUnitNotice() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFEEF4FD),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFC4D7F5)),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info, size: 24, color: Color(0xFF007AFF)),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "We'll skip Step 4 · Affected Area",
                  style: TextStyle(
                    color: Color(0xFF243B53),
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    height: 1.3,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  "Entire Unit covers the whole home, so there's "
                  "no specific area to pick. Next, you'll go straight "
                  'to Step 5 · Add Evidence.',
                  style: TextStyle(
                    color: Color(0xFF637381),
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
