import 'package:flutter/material.dart';

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
      duration: const Duration(milliseconds: 900),
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
      child: Icon(
        Icons.wifi,
        color: Theme.of(context).primaryColor,
        size: 48.0,
        semanticLabel: 'Text to announce in accessibility modes',
      ),
    );
  }
}
