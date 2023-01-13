import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class ScanningLoader extends StatefulWidget {
  const ScanningLoader({Key? key}) : super(key: key);

  @override
  _ScanningLoaderState createState() => _ScanningLoaderState();
}

class _ScanningLoaderState extends State<ScanningLoader>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat(reverse: true);
    _animation = Tween<double>(begin: 0.2, end: 1).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Opacity(
          opacity: _animation.value,
          child: child,
        );
      },
      child: SvgPicture.asset(
        '${dotenv.get('IMAGE_ASSETS_BASE_URL')}/arrow_vertical.svg',
        height: 80.0,
      ),
    );
  }
}
