import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:material_ui/material_ui.dart';

import '../models/case_creation_result.dart';
import '../models/reports_creation_notice.dart';
import '../widgets/creation/case_creation_summary.dart';

class CaseCreatedPage extends StatefulWidget {
  const CaseCreatedPage({super.key, required this.result, this.onViewAnalysis});
  final CaseCreationResult result;

  /// Supply only when a valid real analysis and detail destination exist.
  final VoidCallback? onViewAnalysis;
  @override
  State<CaseCreatedPage> createState() => _CaseCreatedPageState();
}

class _CaseCreatedPageState extends State<CaseCreatedPage> {
  bool _leaving = false;
  void _backToMain() {
    if (_leaving) return;
    setState(() => _leaving = true);
    context.goNamed(
      'cases',
      extra: ReportsCreationNotice.fromResult(widget.result),
    ); // Remove creation/analysis/success from the stack.
  }

  Widget _check(String text, bool verified) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Row(
      children: [
        Container(
          width: 29,
          height: 29,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: verified || widget.result.isDemo
                ? const Color(0xFF1F7011)
                : null,
            border: verified || widget.result.isDemo
                ? null
                : Border.all(color: const Color(0xFFBFCDBF), width: 2),
          ),
          child: verified || widget.result.isDemo
              ? const Icon(LucideIcons.check, color: Colors.white, size: 21)
              : null,
        ),
        const SizedBox(width: 21),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              color: Color(0xFF637381),
              fontSize: 20,
              fontWeight: FontWeight.w500,
              height: 1.25,
            ),
          ),
        ),
      ],
    ),
  );

  Widget _button(String label, bool primary, VoidCallback? onPressed) =>
      SizedBox(
        height: 58,
        child: FilledButton(
          onPressed: onPressed,
          style: FilledButton.styleFrom(
            backgroundColor: primary
                ? const Color(0xFF243B53)
                : const Color(0xFFE5E5E5),
            disabledBackgroundColor: const Color(0xFFE5E5E5),
            foregroundColor: primary ? Colors.white : const Color(0xFF243B53),
            disabledForegroundColor: const Color(0xFF243B53),
            overlayColor: Colors.transparent,
            splashFactory: NoSplash.splashFactory,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            textStyle: const TextStyle(
              fontFamily: 'Pretendard Variable',
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          child: Text(label, textAlign: TextAlign.center),
        ),
      );

  @override
  Widget build(BuildContext context) => PopScope<Object?>(
    canPop: false,
    onPopInvokedWithResult: (didPop, _) {
      if (!didPop) _backToMain();
    },
    child: Scaffold(
      backgroundColor: const Color(0xFFF8F8F8),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(18, 150, 18, 44),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Case successfully\nCreated',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Color(0xFF243B53),
                      fontSize: 32,
                      fontWeight: FontWeight.w700,
                      height: 1.2,
                    ),
                  ),
                  if (widget.result.isDemo) ...[
                    const SizedBox(height: 8),
                    const Text(
                      'Demo preview · No case saved',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Color(0xFF667685),
                        fontSize: 12,
                        height: 1.3,
                      ),
                    ),
                  ],
                  SizedBox(height: widget.result.isDemo ? 24 : 48),
                  CaseCreationSummary(result: widget.result),
                  const SizedBox(height: 28),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(35, 0, 9, 0),
                    child: Column(
                      children: [
                        _check(
                          'Original file saved',
                          widget.result.originalFileSaved,
                        ),
                        _check(
                          'AI Analysis attached',
                          widget.result.analysisAttached,
                        ),
                        _check(
                          'Protected from tampering',
                          widget.result.tamperProtectionConfirmed,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 73),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final compact =
                          constraints.maxWidth < 300 ||
                          MediaQuery.textScalerOf(context).scale(16) > 22;
                      final view = _button(
                        'View Analysis',
                        false,
                        widget.result.isDemo || !widget.result.analysisAttached
                            ? null
                            : widget.onViewAnalysis,
                      );
                      final back = _button(
                        'Back to main',
                        true,
                        _leaving ? null : _backToMain,
                      );
                      return compact
                          ? Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [view, const SizedBox(height: 8), back],
                            )
                          : Row(
                              children: [
                                Expanded(child: view),
                                const SizedBox(width: 7),
                                Expanded(child: back),
                              ],
                            );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );
}
