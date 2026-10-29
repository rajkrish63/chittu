import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app.dart';
import 'core/locale_controller.dart';
import 'core/theme_controller.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppLocaleController.instance.init();
  await AppThemeController.instance.init();
  runApp(const ProviderScope(child: ChitNotebookApp()));
}
