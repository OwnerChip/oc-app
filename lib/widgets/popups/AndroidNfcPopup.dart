import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:nfc_manager/nfc_manager.dart';
import 'package:ownerchip_whitelabel/themes/colorSpecs.dart';
import 'package:ownerchip_whitelabel/utils/localization.helper.dart';
import 'package:ownerchip_whitelabel/widgets/animations/NfcAnimation.dart';
import 'package:ownerchip_whitelabel/widgets/ui/CustomRoundedButton.dart';

class NFCOverlay {
  OverlayEntry? overlayEntry;

// A function to show the snackbar as an overlay entry
  void showNfcOverlay(
    BuildContext context,
    String message,
    VoidCallback? onExit,
  ) {
    // Create an overlay entry widget with a custom content and animation
    overlayEntry = OverlayEntry(
      builder: (context) {
        // Use a TweenAnimationBuilder as the content parameter
        return Stack(children: [
          Positioned.fill(
              child: Container(
            decoration: const BoxDecoration(
              color: Colors.black54,
            ),
          )),
          Positioned(
              bottom: 10,
              left: 5,
              width: MediaQuery.of(context).size.width - 10,
              height: 300,
              child: TweenAnimationBuilder(
                tween: Tween<double>(begin: 0.0, end: 1.0),
                duration: const Duration(milliseconds: 250),
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
                      borderRadius:
                          const BorderRadius.all(Radius.circular(20))),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // The NFC animation widget
                      const NFCAnimation(),

                      const SizedBox(height: 8.0),
                      // A text that instructs the user
                      Text(
                        message,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                              color: CustomColors(dotenv.get('APP_ID'))
                                  .primaryColor,
                            ),
                      ),
                      const SizedBox(height: 30),
                      Padding(
                          padding: const EdgeInsets.only(left: 10, right: 10),
                          child: CustomRoundedButton(
                              showShadow: false,
                              backgroundColor: Colors.black26,
                              text: context.loc.cancel,
                              onPressed: () {
                                // Dismiss the snackbar when the user taps the button
                                removeNfcOverlay();
                                try {
                                  NfcManager.instance.stopSession();
                                } catch (_) {
                                  // Ignore if no active session
                                }
                                onExit?.call();
                              }))
                    ],
                  ),
                ),
              ))
        ]);
      },
    );

    Overlay.of(context).insert(overlayEntry!);
  }

  void removeNfcOverlay() {
    overlayEntry!.remove();
  }
}
