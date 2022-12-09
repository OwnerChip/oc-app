import 'package:flutter/material.dart';
import '../themes/customColors.dart';

//Card widget that can take multiple children
class CustomCard extends StatelessWidget {
  const CustomCard({
    super.key,
    required this.children,
    this.height,
    this.width,
    this.margin,
    this.color,
    this.mainAxisAlignment = MainAxisAlignment.start,
    this.crossAxisAlignment = CrossAxisAlignment.center,
    this.borderColor,
    this.borderRadius = 13,
  });

  final List<Widget> children;
  final double? height;
  final double? width;
  final EdgeInsetsGeometry? margin;
  final Color? color;
  final MainAxisAlignment mainAxisAlignment;
  final CrossAxisAlignment crossAxisAlignment;
  final Color? borderColor;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      width: width,
      margin: margin,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
          color: color ?? Theme.of(context).cardColor,
          border: Border.all(
              color: borderColor ?? CustomColors.borderColor!, width: 1),
          borderRadius: BorderRadius.circular(borderRadius),
          boxShadow: [
            BoxShadow(
                color: Theme.of(context).shadowColor,
                blurRadius: 5,
                offset: const Offset(3, 4)),
          ]),
      child: Column(
          mainAxisAlignment: mainAxisAlignment,
          crossAxisAlignment: crossAxisAlignment,
          children: children),
    );
  }
}
