import 'package:flutter/material.dart';
import 'package:app/core/constants.dart';
import 'package:app/features/home/bottom_app_bar.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryText,
      extendBodyBehindAppBar: true,
      bottomNavigationBar: CustomBottomAppBar(),
    );
  }
}
