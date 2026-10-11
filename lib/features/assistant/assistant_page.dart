import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/app_colors.dart';
import 'data/chat_shell_mock.dart';

/// Assistant 탭
// TODO: 채팅 목록 화면으로 교체 — 지금은 셸 확인용 임시 진입점 (#15)
class AssistantPage extends StatelessWidget {
  const AssistantPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Center(
          child: OutlinedButton(
            onPressed: () =>
                context.push('/assistant/chat/${mockShellThread.caseNo}'),
            child: Text('Open case chat · ${mockShellThread.caseNo}'),
          ),
        ),
      ),
    );
  }
}
