import 'package:ownerchip_whitelabel/domain/attachmentType/attachmentType.dart';

class Attachment {
  final String title; //file title set by user
  final String fileName; //file name including file extension
  final AttachmentType type;
  final bool isPrivate;
  final String url;
  final String backendUuid;
  final bool? isFromCreator;

  Attachment(this.title, this.fileName, this.type, this.url, this.backendUuid,
      {this.isPrivate = false, this.isFromCreator});
}
