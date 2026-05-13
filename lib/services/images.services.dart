import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:ownerchip_whitelabel/config/constants.dart';
import 'package:ownerchip_whitelabel/domain/classDefinition.dart';
import 'package:ownerchip_whitelabel/services/backend/app/backendApp.dart';
import 'package:ownerchip_whitelabel/services/backend/attachments/backendAttachments.dart';
import 'package:ownerchip_whitelabel/services/providers/attachmentsData.dart';
import 'package:ownerchip_whitelabel/services/providers/chipData.dart';
import 'package:ownerchip_whitelabel/services/providers/collectionsData.dart';
import 'package:ownerchip_whitelabel/services/providers/nftData.dart';
import 'package:ownerchip_whitelabel/services/providers/userData.dart';
import 'package:ownerchip_whitelabel/services/providers/walletconnectData.dart';
import 'package:ownerchip_whitelabel/utils/localization.helper.dart';
import 'package:ownerchip_whitelabel/utils/utils.dart';
import 'package:mime/mime.dart';
import 'package:ownerchip_whitelabel/widgets/popups/returnSnackBarWidget.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:web3dart/web3dart.dart';

Future<XFile?> getImageFromCamera() async {
  final ImagePicker picker = ImagePicker();
  final XFile? photo = await picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 70,
      maxHeight: 900,
      maxWidth: 900);
  return photo;
}

Future<XFile?> getImageFromGallery() async {
  final ImagePicker picker = ImagePicker();
  final XFile? image = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
      maxHeight: 900,
      maxWidth: 900);
  return image;
}

Future<XFile?> getMediaFromGallery() async {
  final ImagePicker picker = ImagePicker();
  final XFile? media = await picker.pickMedia();
  return media;
}

Future<List<XFile>?> getMultipleImagesFromGallery() async {
  final ImagePicker picker = ImagePicker();
  final List<XFile>? images = await picker.pickMultiImage();
  return images;
}

Future<void> saveUrl(BuildContext context, WidgetRef ref,
    Function(bool) setLoading, String title, bool isPrivate, String url) async {
  setLoading(true);

  List chainAndCollectionId = await returnChainAndCollectionId(ref);
  int chainId = chainAndCollectionId[0];
  EthereumAddress collectionId = chainAndCollectionId[1];

  UserSession? userSession = ref.read(userSessionProvider);

  try {
    List result = await BackendAttachments.postAttachmentMetadataToBackend(
        userSession!,
        ref.read(userAddressProvider),
        chainId,
        collectionId,
        ref.read(chipInfoProvider).tokenId,
        title,
        title,
        isPrivate,
        attachmentLink: url);

    String fileUuid = result[0];
    String status = result[1];

    await ref.refresh(fetchAttachmentsProvider.future);

    setLoading(false);

    if (status == 'OK') {
      BackendApp.sendAnalyticsTrace(
          userSession.sessionId, fileUuid, "ATTACHMENT_URL_UPLOADED",
          tags: {
            'connectedWallet': ref.read(userAddressProvider).hex,
            'chipWallet': convertTokenIdToEthereumAddress(
                ref.read(chipInfoProvider).tokenId),
          });
    } else {
      throw Exception(context.loc.errorSavingUrl);
    }
  } catch (e) {
    setLoading(false);
  }
}

Future<void> uploadFile(
    BuildContext context,
    WidgetRef ref,
    Function(bool) setLoading,
    PlatformFile file,
    String fileName,
    bool isPrivate,
    String title) async {
  try {
    setLoading(true);

    //get sha256_hash of file
    String fileHash = await getSha256HashOfFile(File(file.path!));
    int fileSize = file.size;
    String contentType = lookupMimeType(file.path!)!;

    UserSession? userSession = ref.read(userSessionProvider);
    EthereumAddress walletAddress = await ref.read(userAddressProvider);
    List chainAndCollectionId = await returnChainAndCollectionId(ref);
    int chainId = chainAndCollectionId[0];
    EthereumAddress collectionId = chainAndCollectionId[1];

    List response = await BackendAttachments.postAttachmentMetadataToBackend(
        userSession!,
        ref.read(userAddressProvider),
        chainId,
        collectionId,
        ref.read(chipInfoProvider).tokenId,
        fileName,
        title,
        isPrivate,
        fileHash: fileHash,
        contentType: contentType,
        fileSize: fileSize);

    String fileUuid = response[0];
    String awsUrl = response[1];

    //upload file to aws presigned url
    var awsResponse = await BackendAttachments.uploadFileToAWS(
        File(file.path!), awsUrl, contentType);

    var _ = await ref.refresh(fetchAttachmentsProvider.future);

    setLoading(false);
    BackendApp.sendAnalyticsTrace(
        userSession.sessionId, fileUuid, "ATTACHMENT_FILE_UPLOADED",
        tags: {
          'connectedWallet': ref.read(userAddressProvider).hex,
          'chipWallet': convertTokenIdToEthereumAddress(
              ref.read(chipInfoProvider).tokenId),
        });

  } catch (e) {
    setLoading(false);
    Sentry.captureException(e);
  }
}

Future<List> returnChainAndCollectionId(
  WidgetRef ref,
) async {
  ChipInfoModel chipInfo = ref.read(chipInfoProvider);

  //get correct chain and collection
  TokenChainAndCollection tokenInfo =
      await ref.read(findTokenProvider(chipInfo.tokenId).future);
  int chainId = tokenInfo.chainId;
  EthereumAddress collectionId = tokenInfo.collectionId;
  //if token does *not* exits AND chain AND collectionId has been selected by user
  // --> set chain and collectionId from dropdown state
  if (tokenInfo.collectionId == zeroAddress &&
      ref.read(selectedChainIdProvider.notifier).state != null &&
      ref.read(selectedCollectionIdProvider.notifier).state != null) {
    chainId = ref.read(selectedChainIdProvider.notifier).state!;
    collectionId = ref.read(selectedCollectionIdProvider.notifier).state!.id;
  }
  return [chainId, collectionId];
}
