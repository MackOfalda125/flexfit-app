import 'package:flutter/material.dart';
import 'package:app/core/constants.dart';

class CustomSemicircle extends StatelessWidget {
  final double score;

  const CustomSemicircle({super.key, required this.score});

  @override
  Widget build(BuildContext context) {
    return ClipPath(
      clipper: _SemicircleClipper(),
      child: Container(
        width: 160,
        height: 80,
        decoration: ShapeDecoration(
          color: Colors.green, //AppColors.primaryShadow,
          shape: OvalBorder(
            side: BorderSide(width: 7, color: AppColors.primaryBackground),
          ),
          shadows: [AppShadows.appBarShadow],
        ),
      ),
    );
  }
}

class _SemicircleClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.moveTo(0, size.height);
    path.arcToPoint(
      Offset(size.width, size.height),
      radius: Radius.elliptical(size.width / 2, size.height),
      clockwise: false,
    );
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}
