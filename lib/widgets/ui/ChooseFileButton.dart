import 'package:flutter/material.dart';
import 'package:ownerchip_whitelabel/screens/AddAttachmentScreen.dart';
import 'package:ownerchip_whitelabel/themes/colorSpecs.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:ownerchip_whitelabel/themes/fontSpecs.dart';
import 'package:ownerchip_whitelabel/utils/navigationArguments.dart';
import '../../domain/classDefinition.dart';

import '../../utils/localization.helper.dart';
import 'CustomRoundedButton.dart';

class ChooseFileButton extends StatelessWidget {
  ChooseFileButton(
      {super.key,
      required this.text,
      required this.openFileExplorerFunction,
      required this.openGalleryFunction,
      this.showOptions = true});

  final String text;
  final bool showOptions;
  final Function openFileExplorerFunction;
  final Function openGalleryFunction;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<int>(
      constraints: const BoxConstraints(minWidth: double.infinity),
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
          side: BorderSide(
              color: CustomColors(dotenv.get('APP_ID')).primaryColorLight)),
      padding: EdgeInsets.all(0),
      position: PopupMenuPosition.under,
      initialValue: null,
      onSelected: (int value) {
        if (value == 0) {
          openFileExplorerFunction();
        } else {
          openGalleryFunction();
        }
      },
      itemBuilder: (BuildContext context) => <PopupMenuEntry<int>>[
        PopupMenuItem<int>(
          value: 0,
          child: Container(
              alignment: Alignment.center,
              width: double.infinity,
              child: Text(context.loc.chooseFile,
                  style: TextStyle(
                      color: CustomColors(dotenv.get('APP_ID')).primaryColor))),
        ),
        const PopupMenuDivider(),
        PopupMenuItem<int>(
          value: 1,
          child: Container(
              alignment: Alignment.center,
              width: double.infinity,
              child: Text(context.loc.viewGallery,
                  style: TextStyle(
                      color: CustomColors(dotenv.get('APP_ID')).primaryColor))),
        ),
      ],
      child: Container(
        padding:
            const EdgeInsets.only(left: 10, right: 10, top: 15, bottom: 15),
        decoration: BoxDecoration(
            color: CustomColors(dotenv.get('APP_ID')).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.all(Radius.circular(10)),
            boxShadow: [
              BoxShadow(
                color: CustomColors(dotenv.get('APP_ID')).secondaryShadowColor,
                offset: const Offset(1, 3),
                blurRadius: 3,
              )
            ]),
        child:
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(
            text,
            style: TextStyle(
              color: CustomColors(dotenv.get('APP_ID')).primaryColor,
              fontSize: 16,
            ),
          ),
          Icon(
            Icons.add,
            color: CustomColors(dotenv.get('APP_ID')).primaryColor,
          )
        ]),
      ),
    );
  }
}
