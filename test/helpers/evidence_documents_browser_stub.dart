import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'Browser document ownership requires Chrome',
    () {},
    skip: 'Run flutter test --platform chrome test/evidence_documents_browser_test.dart',
  );
}
