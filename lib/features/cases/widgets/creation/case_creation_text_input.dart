import 'package:material_ui/material_ui.dart';

class CaseCreationTextInput extends StatelessWidget {
  const CaseCreationTextInput({
    super.key,
    required this.label,
    required this.controller,
    required this.onChanged,
    required this.hintText,
  });

  final String label;
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final String hintText;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF243B53),
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 10),
        ValueListenableBuilder<TextEditingValue>(
          valueListenable: controller,
          builder: (context, value, child) {
            return TextField(
              controller: controller,
              onChanged: onChanged,
              maxLength: 50,
              maxLines: 1,
              style: const TextStyle(
                color: Colors.black,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
              decoration: InputDecoration(
                hintText: hintText,
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
                          controller.clear();
                          onChanged('');
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
