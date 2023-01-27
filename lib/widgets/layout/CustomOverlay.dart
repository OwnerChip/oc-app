import 'package:flutter/material.dart';

class CustomOverlay extends StatelessWidget {
  const CustomOverlay({
    Key? key,
    required this.show,
    this.opacity = 0.5,
    this.color = Colors.grey,
    this.dismissible = false,
    required this.child,
    required this.content,
  }) : super(key: key);

  final bool show;
  final double opacity;
  final Color color;
  final bool dismissible;
  final Widget child;
  final Widget content;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        if (show)
          Positioned.fill(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            child: IgnorePointer(
              ignoring: dismissible,
              child: Container(
                color: color.withOpacity(opacity),
                child: Center(
                  child: content,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
