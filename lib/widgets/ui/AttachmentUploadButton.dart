import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:ownerchip_whitelabel/domain/local_attachment.dart';
import 'package:ownerchip_whitelabel/screens/AddAttachmentScreen.dart';
import 'package:ownerchip_whitelabel/services/images.services.dart';
import 'package:ownerchip_whitelabel/services/providers/attachmentsData.dart';
import 'package:ownerchip_whitelabel/themes/colorSpecs.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:ownerchip_whitelabel/themes/fontSpecs.dart';
import 'package:ownerchip_whitelabel/utils/navigationArguments.dart';
import '../../domain/classDefinition.dart';

import '../../utils/localization.helper.dart';

enum AttachmentUploadButtonOption {
  file,
  gallery,
  url,
}

class AttachmentUploadButton extends ConsumerStatefulWidget {
  const AttachmentUploadButton({
    super.key,
    required this.text,
    required this.icon,
    this.showOptions = true,
  });

  final String text;
  final IconData icon;
  final bool showOptions;

  @override
  ConsumerState<AttachmentUploadButton> createState() =>
      _AttachmentUploadButtonState();
}

class _AttachmentUploadButtonState
    extends ConsumerState<AttachmentUploadButton> {
  @override
  Widget build(BuildContext context) {
    final List<LocalAttachment> attachments =
        ref.watch(localAttachmentsProvider);

    return PopupMenuButton<AttachmentUploadButtonOption>(
      constraints: const BoxConstraints(minWidth: double.infinity),
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
          side: BorderSide(
              color: CustomColors(dotenv.get('APP_ID')).accentColor)),
      padding: EdgeInsets.all(0),
      position: PopupMenuPosition.under,
      initialValue: null,
      onSelected: (AttachmentUploadButtonOption value) async {
        switch (value) {
          case AttachmentUploadButtonOption.file:
            final res =
                await FilePicker.platform.pickFiles(allowMultiple: true);
            final files = res?.files;
            if (files != null && files.isNotEmpty) {
              final List<LocalAttachment> newAttachments = files
                  .map((file) => LocalAttachment(
                        title: file.name.split('.').first,
                        fileName: file.name,
                        type: AttachmentType.other,
                        url: '',
                        backendUuid: UniqueKey().toString(),
                        isFromCreator: true,
                        isPrivate: false,
                        file: file,
                      ))
                  .toList();
              ref.read(localAttachmentsProvider.notifier).state = [
                ...attachments,
                ...newAttachments
              ];
            }
            break;
          case AttachmentUploadButtonOption.gallery:
            final images = await getMultipleImagesFromGallery();
            if (images != null && images.isNotEmpty) {
              final List<LocalAttachment> newAttachments = await Future.wait(
                  images.map((image) async => LocalAttachment(
                      // if ios "Attachment 1,2.." else use file name with extension
                      title: Platform.isIOS
                          ? 'Attachment ${attachments.length + 1 + images!.indexOf(image)}'
                          : image.name.split('.').first,
                      fileName: image.name,
                      type: AttachmentType.image,
                      url: '',
                      backendUuid: UniqueKey().toString(),
                      isFromCreator: true,
                      isPrivate: false,
                      file: PlatformFile(
                        path: image.path,
                        name: image.name,
                        size: await File(image.path!).length(),
                        bytes: await image.readAsBytes(),
                      ))));
              ref.read(localAttachmentsProvider.notifier).state = [
                ...attachments,
                ...newAttachments
              ];
            }
            break;
          case AttachmentUploadButtonOption.url:
            Navigator.pushNamed(context, AddAttachmentScreen.routeName,
                arguments:
                    AttachmentScreensArguments(false, AttachmentType.url));
            break;
        }
      },
      itemBuilder: (BuildContext context) =>
          <PopupMenuEntry<AttachmentUploadButtonOption>>[
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
          value: AttachmentUploadButtonOption.gallery,
          child: Container(
              alignment: Alignment.center,
              width: double.infinity,
              child: Text(context.loc.viewGallery,
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
            widget.text,
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

