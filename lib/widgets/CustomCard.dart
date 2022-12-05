import 'package:flutter/material.dart';
import 'package:owner_chip_admin_demo/themes/BlueTheme.dart';

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
    this.borderRadius = 13,
  });

  final List<Widget> children;
  final double? height;
  final double? width;
  final EdgeInsetsGeometry? margin;
  final Color? color;
  final MainAxisAlignment mainAxisAlignment;
  final CrossAxisAlignment crossAxisAlignment;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    final BlueStyle blueStyle = Theme.of(context).extension<BlueStyle>()!;

    return Container(
      height: height,
      width: width,
      margin: margin,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
          color: color ?? Theme.of(context).cardColor,
          border: Border.all(color: blueStyle.borderColor!, width: 1),
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
