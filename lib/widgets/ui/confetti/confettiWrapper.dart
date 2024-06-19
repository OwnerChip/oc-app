import 'dart:math';

import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:ownerchip_whitelabel/widgets/ui/confetti/confettiUtils.dart';

class ConfettiWrapper extends StatefulWidget {
  const ConfettiWrapper({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  State<ConfettiWrapper> createState() => _ConfettiWrapperState();
}

class _ConfettiWrapperState extends State<ConfettiWrapper> {
  late final ConfettiController _confettiControllerTopCenter;
  late final ConfettiController _confettiControllerTopLeft;
  late final ConfettiController _confettiControllerTopRight;

  @override
  void initState() {
    super.initState();

    _confettiControllerTopCenter =
        ConfettiController(duration: const Duration(seconds: 1));
    _confettiControllerTopRight =
        ConfettiController(duration: const Duration(seconds: 1));
    _confettiControllerTopLeft =
        ConfettiController(duration: const Duration(seconds: 1));

    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) {
        _confettiControllerTopCenter.play();
        _confettiControllerTopLeft.play();
        _confettiControllerTopRight.play();
      }
    });
  }

  @override
  void dispose() {
    _confettiControllerTopCenter.dispose();
    _confettiControllerTopRight.dispose();
    _confettiControllerTopLeft.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        _buildConfetti(
            confettiController: _confettiControllerTopCenter,
            alignment: Alignment.topCenter,
            draw: ConfettiUtils.drawPath,
            colors: _confettiColors),
        _buildConfetti(
            confettiController: _confettiControllerTopLeft,
            alignment: Alignment.topLeft,
            draw: ConfettiUtils.drawPath,
            colors: _confettiColors),
        _buildConfetti(
            confettiController: _confettiControllerTopRight,
            alignment: Alignment.topRight,
            draw: ConfettiUtils.drawPath,
            colors: _confettiColors)
      ],
    );
  }

  final List<Color> _confettiColors = [
    Colors.blue,
    Colors.green,
    Colors.orange,
    Colors.purple,
    Colors.red,
    Colors.yellow
  ];

  Widget _buildConfetti(
      {required ConfettiController confettiController,
      required Alignment alignment,
      required Path Function(Size) draw,
      int numberOfParticles = 150,
      List<Color> colors = const [Colors.black12]}) {
    return Align(
      alignment: alignment,
      child: ConfettiWidget(
        confettiController: confettiController,
        blastDirection: pi / 2,
        maxBlastForce: 16,
        minBlastForce: 12,
        particleDrag: 0.04,
        emissionFrequency: 0,
        minimumSize: const Size(2, 2),
        maximumSize: const Size(20, 20),
        numberOfParticles: numberOfParticles,
        gravity: 0.4,
        shouldLoop: false,
        blastDirectionality: BlastDirectionality.explosive,
        createParticlePath: draw,
        colors: colors,
      ),
    );
  }
}
