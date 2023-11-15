import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:ownerchip_whitelabel/themes/fontSpecs.dart';

Future<void> showCustomPopup(
    BuildContext context, String title, Widget content) async {
  return showDialog<void>(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
          backgroundColor: Theme.of(context).cardColor,
          //border radius
          shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(20.0))),
          title: Padding(
            padding: EdgeInsets.only(),
            child: Text(
              title,
              textAlign: TextAlign.center,
            ),
          ),
          titleTextStyle: Theme.of(context).textTheme.bodyLarge!.copyWith(
              fontSize: CustomFonts(dotenv.get('APP_ID')).metadataNameFontSize,
              fontWeight:
                  CustomFonts(dotenv.get('APP_ID')).metadataNameFontWeight),
          content: content);
    },
  );
}
