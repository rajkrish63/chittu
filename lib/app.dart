import 'package:flutter/material.dart';
import 'features/home/home_screen.dart';

class ChitNotebookApp extends StatelessWidget {
  const ChitNotebookApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'Chit Notebook',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(colorSchemeSeed: Colors.black, useMaterial3: true),
        home: const HomeScreen(),
      );
}
