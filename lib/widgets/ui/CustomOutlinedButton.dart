import 'package:flutter/material.dart';
import 'package:ownerchip_whitelabel/themes/colorSpecs.dart';

class CustomOutlinedButton extends StatelessWidget {
  final double width;
  final double height;
  final VoidCallback onPressed;
  final String buttonText;

  // Use default values for width and height if not provided
  const CustomOutlinedButton({
    super.key,
    this.width = 250,
    this.height = 40,
    required this.onPressed,
    required this.buttonText,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18.0),
          ),
          side: BorderSide(
              width: 2, color: CustomColors('ownerchip').primaryColor),
        ),
        onPressed: onPressed,
        child: Text(
          buttonText,
          style: TextStyle(color: CustomColors('ownerchip').primaryColor),
        ),
      ),
    );
  }
}
