import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'dart:math' as math;

class PopupLoader extends StatefulWidget {
  const PopupLoader(
      {Key? key, required String this.svgPath, this.rotateIcon = true})
      : super(key: key);
  final String svgPath;
  final bool rotateIcon;
  @override
  _PopupLoaderState createState() => _PopupLoaderState();
}

class _PopupLoaderState extends State<PopupLoader>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

//convert integer to double

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 3000),
      vsync: this,
    )..repeat();
    _animation = Tween<double>(begin: 0, end: 2).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.rotateIcon
        ? AnimatedBuilder(
            animation: _animation,
            builder: (context, child) {
              return Transform(
                transform: Matrix4.identity()
                  ..setEntry(3, 2, 0.005)
                  ..rotateY(_animation.value * math.pi),
                alignment: FractionalOffset.center,
                child: child,
              );
            },
            child: SvgPicture.asset(
              widget.svgPath,
              height: 100.0,
            ),
          )
        : SvgPicture.asset(
            widget.svgPath,
            height: 100.0,
          );
  }
}
