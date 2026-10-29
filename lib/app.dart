import 'package:flutter/material.dart';
import 'core/locale_controller.dart';
import 'core/theme_controller.dart';
import 'core/strings.dart';
import 'routing/app_router.dart';

class ChitNotebookApp extends StatelessWidget {
  const ChitNotebookApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([
        AppLocaleController.instance,
        AppThemeController.instance,
      ]),
      builder: (context, _) => MaterialApp.router(
        title: S.appTitle,
        debugShowCheckedModeBanner: false,
        routerConfig: appRouter,
        themeMode: AppThemeController.instance.themeMode,
        theme: ThemeData(
          colorSchemeSeed: Colors.indigo,
          brightness: Brightness.light,
          useMaterial3: true,
          scaffoldBackgroundColor: const Color(0xFFF8F9FA),
          cardTheme: CardThemeData(
            elevation: 1,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
        ),
        darkTheme: ThemeData(
          colorSchemeSeed: Colors.indigo,
          brightness: Brightness.dark,
          useMaterial3: true,
          cardTheme: CardThemeData(
            elevation: 1,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
        ),
      ),
    );
  }
}
