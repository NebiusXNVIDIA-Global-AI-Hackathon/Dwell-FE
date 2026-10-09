import 'package:material_ui/material_ui.dart';
import 'package:flutter_svg/flutter_svg.dart';

enum SafetyNoticeType { electrical, gas, flooding, ceiling }

enum SafetyNoticeResult { leave, continueCreation }

class SafetyNoticeDialog extends StatelessWidget {
  const SafetyNoticeDialog({super.key, required this.type});

  final SafetyNoticeType type;

  String get _title {
    switch (type) {
      case SafetyNoticeType.electrical:
        return 'Electrical Safety Alert';
      case SafetyNoticeType.gas:
        return 'Gas Safety Alert';
      case SafetyNoticeType.flooding:
        return 'Flooding Safety Alert';
      case SafetyNoticeType.ceiling:
        return 'Ceiling Safety Alert';
    }
  }

  String get _lead {
    switch (type) {
      case SafetyNoticeType.electrical:
        return 'This may be an electrical hazard.';
      case SafetyNoticeType.gas:
        return 'A gas smell may indicate a gas leak.';
      case SafetyNoticeType.flooding:
        return 'Flooding may create an electrical hazard.';
      case SafetyNoticeType.ceiling:
        return 'Do not stand or walk underneath the affected area.';
    }
  }

  String get _body {
    switch (type) {
      case SafetyNoticeType.electrical:
        return 'Do not touch the affected area.\n'
            'Even if there is no immediate danger,\n'
            'contact your landlord right away.\n'
            'If you see smoke, fire, or another immediate danger, call 911.';

      case SafetyNoticeType.gas:
        return 'Leave the area immediately and move to a safe location.\n'
            'Once you’re safe, call 911 or your gas utility’s emergency line, '
            'and notify your landlord.\n'
            'Do not stay inside to take photos or collect evidence.';

      case SafetyNoticeType.flooding:
        return 'If water is near outlets, wiring, or electrical equipment, '
            'do not enter or touch the affected area.\n'
            'Keep a safe distance and contact your landlord right away.\n'
            'If there is immediate danger, call 911.';

      case SafetyNoticeType.ceiling:
        return 'Keep a safe distance and contact your landlord right away.\n'
            'If the ceiling is actively falling or appears likely to collapse, '
            'leave the area and call 911 if there is immediate danger.';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      clipBehavior: Clip.antiAlias,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 360),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SvgPicture.asset(
                          'assets/icons/case/warning.svg',
                          width: 18,
                          height: 16,
                          excludeFromSemantics: true,
                        ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            _title,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Color(0xFFFF0000),
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        SvgPicture.asset(
                          'assets/icons/case/warning.svg',
                          width: 18,
                          height: 16,
                          excludeFromSemantics: true,
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      _lead,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.black,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _body,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.black,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const Divider(height: 1, thickness: 1, color: Color(0xFFE3E3E3)),
            Row(
              children: [
                Expanded(
                  child: _buildAction(
                    context,
                    label: 'Leave',
                    color: const Color(0xFF0065F3),
                    result: SafetyNoticeResult.leave,
                  ),
                ),
                const SizedBox(
                  width: 1,
                  height: 44,
                  child: ColoredBox(color: Color(0xFFE3E3E3)),
                ),
                Expanded(
                  child: _buildAction(
                    context,
                    label: 'I’m Safe — Continue',
                    color: const Color(0xFF5E5E5E),
                    result: SafetyNoticeResult.continueCreation,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAction(
    BuildContext context, {
    required String label,
    required Color color,
    required SafetyNoticeResult result,
  }) {
    return TextButton(
      onPressed: () => Navigator.of(context).pop(result),
      style: TextButton.styleFrom(
        foregroundColor: color,
        minimumSize: const Size(0, 44),
        padding: const EdgeInsets.symmetric(horizontal: 8),
        shape: const RoundedRectangleBorder(),
        textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
      ),
      child: Text(label, textAlign: TextAlign.center),
    );
  }
}
