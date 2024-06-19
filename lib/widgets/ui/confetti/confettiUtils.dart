import 'dart:math';

import 'package:flutter/material.dart';
import 'package:path_drawing/path_drawing.dart';

class ConfettiUtils {

  static Path drawPath(Size size) {
    return _draws[Random.secure().nextInt(_draws.length)].call(size);
  }


  static final List<Path Function(Size)> _draws = [
    // _drawStar,
    // _drawCircle,
    // _drawSquare,
    // _drawRectangle,
    // _drawTriangle,
    // _drawHeart,
    _drawJaggedy,
    _drawLoopie,
    _drawMoonBig,
    _drawMoonSmall,
    _drawCircleBig,
    _drawCircleSmall,
    _drawSquareSlim,
    _drawSquareSmall,
    _drawSquareBig,
    _drawSquiggly,
  ];

  static final Path _moonBigPath = parseSvgPathData(
      "M8.91481 10.6028C9.97445 15.6246 17.505 17.6465 12.8625 19.0723C8.21997 20.4982 3.59743 17.5832 2.53779 12.5614C1.47815 7.53968 4.38266 2.31285 9.02521 0.886972C13.6677 -0.538905 7.85516 5.58109 8.91481 10.6028Z");

  static Path _drawMoonBig(Size size) => _moonBigPath;

  static final Path _moonSmall = parseSvgPathData(
      "M6.37834 9.42652C9.16261 10.2333 12.4915 5.50325 11.7457 9.24982C10.9998 12.9964 8.13813 15.3796 5.35386 14.5728C2.56959 13.7661 0.917119 10.0749 1.66295 6.3283C2.40879 2.58172 3.59408 8.61976 6.37834 9.42652Z");

  static Path _drawMoonSmall(Size size) => _moonSmall;

  static final Path _sircleBig = parseSvgPathData(
      "M0.8007799999999996,7.77691a6.04884,7.29766 0 1,0 12.09768,0a6.04884,7.29766 0 1,0 -12.09768,0");

  static Path _drawCircleBig(Size size) => _sircleBig;

  static final Path _circleSmall = parseSvgPathData(
      "M0,3.09764a2.62805,3.09764 0 1,0 5.2561,0a2.62805,3.09764 0 1,0 -5.2561,0");

  static Path _drawCircleSmall(Size size) => _circleSmall;

  static final Path _squareSlim = parseSvgPathData("M0 0h23.5788v7.4548H0Z");

  static Path _drawSquareSlim(Size size) => _squareSlim;

  static final Path _squareSmall = parseSvgPathData("M0 0h5.7516v9.5637H0Z");

  static Path _drawSquareSmall(Size size) => _squareSmall;

  static final Path _squareBig = parseSvgPathData("M0 0h19.1816v9.5589H0Z");

  static Path _drawSquareBig(Size size) => _squareBig;

  static final Path _jaggedy = parseSvgPathData(
      "M -9.26 12.3 C -8.498 12.627 2.852 12.406 2.934 12.488 C 2.934 12.488 -4.448 21.831 -4.422 21.822 C -4.31 21.784 5.386 21.608 5.347 21.608 C 5.285 21.608 -0.052 27.637 -0.03 27.705 C 0.023 27.871 7.713 29.526 8.03 29.842 C 7.927 30.078 7.007 31.152 6.723 31.431 C 6.722 31.432 -3.122 28.702 -3.222 28.602 C -3.252 28.572 1.494 23.57 1.491 23.384 C 1.491 23.367 -7.267 23.364 -7.311 23.321 C -7.444 23.187 -0.594 14.632 -0.629 14.598 C -0.681 14.546 -9.131 14.513 -9.499 14.513 C -9.32 14.441 -9.263 12.3 -9.26 12.3 Z");

  static Path _drawJaggedy(Size size) {
    return _jaggedy;
  }

  static final Path _squiggly = parseSvgPathData(
      "M -29.043 30.255 C -29.559 29.321 -26.833 24.081 -24.856 24.2 C -23.185 24.301 -21.956 30.41 -20.857 30.302 C -19.926 30.21 -20.731 25.194 -19.689 23.766 C -18.41 22.014 -15.589 23.065 -14.601 24.554 C -14.066 25.362 -13.465 26.583 -13.465 27.503 C -13.78 28.057 -13.883 28.121 -14.538 27.809 C -15.193 27.497 -17.305 24.35 -17.827 24.824 C -18.79 25.7 -19.004 30.127 -19.014 30.667 C -19.05 32.544 -21.355 33.007 -22.042 31.883 C -22.31 31.445 -25.133 25.74 -25.355 25.869 C -26.464 26.512 -27.493 29.512 -27.622 30.703 C -28.327 30.975 -28.934 30.453 -29.043 30.255 Z");

