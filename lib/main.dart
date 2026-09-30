import 'package:flutter/material.dart';
import 'package:magic_calculator/calculator/calculator_screen.dart';

void main() {
  runApp(const MagicCalculatorApp());
}

class MagicCalculatorApp extends StatelessWidget {
  const MagicCalculatorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '计算器',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF50647A),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: const CalculatorScreen(),
    );
  }
}
