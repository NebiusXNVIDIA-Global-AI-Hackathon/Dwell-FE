import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../case_detail_tokens.dart';
import '../widgets/case_detail_app_bar.dart';

/// Temporary destination for screens that are not built yet.
class CasePlaceholderScreen extends StatelessWidget {
  const CasePlaceholderScreen({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CaseDetailColors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            CaseDetailAppBar(title: title, onBack: context.pop),
            const Expanded(
              child: Center(
                child: Text('Coming soon', style: CaseDetailText.statusMeta),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
