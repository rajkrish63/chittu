import 'package:flutter/material.dart';
import 'app.dart';
import 'core/locale_controller.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppLocaleController.instance.init();
  runApp(const ChitNotebookApp());
}
