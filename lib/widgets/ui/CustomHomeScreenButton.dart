import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:ownerchip_whitelabel/themes/colorSpecs.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class CustomHomeScreenButton extends StatelessWidget {
  const CustomHomeScreenButton({
    super.key,
    required this.text,
    required this.onTap,
    required this.svgPath,
    this.size = double.infinity,
  });

  final String text;
  final VoidCallback? onTap;
  final String svgPath;
  final double? size;

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      GestureDetector(
        onTap: () => onTap!(),
        child: Container(
            padding: EdgeInsets.zero,
            //boxshadow
            decoration: BoxDecoration(
              // color: Theme.of(context).primaryColor,
              borderRadius: BorderRadius.circular(13),
              boxShadow: [
                BoxShadow(
                  color: CustomColors(dotenv.get('APP_ID'))
                      .customHomeScreenButtonShadowColor,
                  blurRadius: 5,
                  offset: const Offset(3, 4),
                ),
              ],
            ),
            child: SvgPicture.asset(
              fit: BoxFit.cover,
              svgPath,
            )),
      ),
      const SizedBox(height: 10),
      Text(
        text,
        style: Theme.of(context).textTheme.displaySmall,
      )
    ]);
  }
}
