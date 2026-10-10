import 'package:material_ui/material_ui.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class CaseSearchField extends StatelessWidget {
  final ValueChanged<String> onChanged;

  const CaseSearchField({super.key, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final isLight = colors.brightness == Brightness.light;

    return SizedBox(
      height: 56,
      child: TextField(
        onChanged: onChanged,
        maxLines: 1,
        textAlignVertical: TextAlignVertical.center,
        style: TextStyle(color: colors.onSurface, fontSize: 14),
        decoration: InputDecoration(
          constraints: const BoxConstraints.tightFor(height: 56),
          isDense: true,
          prefixIconConstraints: const BoxConstraints(
            minWidth: 48,
            minHeight: 56,
            maxHeight: 56,
          ),
          hintText: 'Search Cases',
          hintStyle: TextStyle(color: Color(0xFFA8A8A8), fontSize: 16),
          prefixIcon: const Icon(
            LucideIcons.search500,
            color: Color(0xFF667685),
            size: 28,
          ),
          filled: true,
          fillColor: isLight
              ? const Color(0xFFE4E8EC)
              : colors.surfaceContainerHighest,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 0,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: colors.primary),
          ),
        ),
      ),
    );
  }
}
