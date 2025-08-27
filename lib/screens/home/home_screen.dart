import 'package:app/core/constants.dart';
import 'package:app/screens/home/bottom_app_bar/bottom_app_bar.dart';
import 'package:app/screens/home/camera_widget.dart';
import 'package:app/screens/home/exercise_menu_panel/exercise_menu_panel.dart';
import 'package:app/screens/home/instruction_panel.dart';
import 'package:app/services/camera_provider.dart';
import 'package:app/services/native_inference_channel.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isMenuOpen = false;
  bool _isExerciseLoading = false;
  String _currentExercise = "Overhead Presses";

  void _toggleMenu() {
    setState(() {
      _isMenuOpen = !_isMenuOpen;
    });
  }

  Future<void> _loadExercise(String label) async {
    setState(() {
      _isExerciseLoading = true;
      _currentExercise = label;
    });

    try {
      context.read<CameraProvider>().stopFrameCapture();
      await NativeInferenceChannel.initExerciseModel(label);
      await Future.delayed(const Duration(seconds: 1));
    } catch (e) {
      debugPrint("Failed to load exercise $label: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Error loading $label exercise",
            style: AppTextStyles.buttonText,
          ),
          backgroundColor: AppColors.primaryBackground,
        ),
      );
    } finally {
      setState(() => _isExerciseLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryBackground,
      extendBody: true,
      body: Stack(
        children: [
          // Instruction Panel
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: RepaintBoundary(
              key: const ValueKey('instruction_boundary'),
              child: InstructionPanel(exercise: _currentExercise),
            ),
          ),

          // Camera preview with skeletal overlay
          Positioned(right: 0, bottom: 64, child: CameraWidget()),
          // Bottom App Bar
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: CustomBottomAppBar(onMenuPressed: _toggleMenu),
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
            child: ExerciseMenuPanel(
              onBackPressed: _toggleMenu,
              onExerciseSelected: _loadExercise,
            ),
          ),
          // Exercise loading indicator
          if (_isExerciseLoading)
            Container(
              color: Color(0x4C1B1B1B),
              child: Center(
                child: Image.asset(
                  "assets/images/flexfit_loading.gif",
                  width: 200,
                  height: 200,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
