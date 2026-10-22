import 'dart:async';

import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../core/theme.dart';
import '../case_detail_tokens.dart';

class CaseDeletedToast extends StatefulWidget {
  const CaseDeletedToast({
    super.key,
    required this.message,
    required this.onDismissed,
  });

  final String message;
  final VoidCallback onDismissed;

  @override
  State<CaseDeletedToast> createState() => _CaseDeletedToastState();
}

class _CaseDeletedToastState extends State<CaseDeletedToast>
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
    // Hide the toast after 2 seconds
    _timer = Timer(const Duration(seconds: 2), _dismiss);
  }

  Future<void> _dismiss() async {
    try {
      await _fade.reverse().orCancel;
      if (mounted) widget.onDismissed();
    } on TickerCanceled {
      return;
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
          key: const ValueKey('case-deleted-toast'),
          height: CaseDetailSizes.toastHeight,
          padding: const EdgeInsets.symmetric(horizontal: Gap.md),
          decoration: BoxDecoration(
            color: CaseDetailColors.toast,
            borderRadius: BorderRadius.circular(Gap.card),
            boxShadow: const [
              BoxShadow(
                color: CaseDetailColors.floatShadow,
                offset: CaseDetailSizes.shadowOffset,
                blurRadius: CaseDetailSizes.shadowBlur,
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const ExcludeSemantics(
                child: Icon(
                  LucideIcons.check,
                  size: CaseDetailSizes.toastIcon,
                  color: CaseDetailColors.surface,
                ),
              ),
              const SizedBox(width: Gap.sm),
              Flexible(
                child: Text(
                  widget.message,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: CaseDetailText.toast,
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