  static Path _drawSquiggly(Size size) => _squiggly;

  static final Path _loopie = parseSvgPathData(
      "M 3.78 30.057 C 8.316 23.407 -0.497 18.626 -3.261 17.569 C -4.282 17.179 -6.964 15.486 -6.152 14.605 C -5.728 13.742 -3.26 15.195 -2.361 15.644 C 1.059 17.353 4.696 19.549 6.141 23.251 C 6.774 24.873 7.583 30.974 5.386 31.787 C 3.598 32.448 -1.204 30.133 -1.734 28.203 C -2.346 25.976 -1.609 24.353 0.358 21.995 C 2.291 19.678 6.597 17.849 8.32 17.743 C 10.416 17.614 17.584 17.531 17.163 19.784 C 16.556 21.475 12.588 18.678 8.472 19.622 C 6.795 20.007 4.408 21.101 2.867 21.883 C 1.387 22.634 -0.269 24.986 -0.154 27.822 C -0.121 28.629 3.353 30.683 3.78 30.057 Z");

  static Path _drawLoopie(Size size) => _loopie;

  static Path _drawHeart(Size size) {
    double width = size.width;
    double height = size.height;

    Path path = Path();
    path.moveTo(0.5 * width, height * 0.35);
    path.cubicTo(0.2 * width, height * 0.1, -0.25 * width, height * 0.6,
        0.5 * width, height);
    path.moveTo(0.5 * width, height * 0.35);
    path.cubicTo(0.8 * width, height * 0.1, 1.25 * width, height * 0.6,
        0.5 * width, height);

    return path;
  }

  static Path _drawZigZag(Size size) {
    const double strokeWidth = 4;
    final height = size.height / 3;
    final width = size.width / 2;

    return Path()
      ..moveTo(0, 0)
      ..addPolygon([
        Offset(0, height),
        Offset(width / 4 - strokeWidth, 0),
        Offset(width / 4, 0),
        Offset(0 + strokeWidth, height)
      ], true)
      ..addPolygon([
        Offset(width / 4 - strokeWidth, 0),
        Offset(width / 4, 0),
        Offset(width / 2, height),
        Offset(width / 2 - strokeWidth, height)
      ], true)
      ..addPolygon([
        Offset(width / 2, height),
        Offset(width / 2 + width / 4 - strokeWidth, 0),
        Offset(width / 2 + width / 4, 0),
        Offset(width / 2 + strokeWidth, height),
      ], true)
      ..addPolygon([
        Offset(width / 2 + width / 4 - strokeWidth, 0),
        Offset(width / 2 + width / 4, 0),
        Offset(width, height),
        Offset(width - strokeWidth, height),
      ], true);
  }

  static Path _drawSquare(Size size) {
    return Path()
      ..lineTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..lineTo(0, 0);
  }

  static Path _drawTriangle(Size size) {
    return Path()
      ..moveTo(0, size.height)
      ..lineTo(size.width / 2, 0)
      ..lineTo(size.width, size.height);
  }

  static Path _drawRectangle(Size size) {
    return Path()
      ..lineTo(0, 0)
      ..lineTo(size.width / 2, 0)
      ..lineTo(size.width / 2, size.height)
      ..lineTo(0, size.height)
      ..lineTo(0, 0);
  }

  static Path _drawCircle(Size size) {
    return Path()
      ..addOval(
          Rect.fromCircle(center: const Offset(0, 0), radius: size.width / 2));
  }

  static Path _drawStar(Size size) {
    double degToRad(double deg) => deg * (pi / 180.0);

    const numberOfPoints = 5;
    final halfWidth = size.width / 2;
    final externalRadius = halfWidth;
    final internalRadius = halfWidth / 2.5;
    final degreesPerStep = degToRad(360 / numberOfPoints);
    final halfDegreesPerStep = degreesPerStep / 2;
    final path = Path();
    final fullAngle = degToRad(360);
    path.moveTo(size.width, halfWidth);

    for (double step = 0; step < fullAngle; step += degreesPerStep) {
      path.lineTo(halfWidth + externalRadius * cos(step),
          halfWidth + externalRadius * sin(step));
      path.lineTo(halfWidth + internalRadius * cos(step + halfDegreesPerStep),
          halfWidth + internalRadius * sin(step + halfDegreesPerStep));
    }
    path.close();
    return path;
  }
}
