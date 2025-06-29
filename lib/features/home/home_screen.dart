import 'package:flutter/material.dart';
import 'package:app/core/constants.dart';
import 'package:app/features/home/bottom_app_bar.dart';
import 'package:app/features/home/exercise_menu_panel.dart';

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
      extendBody: true, // Needed to allow overlay over bottomNavigationBar
      body: Stack(
        children: [
          // Main content (camera preview or background)
          Container(), // Replace with your actual UI
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: CustomBottomAppBar(onMenuPressed: _toggleMenu),
          ),
          // Dimmed background
          if (_isMenuOpen)
            GestureDetector(
              onTap: _toggleMenu,
              child: Container(color: Colors.black.withOpacity(0.2)),
            ),

          // Sliding panel
          AnimatedPositioned(
            duration: const Duration(milliseconds: 300),
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
