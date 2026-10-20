import 'package:flutter_test/flutter_test.dart';
import 'package:chit_notebook/app.dart';

void main() {
  testWidgets('App launches smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const ChitNotebookApp());
    expect(find.text('என் சீட்கள்'), findsOneWidget);
  });
}
