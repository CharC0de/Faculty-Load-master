import 'package:flutter/material.dart';

class TopImage extends StatelessWidget {
  final double size;
  const TopImage({
    Key? key,
    required this.imgPath, required this.size,
  }) : super(key: key);

  final String imgPath;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      imgPath,
      height: size,
      width: size,
    );
  }
}
