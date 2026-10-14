import 'dart:async';

import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:material_ui/material_ui.dart';

class CaseCreationToast extends StatefulWidget {
  const CaseCreationToast({
    super.key,
    required this.message,
    required this.onDismissed,
  });
  final String message;
  final VoidCallback onDismissed;
  @override
  State<CaseCreationToast> createState() => _CaseCreationToastState();
}

class _CaseCreationToastState extends State<CaseCreationToast>
    with SingleTickerProviderStateMixin {
  late final AnimationController _fade;
  late final CurvedAnimation _opacity;
  Timer? _timer;
  @override
  void initState() {
    super.initState();
    _fade = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 180),
    )..forward();
    _opacity = CurvedAnimation(
      parent: _fade,
      curve: Curves.easeOut,
      reverseCurve: Curves.easeIn,
    );
    _timer = Timer(const Duration(milliseconds: 2500), _dismiss);
  }

  Future<void> _dismiss() async {
    try {
      await _fade.reverse().orCancel;
      if (mounted) widget.onDismissed();
    } on TickerCanceled {
      // Navigating away disposes the toast and cancels the animation.
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _opacity.dispose();
    _fade.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => IgnorePointer(
    child: FadeTransition(
      opacity: _opacity,
      child: Semantics(
        liveRegion: true,
        child: Container(
          key: const ValueKey('reports-creation-toast'),
          width: 260,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
          decoration: BoxDecoration(
            color: const Color(0xFF514F4F),
            borderRadius: BorderRadius.circular(12),
            boxShadow: const [
              BoxShadow(
                color: Color(0x33000000),
                blurRadius: 4,
                offset: Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            children: [
              const ExcludeSemantics(
                child: Icon(LucideIcons.check, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  widget.message,
                  style: const TextStyle(
                    color: Colors.white,
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
    ),
  );
}
