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
            ),
            child: SvgPicture.asset(
              fit: BoxFit.cover,
              svgPath,
            )),
      ),
    ]);
  }
}
