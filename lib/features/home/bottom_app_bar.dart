import 'package:flutter/material.dart';
import 'package:app/core/constants.dart';
import 'package:app/features/home/start_stop_button.dart';
import 'package:app/features/home/custom_semicircle.dart';

class CustomBottomAppBar extends StatefulWidget {
  final VoidCallback onMenuPressed;
  final int score;

  const CustomBottomAppBar({super.key, required this.onMenuPressed, required this.score});

  @override
  State<CustomBottomAppBar> createState() => _CustomBottomAppBarState();
}

class _CustomBottomAppBarState extends State<CustomBottomAppBar> {
  bool _isRunning = false;

  void _toggleStartStop() {
    setState(() {
      _isRunning = !_isRunning;
    });

    // Add Start/Stop Logic Here
  }

  //TODO: add exercise menu panel

  @override
  Widget build(BuildContext context) {
    return BottomAppBar(
      color: Colors.transparent,
      elevation: 0,
      height: 80,
      padding: EdgeInsets.zero,
      child: Stack(
        alignment: Alignment.topCenter,
        clipBehavior: Clip.none,
        children: [
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              width: MediaQuery.of(context).size.width,
              height: 64,
              decoration: BoxDecoration(
                color: AppColors.primaryBackground,
                boxShadow: [AppShadows.appBarShadow],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Padding(
                    padding: EdgeInsets.only(left: 12),
                    child: InkWell(
                      onTap: widget.onMenuPressed,
                      child: Icon(
                        Icons.menu_rounded,
                        color: AppColors.primaryText,
                        size: 38.4,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(right: 14),
                    child: StartStopButton(
                      onTap: _toggleStartStop,
                      isRunning: _isRunning,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned(top: 0, child: CustomSemicircle(score: widget.score)),
        ],
      ),
    );
  }
}
