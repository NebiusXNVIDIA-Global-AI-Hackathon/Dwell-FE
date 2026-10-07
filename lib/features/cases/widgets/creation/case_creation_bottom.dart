import 'package:dwell/core/widgets/primary_action_button.dart';
import 'package:material_ui/material_ui.dart';

class CaseCreationBottom extends StatelessWidget {
  const CaseCreationBottom({
    super.key,
    required this.enabled,
    required this.onNext,
    this.label = 'Next',
  });

  final bool enabled;
  final VoidCallback? onNext;
  final String label;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: PrimaryActionButton(
        label: label,
        enabled: enabled,
        onPressed: onNext,
      ),
    );
  }
}
