import 'package:material_ui/material_ui.dart';

class CaseCreationPage extends StatelessWidget {
  const CaseCreationPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Case')),
      body: const SafeArea(child: Center(child: Text('케이스 등록 화면'))),
    );
  }
}
