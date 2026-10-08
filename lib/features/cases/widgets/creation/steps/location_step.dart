import 'package:material_ui/material_ui.dart';

import '../../../data/case_creation_options.dart';
import '../case_location_card.dart';

class LocationStep extends StatelessWidget {
  const LocationStep({
    super.key,
    required this.issueSummary,
    required this.selectedLocation,
    required this.onChanged,
    required this.onEdit,
    required this.otherController,
    required this.onOtherChanged,
  });

  final String issueSummary;
  final String? selectedLocation;
  final ValueChanged<String> onChanged;
  final VoidCallback onEdit;
  final TextEditingController otherController;
  final ValueChanged<String> onOtherChanged;

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
          const SizedBox(height: 24),

          // 위치 카드: 3열 배치
          GridView.count(
            crossAxisCount: 3,
            crossAxisSpacing: 14,
            mainAxisSpacing: 18,
            childAspectRatio: 1,
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
          ),

          // Other 선택 시 직접 입력
          if (CaseCreationOptions.requiresOtherLocationInput(
            selectedLocation,
          )) ...[
            const SizedBox(height: 16),
            _buildOtherInput(),
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

  Widget _buildOtherInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Enter the issue location',
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
                hintText: 'e.g. garage',
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
