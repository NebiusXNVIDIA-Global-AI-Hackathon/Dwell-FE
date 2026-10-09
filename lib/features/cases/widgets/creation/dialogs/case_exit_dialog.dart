import 'package:material_ui/material_ui.dart';

enum CaseExitResult { stay, leave }

class CaseExitDialog extends StatelessWidget {
  const CaseExitDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      constraints: const BoxConstraints(maxWidth: 254),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 안내 영역: 기본 글자 배율에서 높이 69
          const Flexible(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(16, 16, 16, 11),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Leave this page?',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      height: 1.25,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Your progress will not be saved.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Color(0xFF5E5E5E),
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      height: 1.25,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 가로 구분선
          const SizedBox(
            height: 1,
            child: ColoredBox(color: Color(0xFFE3E3E3)),
          ),

          // 버튼 영역: 좌우 같은 너비, 터치 높이 44
          SizedBox(
            height: 44,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: _buildAction(
                    context,
                    label: 'Stay',
                    color: const Color(0xFF5E5E5E),
                    result: CaseExitResult.stay,
                  ),
                ),
                const SizedBox(
                  width: 1,
                  child: ColoredBox(color: Color(0xFFE3E3E3)),
                ),
                Expanded(
                  child: _buildAction(
                    context,
                    label: 'Leave',
                    color: const Color(0xFF0065F3),
                    result: CaseExitResult.leave,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAction(
    BuildContext context, {
    required String label,
    required Color color,
    required CaseExitResult result,
  }) {
    return TextButton(
      onPressed: () => Navigator.of(context).pop(result),
      style: TextButton.styleFrom(
        foregroundColor: color,
        minimumSize: Size.zero,
        padding: EdgeInsets.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        visualDensity: VisualDensity.standard,
        shape: const RoundedRectangleBorder(),
        textStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          height: 1.25,
        ),
      ),
      child: Text(label, textAlign: TextAlign.center),
    );
  }
}
