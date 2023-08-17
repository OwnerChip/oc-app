import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:nfc_manager/nfc_manager.dart';
import 'package:ownerchip_whitelabel/themes/colorSpecs.dart';
import 'package:ownerchip_whitelabel/widgets/ui/NfcAnimation.dart';

// A function to show the snackbar
SnackBar showNfcSnackbar(ScaffoldMessengerState scaffoldMessengerState) {
  // Return a snackbar widget with a custom content and animation
  return SnackBar(
      dismissDirection: DismissDirection.none,
      backgroundColor: Colors.transparent,
      duration: const Duration(minutes: 5),
      behavior: SnackBarBehavior.floating,
      elevation: 0,
      // Use a TweenAnimationBuilder as the content parameter
      content: TweenAnimationBuilder(
        tween: Tween<double>(begin: 0.0, end: 1.0),
        duration: const Duration(milliseconds: 150),
        builder: (context, value, child) {
          // Calculate the position and opacity of the snackbar based on the animation value
          final offset = (1 - value) * 100;
          final opacity = value.clamp(0.0, 1.0);
          return Opacity(
            opacity: opacity,
            child: Transform.translate(
              offset: Offset(0, offset),
              child: child,
            ),
          );
        },
        // Use the Container widget as the child parameter
        child: Container(
          decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.all(Radius.circular(20))),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // The NFC animation widget
              const NFCAnimation(),

              // Add more spacing between the icon and the text
              const SizedBox(height: 8.0),
              // A text that instructs the user
              const Text(
                'Hold your phone close to the NFC chip',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.black54),
              ),
              // A divider to separate the content and the button
              const Divider(),
              // An InkWell widget to make the button clickable
              InkWell(
                onTap: () {
                  // Dismiss the snackbar when the user taps the button
                  scaffoldMessengerState.hideCurrentSnackBar();

                  NfcManager.instance.stopSession();
                },
                child: Container(
                  padding: const EdgeInsets.all(16.0),
                  alignment: Alignment.center,
                  child: const Text(
                    'Cancel',
                    style: TextStyle(
                      color: Colors.black45,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ));
}
