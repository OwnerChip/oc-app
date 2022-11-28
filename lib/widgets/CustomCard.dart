import 'package:flutter/material.dart';

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
  });

  final List<Widget> children;
  final double? height;
  final double? width;
  final EdgeInsetsGeometry? margin;
  final Color? color;
  final MainAxisAlignment mainAxisAlignment;
  final CrossAxisAlignment crossAxisAlignment;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      width: width,
      margin: margin,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
          color: color == null ? Theme.of(context).cardColor : color,
          border: Border.all(
              color: Color.fromARGB(255, 249, 247, 247),
              width: 1), //TODO: externalize border color to theme
          borderRadius: BorderRadius.circular(13),
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
