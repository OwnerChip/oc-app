import 'package:flutter/material.dart';

class CustomIconButton extends StatelessWidget {
  CustomIconButton({super.key, required this.icon, required this.onPressed});

  final Icon icon; //TODO: change to SVG for custom icons
  final Function onPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      child: ElevatedButton(
        onPressed: (() => onPressed()),
        style: ElevatedButton.styleFrom(
          backgroundColor: Theme.of(context).primaryColor,
          shape: const CircleBorder(),
        ),
        child: icon,
      ),
    );
  }
}
