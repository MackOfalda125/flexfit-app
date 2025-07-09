import 'package:app/core/constants.dart';
import 'package:app/features/home/custom_semicircle.dart';
import 'package:app/features/home/start_stop_button.dart';
import 'package:flutter/material.dart';

class CustomBottomAppBar extends StatefulWidget {
  final VoidCallback onMenuPressed;
  final int score;
  final VoidCallback onStartStop;
  final bool isTracking;

  const CustomBottomAppBar({
    super.key,
    required this.onMenuPressed,
    required this.score,
    required this.onStartStop,
    required this.isTracking,
  });

  @override
  State<CustomBottomAppBar> createState() => _CustomBottomAppBarState();
}

class _CustomBottomAppBarState extends State<CustomBottomAppBar> {
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
                      onTap: widget.onStartStop,
                      isTracking: widget.isTracking,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            top: 0,
            child: RepaintBoundary(
              key: const ValueKey('score_boundary'),
              child: CustomSemicircle(score: widget.score),
            ),
          ),
        ],
      ),
    );
  }
}
