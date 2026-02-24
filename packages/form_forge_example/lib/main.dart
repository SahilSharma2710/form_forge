import 'package:flutter/material.dart';

void main() {
  runApp(const FormForgeExampleApp());
}

/// Example app demonstrating form_forge usage.
class FormForgeExampleApp extends StatelessWidget {
  const FormForgeExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'form_forge Examples',
      theme: ThemeData(colorSchemeSeed: Colors.deepPurple, useMaterial3: true),
      home: const Scaffold(
        body: Center(child: Text('form_forge examples coming soon')),
      ),
    );
  }
}
