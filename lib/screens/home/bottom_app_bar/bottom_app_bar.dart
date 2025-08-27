import 'package:app/core/constants.dart';
import 'package:app/screens/home/bottom_app_bar/custom_semicircle.dart';
import 'package:app/screens/home/bottom_app_bar/start_stop_button.dart';
import 'package:flutter/material.dart';

class CustomBottomAppBar extends StatefulWidget {
  final VoidCallback onMenuPressed;

  const CustomBottomAppBar({super.key, required this.onMenuPressed});

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
                    child: StartStopButton(),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            top: 0,
            child: RepaintBoundary(
              key: const ValueKey('score_boundary'),
              child: CustomSemicircle(),
            ),
          ),
        ],
      ),
    );
  }
}
