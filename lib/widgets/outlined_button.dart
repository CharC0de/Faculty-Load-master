import 'package:flutter/material.dart';

class MyOutlinedButton extends StatelessWidget {
  final Widget? child;

  final void Function()? onTap;

  const MyOutlinedButton({super.key, this.child, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 60,
        height: 60,
        child: Card(
          elevation: 5,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(50.0),
          ),
          child: Padding(
            padding: const EdgeInsets.all(7.5),
            child: child,
          ),
        ),
      ),
    );
  }
}
