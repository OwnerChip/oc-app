import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:ownerchip_whitelabel/themes/colorSpecs.dart';

class NFCAnimation extends StatefulWidget {
  const NFCAnimation({Key? key}) : super(key: key);

  @override
  _NFCAnimationState createState() => _NFCAnimationState();
}

class _NFCAnimationState extends State<NFCAnimation>
    with SingleTickerProviderStateMixin {
  // A controller for the animation
  late final AnimationController _controller;

  // A linear animation that goes from 0.0 to 1.0 in 2 seconds
  late final Animation<double> _animation;

  // A boolean flag to indicate whether to show the phone icon or the checkmark icon
  bool showPhone = true;

  @override
  void initState() {
    super.initState();
    // Initialize the controller with a duration of 2 seconds
    _controller = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );

    // Initialize the animation with a curve of easeInOut
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );

    // Repeat the animation indefinitely
    _controller.repeat();
  }

  @override
  void dispose() {
    // Dispose the controller when the widget is disposed
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        // Calculate the icon's rotation angle based on the animation value
        final angle = -0.6 +
            (1.2 *
                _animation
                    .value); // Increase the range and amplitude of the tilt

        return Padding(
          // Add more padding top and bottom to the widget
          padding: const EdgeInsets.symmetric(vertical: 16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // A phone icon or a checkmark icon that rotates around its center inside a circle
              Container(
                // Use a circle shape for the container
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                  border: Border.all(
                    color: CustomColors(dotenv.get('APP_ID'))
                        .androidNfcAnimationColor,
                    width: 4.0,
                  ),
                ),
                padding: const EdgeInsets.all(8.0),
                child: Transform(
                  // Use a matrix to rotate the icon around the x-axis
                  transform: Matrix4.rotationX(angle),
                  alignment: Alignment.center,
                  child: AnimatedSwitcher(
                    // Use an AnimatedSwitcher to animate the change of the icon
                    duration: const Duration(milliseconds: 300),
                    transitionBuilder: (child, animation) => ScaleTransition(
                      // Use a ScaleTransition to scale the icon in and out
                      scale: animation,
                      child: child,
                    ),
                    child: Icon(
                      // Use a ternary operator to choose the icon based on the showPhone flag
                      showPhone ? Icons.phone_android : Icons.check_circle,
                      key: ValueKey(
                          showPhone), // Use a ValueKey to distinguish between different icons
                      size: 96,
                      color: CustomColors(dotenv.get('APP_ID'))
                          .androidNfcAnimationColor,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // A function to trigger the change of the icon
  void changeIcon() {
    // Use setState to update the showPhone flag and rebuild the widget
    setState(() {
      showPhone = !showPhone;
    });
  }
}
