import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ownerchip_whitelabel/themes/colorSpecs_ownerchip.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class CustomRoundedButton extends StatelessWidget {
  CustomRoundedButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.icon,
    this.height = 40,
    this.width = double.infinity,
    this.backgroundColor,
    this.textStyle,
    this.mainAxisAlignment = MainAxisAlignment.center,
    this.crossAxisAlignment = CrossAxisAlignment.center,
  });

  final String text;
  final VoidCallback? onPressed;
  final Icon? icon; //TODO: Make this SVG to use custom marta icons
  final double height;
  final double width;
  final Color? backgroundColor;
  final MainAxisAlignment mainAxisAlignment;
  final CrossAxisAlignment crossAxisAlignment;
  TextStyle? textStyle;

  @override
  Widget build(BuildContext context) {
    bool isActive = true;

    return Container(
      width: width,
      height: height,
      child: ElevatedButton(
          onPressed: (() =>
              (onPressed != null) ? onPressed!() : isActive = false),
          style: ElevatedButton.styleFrom(
            backgroundColor: backgroundColor ??
                CustomColors(dotenv.get('APP_ID')).primaryColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
          ),
          child: Row(
            mainAxisAlignment: mainAxisAlignment,
            crossAxisAlignment: crossAxisAlignment,
            children: [
              icon != null ? icon! : Container(),
              icon != null ? const SizedBox(width: 10) : Container(),
              Text(text,
                  style: textStyle ??
                      Theme.of(context).textTheme.bodyText1!.copyWith(
                          color: CustomColors(dotenv.get('APP_ID'))
                              .customRoundedButtonColor)),
            ],
          )),
    );
  }
}
