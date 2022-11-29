import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'dart:math' as math;

class SpinningLoader extends StatefulWidget {
  const SpinningLoader({Key? key}) : super(key: key);

  @override
  _SpinningLoaderState createState() => _SpinningLoaderState();
}

class _SpinningLoaderState extends State<SpinningLoader>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 900),
      vsync: this,
    )..repeat(reverse: false);
    _animation = Tween<double>(begin: 0.2, end: 1).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: AnimatedBuilder(
          animation: _controller,
          builder: (_, child) {
            return Transform.rotate(
              angle: _controller.value * 2 * math.pi,
              child: child,
            );
          },
          child: SvgPicture.asset(
            'assets/images/chip_dark_blue.svg',
            width: 90.0,
            height: 135.0,
          )),
    );
  }
}
