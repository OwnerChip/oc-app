import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:ownerchip_whitelabel/themes/fontSpecs.dart';

Future<void> showCustomPopup(BuildContext context, String title, Widget content,
    {Widget? icon,
    TextStyle? titleTextStyle,
    EdgeInsets? titlePadding,
    VoidCallback? setShippingPopupIsShownState}) async {
  setShippingPopupIsShownState?.call();
  return showDialog<void>(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
          icon: icon,
          backgroundColor: Theme.of(context).cardColor,
          //border radius
          shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(20.0))),
          title: Padding(
            padding: titlePadding ?? EdgeInsets.only(),
            child: Text(
              title,
              textAlign: TextAlign.center,
            ),
          ),
          titleTextStyle: titleTextStyle ??
              Theme.of(context).textTheme.bodyLarge!.copyWith(
                  fontSize:
                      CustomFonts(dotenv.get('APP_ID')).metadataNameFontSize,
                  fontWeight:
                      CustomFonts(dotenv.get('APP_ID')).metadataNameFontWeight),
          content: content);
    },
  ).then((value) {
    setShippingPopupIsShownState?.call();
  });
}
