import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:ownerchip_whitelabel/themes/colorSpecs.dart';
import 'package:ownerchip_whitelabel/themes/fontSpecs.dart';

Future<void> showCustomPopup(
  BuildContext context,
  String title,
  Widget content, {
  Widget? icon,
  TextStyle? titleTextStyle,
  EdgeInsets? titlePadding,
  VoidCallback? setShippingPopupIsShownState,
  bool showCloseButton = true,
}) async {
  setShippingPopupIsShownState?.call();
  return showDialog<void>(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
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
    },
  ).then((value) {
    setShippingPopupIsShownState?.call();
  });
}
