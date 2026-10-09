import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:material_ui/material_ui.dart';

enum EvidenceSource { photo, library, video, audio, document }

class EvidenceAddSheet extends StatelessWidget {
  const EvidenceAddSheet({super.key, required this.onSelected});
  final ValueChanged<EvidenceSource> onSelected;
  // Lucide300 preserves the same paths with a 1.55 stroke in its 24-unit viewBox.
  static const options = [
    (
      EvidenceSource.photo,
      'Take Photo',
      'Document the issue now',
      LucideIcons.camera300,
    ),
    (
      EvidenceSource.library,
      'Upload from library',
      'Choose existing photos or videos',
      LucideIcons.image300,
    ),
    (
      EvidenceSource.video,
      'Record Video',
      'Capture a video of the issue',
      LucideIcons.video300,
    ),
    (
      EvidenceSource.audio,
      'Record Audio',
      'Describe the issue or record the sound',
      LucideIcons.mic300,
    ),
    (
      EvidenceSource.document,
      'Upload Documents',
      'Notice, letters, leases, etc.',
      LucideIcons.fileText300,
    ),
  ];
  @override
  Widget build(BuildContext context) => SafeArea(
    top: false,
    child: SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(21, 20, 21, 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 67,
              height: 6,
              decoration: BoxDecoration(
                color: const Color(0xFFE3E3E3),
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),
          const SizedBox(height: 17),
          const Padding(
            padding: EdgeInsets.only(left: 5),
            child: Text(
              'Add Evidence',
              style: TextStyle(
                fontSize: 20,
                height: 1.2,
                fontWeight: FontWeight.w700,
                color: Color(0xFF243B53),
              ),
            ),
          ),
          const SizedBox(height: 17),
          for (var i = 0; i < options.length; i++) ...[
            if (i > 0) const SizedBox(height: 6),
            _EvidenceOption(
              source: options[i].$1,
              title: options[i].$2,
              description: options[i].$3,
              icon: options[i].$4,
              onTap: () => onSelected(options[i].$1),
            ),
          ],
        ],
      ),
    ),
  );
}

class _EvidenceOption extends StatefulWidget {
  const _EvidenceOption({
    required this.source,
    required this.title,
    required this.description,
    required this.icon,
    required this.onTap,
  });
  final EvidenceSource source;
  final String title;
  final String description;
  final IconData icon;
  final VoidCallback onTap;
  @override
  State<_EvidenceOption> createState() => _EvidenceOptionState();
}

class _EvidenceOptionState extends State<_EvidenceOption> {
  bool _pressed = false;
  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: '${widget.title}. ${widget.description}',
    onTap: widget.onTap,
    excludeSemantics: true,
    child: Material(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: _pressed ? const Color(0xFF243B53) : const Color(0xFFE3E3E3),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        key: ValueKey(widget.source),
        onTap: widget.onTap,
        onHighlightChanged: (value) => setState(() => _pressed = value),
        excludeFromSemantics: true,
        overlayColor: const WidgetStatePropertyAll(Colors.transparent),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Row(
            children: [
              Container(
                width: 63,
                height: 63,
                decoration: BoxDecoration(
                  color: const Color(0xFFE3E3E3),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  widget.icon,
                  size: 36,
                  color: const Color(0xFF243B53),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.title,
                      style: const TextStyle(
                        fontSize: 20,
                        height: 1.2,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF243B53),
                      ),
                    ),
                    Text(
                      widget.description,
                      style: const TextStyle(
                        fontSize: 16,
                        height: 1.2,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF627381),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
