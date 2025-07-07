import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:app/core/constants.dart';
import 'package:app/features/home/bottom_app_bar.dart';
import 'package:app/features/home/exercise_menu_panel.dart';
import 'package:app/features/home/camera_widget.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isMenuOpen = false;

  void _toggleMenu() {
    setState(() {
      _isMenuOpen = !_isMenuOpen;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryText,
      extendBody: true,
      body: Stack(
        children: [
          // Camera Preview
          Positioned.fill(
            bottom: 64,
            child: RepaintBoundary(
              key: const ValueKey('camera_boundary'),
              child: const CameraWidget(),
            ),
          ),
          // Bottom App Bar
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: CustomBottomAppBar(
              onMenuPressed: _toggleMenu,
              score: 60,
            ),
          ),
          // Dimmed background
          if (_isMenuOpen)
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: _toggleMenu,
              child: Container(color: Color(0x4C1B1B1B)),
            ),
          // Sliding panel
          AnimatedPositioned(
            duration: const Duration(milliseconds: 100),
            left: _isMenuOpen ? 0 : -230,
            top: 0,
            bottom: 0,
            child: ExerciseMenuPanel(onBackPressed: _toggleMenu),
          ),
        ],
      ),
    );
  }
}
