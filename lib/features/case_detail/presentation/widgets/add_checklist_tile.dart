import 'package:material_ui/material_ui.dart';

import '../case_detail_tokens.dart';
import 'checklist_card_frame.dart';

class AddChecklistTile extends StatelessWidget {
  const AddChecklistTile({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ChecklistCardFrame(
      color: CaseDetailColors.divider,
      onTap: onTap,
      child: const Text(
        '+ add checklist',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: CaseDetailText.checklist,
      ),
    );
  }
}
