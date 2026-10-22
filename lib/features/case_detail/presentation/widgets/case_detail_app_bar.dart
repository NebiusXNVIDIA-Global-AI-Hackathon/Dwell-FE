import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:material_ui/material_ui.dart';

import '../case_detail_tokens.dart';

class CaseDetailAppBar extends StatelessWidget {
  const CaseDetailAppBar({
    super.key,
    required this.title,
    required this.onBack,
    this.trailing,
  });

  final String title;
  final VoidCallback onBack;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        CaseDetailSizes.appBarStart,
        CaseDetailSizes.appBarTop,
        CaseDetailSizes.appBarEnd,
        0,
      ),
      child: Row(
        children: [
          _BackButton(onTap: onBack),
          const SizedBox(width: CaseDetailSizes.appBarEnd),
          Expanded(
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: CaseDetailText.appBarTitle,
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }
}

class _BackButton extends StatelessWidget {
  const _BackButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(CaseDetailSizes.backRadius);

    return Semantics(
      button: true,
      label: 'Back',
      child: Material(
        color: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: radius,
          side: const BorderSide(color: CaseDetailColors.divider),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: const SizedBox.square(
            dimension: CaseDetailSizes.backButton,
            child: Icon(
              LucideIcons.chevronLeft,
              size: CaseDetailSizes.backIcon,
              color: CaseDetailColors.body,
            ),
          ),
        ),
      ),
    );
  }
}
