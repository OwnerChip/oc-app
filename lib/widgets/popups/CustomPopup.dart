import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:ownerchip_whitelabel/themes/colorSpecs.dart';
import 'package:ownerchip_whitelabel/themes/fontSpecs.dart';
import 'package:ownerchip_whitelabel/widgets/ui/confetti/confettiWrapper.dart';

Future<T> showCustomPopup<T>(
  BuildContext context,
  String title,
  Widget content, {
  Widget? icon,
  TextStyle? titleTextStyle,
  EdgeInsets? titlePadding,
  VoidCallback? setShippingPopupIsShownState,
  bool showCloseButton = true,
  bool showConfetti = false,
}) async {
  setShippingPopupIsShownState?.call();

  return showDialog<T>(
    context: context,
    builder: (BuildContext context) {
      final dialog = AlertDialog(
        backgroundColor: Theme.of(context).cardColor,
        //border radius
        shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(20.0))),
        contentPadding: EdgeInsets.zero,
        content: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (icon != null) icon,
                  const SizedBox(
                    height: 8,
                  ),
                  Padding(
                    padding: titlePadding ?? EdgeInsets.zero,
                    child: Text(
                      title,
                      style: titleTextStyle ??
                          Theme.of(context).textTheme.bodyLarge!.copyWith(
                                fontSize: CustomFonts(dotenv.get('APP_ID'))
                                    .metadataNameFontSize,
                                fontWeight: CustomFonts(dotenv.get('APP_ID'))
                                    .metadataNameFontWeight,
                              ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(
                    height: 8,
                  ),
                  content,
                ],
              ),
            ),
            if (showCloseButton)
              Positioned(
                right: 4.0,
                top: 4.0,
                child: IconButton(
                  icon: Icon(
                    Icons.close,
                    size: 32,
                    color: CustomColors(dotenv.get('APP_ID')).black.withOpacity(
                          0.5,
                        ),
                  ),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
              ),
          ],
        ),
      );

      if (showConfetti) {
        return ConfettiWrapper(child: dialog);
      }

      return dialog;
    },
  ).then((value) {
    setShippingPopupIsShownState?.call();
    return value as T;
  });
}
