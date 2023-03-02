import 'package:flutter/material.dart';

class ScreenBodyLayout extends StatelessWidget {
  const ScreenBodyLayout({
    super.key,
    required this.children,
    this.withScrollView = true,
    this.mainAxisAlignment = MainAxisAlignment.start,
    this.crossAxisAlignment = CrossAxisAlignment.center,
    this.flexSides = 1,
    this.padding = const EdgeInsets.only(top: 15, bottom: 15),
  });

  final List<Widget> children;
  final bool withScrollView;
  final MainAxisAlignment mainAxisAlignment;
  final CrossAxisAlignment crossAxisAlignment;
  final int flexSides;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: withScrollView
          ? SingleChildScrollView(
              child: Padding(
                  padding: padding,
                  child: Row(
                    children: [
                      Expanded(flex: flexSides, child: Container()),
                      Expanded(
                        flex: 18,
                        child: Column(
                          mainAxisAlignment: mainAxisAlignment,
                          crossAxisAlignment: crossAxisAlignment,
                          children: children,
                        ),
                      ),
                      Expanded(flex: flexSides, child: Container()),
                    ],
                  )),
            )
          : Padding(
              padding: const EdgeInsets.only(top: 15, bottom: 15),
              child: Row(
                children: [
                  Expanded(flex: 1, child: Container()),
                  Expanded(
                    flex: 18,
                    child: Column(
                      mainAxisAlignment: mainAxisAlignment,
                      crossAxisAlignment: crossAxisAlignment,
                      children: children,
                    ),
                  ),
                  Expanded(flex: 1, child: Container()),
                ],
              )),
    );
  }
}
