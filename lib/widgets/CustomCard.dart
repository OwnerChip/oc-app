import 'package:flutter/material.dart';
import 'package:ownerchip_whitelabel/themes/colorSpecs.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

//Card widget that can take multiple children
class CustomCard extends StatelessWidget {
  const CustomCard({
    super.key,
    required this.children,
    this.height,
    this.width,
    this.maxHeight = double.infinity,
    this.maxWidth = double.infinity,
    this.margin,
    this.color,
    this.mainAxisSize = MainAxisSize.max,
    this.mainAxisAlignment = MainAxisAlignment.start,
    this.crossAxisAlignment = CrossAxisAlignment.center,
    this.borderColor,
    this.borderRadius = 13,
    this.withScrollView = false,
  });

  final List<Widget> children;
  final double? height;
  final double? width;
  final double maxHeight;
  final double maxWidth;
  final EdgeInsetsGeometry? margin;
  final Color? color;
  final MainAxisAlignment mainAxisAlignment;
  final CrossAxisAlignment crossAxisAlignment;
  final MainAxisSize mainAxisSize;
  final Color? borderColor;
  final double borderRadius;
  final bool withScrollView;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(maxWidth: maxWidth, maxHeight: maxHeight),
      height: height,
      width: width,
      margin: margin,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
          color: color ?? Theme.of(context).cardColor,
          border: Border.all(
              color: borderColor ??
                  CustomColors(dotenv.get('APP_ID')).borderColor!,
              width: 1),
          borderRadius: BorderRadius.circular(borderRadius),
          boxShadow: [
            BoxShadow(
                color: Theme.of(context).shadowColor,
                blurRadius: 5,
                offset: const Offset(3, 4)),
          ]),
      child: withScrollView
          ? SingleChildScrollView(
              child: Column(
                  mainAxisAlignment: mainAxisAlignment,
                  crossAxisAlignment: crossAxisAlignment,
                  mainAxisSize: mainAxisSize,
                  children: children),
            )
          : Column(
              mainAxisAlignment: mainAxisAlignment,
              crossAxisAlignment: crossAxisAlignment,
              mainAxisSize: mainAxisSize,
              children: children),
    );
  }
}
