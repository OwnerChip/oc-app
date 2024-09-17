import 'package:flutter/material.dart';
import 'package:ownerchip_whitelabel/screens/AddAttachmentScreen.dart';
import 'package:ownerchip_whitelabel/themes/colorSpecs.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:ownerchip_whitelabel/themes/fontSpecs.dart';
import 'package:ownerchip_whitelabel/utils/navigationArguments.dart';
import '../../domain/classDefinition.dart';

import '../../utils/localization.helper.dart';

enum AttachmentUploadButtonOption {
  file,
  url,
}

class AttachmentUploadButton extends StatelessWidget {
  const AttachmentUploadButton(
      {super.key,
      required this.text,
      required this.icon,
      this.showOptions = true});

  final String text;
  final IconData icon;
  final bool showOptions;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<AttachmentUploadButtonOption>(
      constraints: const BoxConstraints(minWidth: double.infinity),
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
          side: BorderSide(
              color: CustomColors(dotenv.get('APP_ID')).accentColor)),
      padding: EdgeInsets.all(0),
      position: PopupMenuPosition.under,
      initialValue: null,
      onSelected: (AttachmentUploadButtonOption value) {

        switch(value) {

          case AttachmentUploadButtonOption.file:
            Navigator.pushNamed(context, AddAttachmentScreen.routeName,
                arguments:
                AttachmentScreensArguments(false, AttachmentType.text));
            break;
          case AttachmentUploadButtonOption.url:
            Navigator.pushNamed(context, AddAttachmentScreen.routeName,
                arguments: AttachmentScreensArguments(false, AttachmentType.url));
            break;
        }

      },
      itemBuilder: (BuildContext context) => <PopupMenuEntry<AttachmentUploadButtonOption>>[
        PopupMenuItem<AttachmentUploadButtonOption>(
          value: AttachmentUploadButtonOption.file,
          child: Container(
              alignment: Alignment.center,
              width: double.infinity,
              child: Text(context.loc.addFile,
                  style: TextStyle(
                      color: CustomColors(dotenv.get('APP_ID')).primaryColor))),
        ),
        const PopupMenuDivider(),
        PopupMenuItem<AttachmentUploadButtonOption>(
          value: AttachmentUploadButtonOption.url,
          child: Container(
              alignment: Alignment.center,
              width: double.infinity,
              child: Text(
                context.loc.addUrl,
                style: TextStyle(
                    color: CustomColors(dotenv.get('APP_ID')).primaryColor),
              )),
        ),
      ],
      child: Container(
        padding:
            const EdgeInsets.only(left: 10, right: 10, top: 15, bottom: 15),
        decoration: BoxDecoration(
            color: CustomColors(dotenv.get('APP_ID')).secondaryColor,
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
