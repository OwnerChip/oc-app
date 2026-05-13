import 'package:file_picker/file_picker.dart';
import 'package:ownerchip_whitelabel/domain/classDefinition.dart';

class LocalAttachment {
  String title;
  String fileName;
  AttachmentType type;
  String url;
  String backendUuid;
  bool? isFromCreator;
  bool isPrivate;
  PlatformFile? file; // Local file, if any
  bool isNew;
  bool isUpdated;
  bool isDeleted;

  LocalAttachment({
    required this.title,
    required this.fileName,
    required this.type,
    required this.url,
    required this.backendUuid,
    this.isFromCreator,
    required this.isPrivate,
    this.file,
    this.isNew = false,
    this.isUpdated = false,
    this.isDeleted = false,
  });

  factory LocalAttachment.fromAttachment(Attachment attachment) {
    return LocalAttachment(
      title: attachment.title,
      fileName: attachment.fileName,
      type: attachment.type,
      url: attachment.url,
      backendUuid: attachment.backendUuid,
      isFromCreator: attachment.isFromCreator,
      isPrivate: attachment.isPrivate,
    );
  }

  Attachment toAttachment() {
    return Attachment(
      title: title,
      fileName: fileName,
      type: type,
      url: url,
      backendUuid: backendUuid,
      isFromCreator: isFromCreator,
      isPrivate: isPrivate,
    );
  }

  LocalAttachment copyWith({
    String? title,
    String? fileName,
    AttachmentType? type,
    String? url,
    String? backendUuid,
    bool? isFromCreator,
    bool? isPrivate,
    PlatformFile? file,
    bool? isNew,
    bool? isUpdated,
    bool? isDeleted,
  }) {
    return LocalAttachment(
      title: title ?? this.title,
      fileName: fileName ?? this.fileName,
      type: type ?? this.type,
      url: url ?? this.url,
      backendUuid: backendUuid ?? this.backendUuid,
      isFromCreator: isFromCreator ?? this.isFromCreator,
      isPrivate: isPrivate ?? this.isPrivate,
      file: file ?? this.file,
      isNew: isNew ?? this.isNew,
      isUpdated: isUpdated ?? this.isUpdated,
      isDeleted: isDeleted ?? this.isDeleted,
    );
  }
}

