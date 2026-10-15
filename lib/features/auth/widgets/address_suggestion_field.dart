import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:material_ui/material_ui.dart';

import '../services/address_suggestions.dart';
import 'sign_up_components.dart';

class AddressSuggestionField extends StatefulWidget {
  const AddressSuggestionField({
    super.key,
    required this.controller,
    required this.source,
    required this.onChanged,
    required this.onSelected,
    this.enabled = true,
  });
  final TextEditingController controller;
  final AddressSuggestionSource source;
  final ValueChanged<String> onChanged;
  final ValueChanged<AddressSuggestion> onSelected;
  final bool enabled;
  @override
  State<AddressSuggestionField> createState() => _AddressSuggestionFieldState();
}

class _AddressSuggestionFieldState extends State<AddressSuggestionField> {
  final _focus = FocusNode(debugLabel: 'Address suggestions');
  int _generation = 0;
  bool _empty = false;
  @override
  void dispose() {
    _generation++;
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) => RawAutocomplete<AddressSuggestion>(
      textEditingController: widget.controller,
      focusNode: _focus,
      displayStringForOption: (option) => option.line1,
      optionsBuilder: (value) async {
        final generation = ++_generation;
        if (value.text.trim().isEmpty) {
          if (mounted) setState(() => _empty = false);
          return const [];
        }
        List<AddressSuggestion> results;
        try {
          results = await widget.source.search(value.text);
        } catch (_) {
          results = [];
        }
        if (!mounted || generation != _generation) return const [];
        setState(() => _empty = results.isEmpty);
        return results;
      },
      onSelected: widget.onSelected,
      fieldViewBuilder: (context, controller, focus, submit) => TextField(
        key: const ValueKey('signup-address'),
        controller: controller,
        focusNode: focus,
        enabled: widget.enabled,
        onChanged: widget.onChanged,
        textInputAction: TextInputAction.next,
        keyboardType: TextInputType.streetAddress,
        style: const TextStyle(fontSize: 16, height: 1.2),
        onTapOutside: (_) => focus.unfocus(),
        onSubmitted: (_) => submit(),
        decoration: signUpDecoration('Enter your address').copyWith(
          helperText: _empty
              ? 'No demo suggestions. Enter your address manually.'
              : null,
          helperMaxLines: 3,
        ),
      ),
      optionsViewBuilder: (context, select, options) => Align(
        alignment: Alignment.topLeft,
        child: TextFieldTapRegion(
          child: SizedBox(
            width: constraints.maxWidth,
            child: Material(
              color: const Color(0xFFFCFCFC),
              elevation: 3,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: const BorderSide(color: Color(0xFFE5E5E5)),
              ),
              clipBehavior: Clip.antiAlias,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 200),
                child: ListView.builder(
                  shrinkWrap: true,
                  padding: EdgeInsets.zero,
                  itemCount: options.length,
                  itemBuilder: (context, index) {
                    final option = options.elementAt(index);
                    return TextButton(
                      onPressed: () => select(option),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.all(12),
                        shape: const RoundedRectangleBorder(),
                        foregroundColor: const Color(0xFF243B53),
                        backgroundColor:
                            AutocompleteHighlightedOption.of(context) == index
                            ? const Color(0xFFE5E5E5)
                            : Colors.transparent,
                        splashFactory: NoSplash.splashFactory,
                      ),
                      child: Row(
                        children: [
                          const Icon(LucideIcons.mapPin, size: 18),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  option.line1,
                                  style: const TextStyle(
                                    fontFamily: 'Pretendard Variable',
                                    fontSize: 16,
                                    color: Colors.black,
                                  ),
                                ),
                                Text(
                                  option.subtitle,
                                  style: const TextStyle(
                                    fontFamily: 'Pretendard Variable',
                                    fontSize: 12,
                                    color: Color(0xFF606060),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}
