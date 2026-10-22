import 'package:material_ui/material_ui.dart';

import '../../../../core/theme.dart';
import '../case_detail_tokens.dart';

class CaseSectionHeader extends StatelessWidget {
  const CaseSectionHeader({super.key, required this.title, this.trailing});

  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: CaseDetailText.sectionTitle,
          ),
        ),
        if (trailing != null) ...[const SizedBox(width: Gap.sm), trailing!],
      ],
    );
  }
}

/// Text button that shows an underline when active or pressed.
class CaseTextLink extends StatefulWidget {
  const CaseTextLink({
    super.key,
    required this.label,
    required this.onTap,
    this.trailingIcon,
    this.active = false,
  });

  final String label;
  final VoidCallback onTap;
  final IconData? trailingIcon;
  final bool active;

  @override
  State<CaseTextLink> createState() => _CaseTextLinkState();
}

class _CaseTextLinkState extends State<CaseTextLink> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (_pressed != value) setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final underlined = widget.active || _pressed;

    return Semantics(
      button: true,
      selected: widget.active,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => _setPressed(true),
        onTapCancel: () => _setPressed(false),
        onTapUp: (_) => _setPressed(false),
        onTap: widget.onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: Gap.xs),
          child: DecoratedBox(
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: underlined
                      ? CaseDetailColors.body
                      : Colors.transparent,
                ),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(widget.label, style: CaseDetailText.link),
                if (widget.trailingIcon case final icon?) ...[
                  const SizedBox(width: Gap.xs),
                  Icon(
                    icon,
                    size: CaseDetailSizes.linkIcon,
                    color: CaseDetailColors.body,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
