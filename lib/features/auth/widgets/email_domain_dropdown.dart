import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:material_ui/material_ui.dart';

class EmailDomainDropdown extends StatefulWidget {
  const EmailDomainDropdown({
    super.key,
    required this.value,
    required this.onChanged,
    this.enabled = true,
    this.options = domains,
    this.showSelectionMark = false,
    this.semanticLabel = 'Choose email domain',
    this.controlKey = const ValueKey('email-domain'),
    this.maxMenuHeight,
    this.optionNames = const {},
  });
  final String? value;
  final ValueChanged<String> onChanged;
  final bool enabled;
  final List<String> options;
  final bool showSelectionMark;
  final String semanticLabel;
  final Key controlKey;
  final double? maxMenuHeight;
  final Map<String, String> optionNames;
  static const domains = ['naver.com', 'daum.net', 'google.com'];

  @override
  State<EmailDomainDropdown> createState() => _EmailDomainDropdownState();
}

class _EmailDomainDropdownState extends State<EmailDomainDropdown> {
  final _menu = MenuController();
  final _focus = FocusNode(debugLabel: 'Email domain');
  bool _open = false;

  @override
  void didUpdateWidget(covariant EmailDomainDropdown oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!widget.enabled && _menu.isOpen) _menu.close();
  }

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final width = constraints.maxWidth;
      return MenuAnchor(
        controller: _menu,
        childFocusNode: _focus,
        useRootOverlay: true,
        consumeOutsideTap: true,
        crossAxisUnconstrained: false,
        onOpen: () => setState(() => _open = true),
        onClose: () {
          if (mounted) setState(() => _open = false);
        },
        style: MenuStyle(
          alignment: Alignment.bottomLeft,
          fixedSize: WidgetStatePropertyAll(Size.fromWidth(width)),
          maximumSize: widget.maxMenuHeight == null
              ? null
              : WidgetStatePropertyAll(Size(width, widget.maxMenuHeight!)),
          padding: const WidgetStatePropertyAll(EdgeInsets.zero),
          backgroundColor: const WidgetStatePropertyAll(Color(0xFFFCFCFC)),
          surfaceTintColor: const WidgetStatePropertyAll(Colors.transparent),
          side: const WidgetStatePropertyAll(
            BorderSide(color: Color(0xFF666666)),
          ),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          elevation: const WidgetStatePropertyAll(0),
        ),
        menuChildren: [
          for (final domain in widget.options) ...[
            if (domain != widget.options.first)
              const Divider(height: 1, color: Color(0xFFAAAAAA)),
            MenuItemButton(
              semanticsLabel: widget.optionNames[domain] == null
                  ? domain
                  : '$domain, ${widget.optionNames[domain]}',
              trailingIcon: widget.showSelectionMark && domain == widget.value
                  ? const Icon(
                      LucideIcons.check,
                      size: 16,
                      color: Color(0xFF0065F3),
                    )
                  : null,
              onPressed: () {
                _menu.close();
                widget.onChanged(domain);
              },
              style: const ButtonStyle(
                minimumSize: WidgetStatePropertyAll(Size(0, 44)),
                padding: WidgetStatePropertyAll(
                  EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                ),
                foregroundColor: WidgetStatePropertyAll(Color(0xFF606060)),
                textStyle: WidgetStatePropertyAll(
                  TextStyle(fontFamily: 'Pretendard Variable', fontSize: 16),
                ),
                overlayColor: WidgetStatePropertyAll(Colors.transparent),
                splashFactory: NoSplash.splashFactory,
              ),
              child: Text(domain, softWrap: true),
            ),
          ],
        ],
        builder: (_, _, _) => Semantics(
          expanded: _open,
          child: OutlinedButton(
            key: widget.controlKey,
            focusNode: _focus,
            onPressed: widget.enabled
                ? () {
                    _menu.isOpen ? _menu.close() : _menu.open();
                  }
                : null,
            style:
                OutlinedButton.styleFrom(
                  minimumSize: const Size(0, 56),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 12,
                  ),
                  foregroundColor: const Color(0xFF606060),
                  backgroundColor: const Color(0xFFFCFCFC),
                  side: const BorderSide(color: Color(0xFF666666)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  splashFactory: NoSplash.splashFactory,
                ).copyWith(
                  overlayColor: const WidgetStatePropertyAll(
                    Colors.transparent,
                  ),
                ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    widget.value ?? '',
                    style: const TextStyle(fontSize: 16),
                    softWrap: true,
                  ),
                ),
                Icon(
                  _open ? LucideIcons.chevronDown : LucideIcons.chevronUp,
                  size: 18,
                  semanticLabel: widget.semanticLabel,
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}
