// lib/widgets/skeleton_loader.dart

import 'package:flutter/material.dart';

class Skeleton extends StatelessWidget {
  const Skeleton({super.key, this.height, this.width, this.radius = 16});

  final double? height, width;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      width: width,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.08),
        borderRadius: BorderRadius.all(Radius.circular(radius)),
      ),
    );
  }
}