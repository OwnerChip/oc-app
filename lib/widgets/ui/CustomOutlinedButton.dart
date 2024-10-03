import 'package:flutter/material.dart';
import 'package:ownerchip_whitelabel/themes/colorSpecs.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class CustomOutlinedButton extends StatelessWidget {
  final double width;
  final double height;
  final VoidCallback onPressed;
  final String buttonText;
  final Color? color;

  final bool disabled;

  // Use default values for width and height if not provided
  const CustomOutlinedButton({
    super.key,
    this.width = 250,
    this.height = 40,
    required this.onPressed,
    required this.buttonText,
    this.color,
    this.disabled = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 200),
        opacity: disabled ? 0.5 : 1,
        child: OutlinedButton(
          style: OutlinedButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18.0),
            ),
            side: BorderSide(
                width: 2,
                color: color != null
                    ? color!
                    : CustomColors(dotenv.get('APP_ID')).primaryColor),
          ),
          onPressed: disabled ? null : onPressed,
          child: Text(
            buttonText,
            style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                color: color != null
                    ? color!
                    : CustomColors(dotenv.get('APP_ID')).primaryColor),
          ),
        ),
      ),
    );
  }
}
