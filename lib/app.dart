import 'package:flutter/material.dart';
import 'core/locale_controller.dart';
import 'core/strings.dart';
import 'features/home/home_screen.dart';

class ChitNotebookApp extends StatelessWidget {
  const ChitNotebookApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: AppLocaleController.instance,
      builder: (context, _) => MaterialApp(
        title: S.appTitle,
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorSchemeSeed: Colors.indigo,
          useMaterial3: true,
          scaffoldBackgroundColor: const Color(0xFFF8F9FA),
          cardTheme: CardThemeData(
            elevation: 1,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
        ),
        home: const HomeScreen(),
      ),
    );
  }
}
