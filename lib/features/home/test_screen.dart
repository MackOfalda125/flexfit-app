import 'package:flutter/material.dart';
import 'package:app/core/constants.dart';
import 'package:app/features/home/exercise_menu_panel.dart';
import 'package:app/features/home/bottom_app_bar.dart';

class TestScreen extends StatefulWidget {
  const TestScreen({super.key});

  @override
  State<TestScreen> createState() => _TestScreenState();
}

class _TestScreenState extends State<TestScreen> {
  bool _isMenuOpen = false;

  void _toggleMenu() {
    setState(() {
      _isMenuOpen = !_isMenuOpen;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold();
  }
}
