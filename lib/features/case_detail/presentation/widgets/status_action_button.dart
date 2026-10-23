import 'package:material_ui/material_ui.dart';

import '../case_detail_tokens.dart';

/// Pill button on the Current Status banner; the color follows the stage tone.
class StatusActionButton extends StatelessWidget {
  const StatusActionButton({
    super.key,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color,
      shape: const StadiumBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          height: CaseDetailSizes.noticeButtonHeight,
          child: Center(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: CaseDetailText.noticeButton,
            ),
          ),
        ),
      ),
    );
  }
}
