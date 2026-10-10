import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:material_ui/material_ui.dart';

import '../../models/case_sort_order.dart';

class CaseSortMenu extends StatefulWidget {
  final CaseSortOrder selectedOrder;
  final ValueChanged<CaseSortOrder> onChanged;

  const CaseSortMenu({
    super.key,
    required this.selectedOrder,
    required this.onChanged,
  });

  @override
  State<CaseSortMenu> createState() => _CaseSortMenuState();
}

class _CaseSortMenuState extends State<CaseSortMenu> {
  bool _isOpen = false;
  bool _isHovered = false;

  void _setOpen(bool value) {
    if (!mounted) return;

    setState(() {
      _isOpen = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final isLight = colors.brightness == Brightness.light;
    final textColor = isLight ? const Color(0xFF243B53) : colors.onSurface;

    return MouseRegion(
      onEnter: (_) {
        setState(() {
          _isHovered = true;
        });
      },
      onExit: (_) {
        setState(() {
          _isHovered = false;
        });
      },
      child: PopupMenuButton<CaseSortOrder>(
        tooltip: 'Sort Cases',
        position: PopupMenuPosition.under,
        offset: const Offset(0, 4),
        padding: EdgeInsets.zero,
        menuPadding: EdgeInsets.zero,
        constraints: BoxConstraints(
          minWidth: 110,
          maxWidth: MediaQuery.sizeOf(context).width,
        ),
        color: isLight ? Colors.white : colors.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 6,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(
            color: isLight ? const Color(0xFFE5E5E5) : colors.outlineVariant,
          ),
        ),
        onOpened: () => _setOpen(true),
        onCanceled: () => _setOpen(false),
        onSelected: (order) {
          if (!mounted) return;

          _setOpen(false);
          widget.onChanged(order);
        },
        itemBuilder: (context) {
          return [
            for (final order in CaseSortOrder.values) ...[
              // Oldest 위에 구분선 표시
              if (order == CaseSortOrder.oldest)
                const PopupMenuDivider(height: 1),

              PopupMenuItem<CaseSortOrder>(
                value: order,
                height: 40,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: Text(
                        order.label,
                        style: TextStyle(
                          color: textColor,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    if (order == widget.selectedOrder)
                      const Icon(
                        LucideIcons.check,
                        color: Color(0xFF007AFF),
                        size: 16,
                      )
                    else
                      const SizedBox(width: 16),
                  ],
                ),
              ),
            ],
          ];
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Text(
                  'Sort by ',
                  style: TextStyle(
                    color: textColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Flexible(
                child: Text(
                  widget.selectedOrder.label,
                  style: TextStyle(
                    color: textColor,
                    fontSize: 13, // 여기만 12 → 13
                    fontWeight: FontWeight.w700,
                    decoration: _isOpen || _isHovered
                        ? TextDecoration.underline
                        : TextDecoration.none,
                    decorationColor: textColor,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Icon(
                _isOpen ? LucideIcons.chevronUp600 : LucideIcons.chevronDown500,
                color: textColor,
                size: 14,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
