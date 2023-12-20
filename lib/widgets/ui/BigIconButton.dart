import 'package:flutter/material.dart';
import 'package:ownerchip_whitelabel/themes/colorSpecs.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:ownerchip_whitelabel/widgets/ui/CustomCard.dart';

class BigIconButton extends StatelessWidget {
  BigIconButton({
    super.key,
    required this.text,
    required this.onPressed,
    required this.icon,
    this.height = 60,
    // this.width = double.infinity,
    this.backgroundColor,
    this.borderColor,
    this.textStyle,
    this.mainAxisAlignment = MainAxisAlignment.center,
    this.crossAxisAlignment = CrossAxisAlignment.center,
    this.showShadow = true,
  });

  final String text;
  final VoidCallback onPressed;
  final Icon icon;
  final double height;
  // final double? width;
  final Color? backgroundColor;
  final Color? borderColor;
  final MainAxisAlignment mainAxisAlignment;
  final CrossAxisAlignment crossAxisAlignment;
  TextStyle? textStyle;
  final bool? showShadow;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
        onTap: onPressed,
        child: SizedBox(
          // width: width,
          height: height,
          child: CustomCard(
              // color: CustomColors(dotenv.get('APP_ID')).secondaryColor,
              margin: const EdgeInsets.only(
                top: 5.0,
                bottom: 5.0,
              ),
              padding: const EdgeInsets.all(7),
              children: [
                icon,
                Text(text,
                    style: textStyle ?? Theme.of(context).textTheme.bodySmall!),
              ]),
        ));
  }
}
