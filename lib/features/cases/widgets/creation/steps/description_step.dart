import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:material_ui/material_ui.dart';

import '../../../controllers/case_creation_controller.dart';

class DescriptionStep extends StatefulWidget {
  const DescriptionStep({
    super.key,
    required this.description,
    required this.onChanged,
    this.enabled = true,
  });

  final String description;
  final ValueChanged<String> onChanged;
  final bool enabled;

  @override
  State<DescriptionStep> createState() => _DescriptionStepState();
}

class _DescriptionStepState extends State<DescriptionStep> {
  late final TextEditingController _text;
  final _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    _text = TextEditingController(text: widget.description);
  }

  @override
  void didUpdateWidget(covariant DescriptionStep oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_text.text != widget.description) {
      _text.value = TextEditingValue(
        text: widget.description,
        selection: TextSelection.collapsed(offset: widget.description.length),
      );
    }
  }

  @override
  void dispose() {
    _text.dispose();
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const heading = TextStyle(
      color: Color(0xFF243B53),
      fontSize: 16,
      fontWeight: FontWeight.w600,
      height: 1.25,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 3),
          child: Text(
            'Add details for a more accurate AI analysis',
            style: heading,
          ),
        ),
        const SizedBox(height: 16),
        ListenableBuilder(
          listenable: Listenable.merge([_text, _focus]),
          builder: (context, _) => Column(
            children: [
              AnimatedContainer(
                key: const ValueKey('description-input-box'),
                duration: const Duration(milliseconds: 100),
                height: 138,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _focus.hasFocus
                        ? const Color(0xFF0066FF)
                        : const Color(0xFFA6A6A6),
                  ),
                ),
                child: Stack(
                  children: [
                    Padding(
                      padding: EdgeInsets.fromLTRB(
                        23,
                        18,
                        _text.text.isEmpty ? 18 : 42,
                        18,
                      ),
                      child: TextField(
                        key: const ValueKey('description-input'),
                        controller: _text,
                        focusNode: _focus,
                        enabled: widget.enabled,
                        expands: true,
                        minLines: null,
                        maxLines: null,
                        maxLength: CaseCreationController.descriptionLimit,
                        maxLengthEnforcement: MaxLengthEnforcement.enforced,
                        keyboardType: TextInputType.multiline,
                        textAlignVertical: TextAlignVertical.top,
                        style: const TextStyle(
                          color: Colors.black,
                          fontSize: 16,
                          height: 1.25,
                        ),
                        decoration: const InputDecoration(
                          hintText: 'e.g. Water is leaking from the ceiling above the shower. The stain has gotten bigger since last week.',
                          hintStyle: TextStyle(
                            color: Color(0xFF9FA6AB),
                            fontSize: 16,
                            height: 1.25,
                          ),
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          disabledBorder: InputBorder.none,
                          contentPadding: EdgeInsets.zero,
                          isCollapsed: true,
                          counterText: '',
                        ),
                        onChanged: widget.onChanged,
                      ),
                    ),
                    if (_text.text.isNotEmpty)
                      Positioned(
                        top: 5,
                        right: 2,
                        child: IconButton(
                          key: const ValueKey('description-clear'),
                          tooltip: 'Clear description',
                          onPressed: widget.enabled
                              ? () {
                                  _text.clear();
                                  widget.onChanged('');
                                }
                              : null,
                          constraints: const BoxConstraints(
                            minWidth: 44,
                            minHeight: 44,
                          ),
                          icon: const Icon(
                            Icons.cancel,
                            color: Color(0xFFA6A6A6),
                            size: 16,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  '${_text.text.characters.length}/500',
                  key: const ValueKey('description-count'),
                  style: const TextStyle(
                    color: Color(0xFF9FA6AB),
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    height: 1.25,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 26),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 3),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Not sure what to write?', style: heading),
              Text('Here are a few guide questions to help', style: heading),
            ],
          ),
        ),
        const SizedBox(height: 14),
        for (final question in const [
          (LucideIcons.calendarDays, 'When did you notice this?'),
          (LucideIcons.activity, 'Is it still happening?'),
          (LucideIcons.chartLine, 'Has it affected anything nearby?'),
          (LucideIcons.searchAlert, 'Any idea what caused it?'),
        ])
          Padding(
            padding: const EdgeInsets.only(bottom: 7),
            child: Container(
              constraints: const BoxConstraints(minHeight: 53),
              padding: const EdgeInsets.symmetric(
                horizontal: 18,
                vertical: 13.5,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: const Color(0xFFA6A6A6)),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  ExcludeSemantics(
                    child: Icon(question.$1, size: 24, color: Colors.black),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      question.$2,
                      style: const TextStyle(
                        color: Colors.black,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        height: 1.25,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
