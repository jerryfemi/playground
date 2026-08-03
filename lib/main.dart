import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:playground/glide_menu/example_app.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GlideMenu Showcase',
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: Colors.black,
        colorScheme: const ColorScheme.dark(
          primary: CupertinoColors.activeBlue,
          surface: Colors.black,
        ),
      ),
      debugShowCheckedModeBanner: false,
      home: const DemoPage(),
      themeMode: ThemeMode.dark,
    );
  }
}
