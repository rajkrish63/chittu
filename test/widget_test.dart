import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:chit_notebook/app.dart';
import 'package:chit_notebook/core/locale_controller.dart';
import 'package:chit_notebook/core/strings.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('App launches smoke test in English by default', (WidgetTester tester) async {
    await tester.pumpWidget(const ChitNotebookApp());
    expect(find.text(S.myChits), findsAtLeastNWidgets(1));
    expect(find.text(S.settings), findsOneWidget);
  });

  testWidgets('App language switches to Tamil', (WidgetTester tester) async {
    await tester.pumpWidget(const ChitNotebookApp());
    await AppLocaleController.instance.setLanguage('ta');
    await tester.pump();
    expect(find.text('என் சீட்கள்'), findsAtLeastNWidgets(1));
    expect(find.text('அமைப்புகள்'), findsOneWidget);

    // Switch back to English
    await AppLocaleController.instance.setLanguage('en');
    await tester.pump();
    expect(find.text('My Chits'), findsAtLeastNWidgets(1));
    expect(find.text('Settings'), findsOneWidget);
  });
}
