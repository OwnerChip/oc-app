import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class CustomRoundedButton extends StatelessWidget {
  const CustomRoundedButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.icon,
    this.width = double.infinity,
    this.mainAxisAlignment = MainAxisAlignment.center,
    this.crossAxisAlignment = CrossAxisAlignment.center,
  });

  final String text;
  final VoidCallback? onPressed;
  final Icon? icon; //TODO: Make this SVG to use custom marta icons
  final double width;
  final MainAxisAlignment mainAxisAlignment;
  final CrossAxisAlignment crossAxisAlignment;

  @override
  Widget build(BuildContext context) {
    bool isActive = true;

    return Container(
      width: width,
      height: 40,
      child: ElevatedButton(
          onPressed: (() =>
              (onPressed != null) ? onPressed!() : isActive = false),
          style: ElevatedButton.styleFrom(
            backgroundColor: isActive
                ? Theme.of(context).primaryColor
                : Theme.of(context).backgroundColor, //TODO: This does not work
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(9),
            ),
          ),
          child: Row(
            mainAxisAlignment: mainAxisAlignment,
            crossAxisAlignment: crossAxisAlignment,
            children: [
              icon != null ? icon! : Container(),
              //spacing
              const SizedBox(width: 10),
              Text(
                text,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w400,
                ),
              )
            ],
          )),
    );
  }
}
