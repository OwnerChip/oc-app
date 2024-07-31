//import packages
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mime/mime.dart';
import 'package:async/async.dart';
import 'package:ownerchip_whitelabel/config/constants.dart';
import 'package:ownerchip_whitelabel/domain/classDefinition.dart';
import 'package:ownerchip_whitelabel/domain/creation/digitalTwinAttachment.dart';
import 'package:ownerchip_whitelabel/services/backend/app/backendApp.dart';
import 'package:ownerchip_whitelabel/services/backend/attachments/backendAttachments.dart';
import 'package:ownerchip_whitelabel/services/backend/backend.services.dart';
import 'package:ownerchip_whitelabel/services/backend/creation/backendCreation.dart';
import 'package:ownerchip_whitelabel/services/backend/creation/payloads/uploadDigitalTwinCreationAttachmentPayload.dart';
import 'package:ownerchip_whitelabel/services/providers/creationData.dart';
import 'package:ownerchip_whitelabel/widgets/popups/CustomOverlay.dart';
import 'package:ownerchip_whitelabel/widgets/popups/returnSnackBarWidget.dart';
import 'package:ownerchip_whitelabel/widgets/ui/ChooseFileButton.dart';
import 'package:sentry/sentry.dart';
import 'package:web3dart/web3dart.dart';
import 'package:ownerchip_whitelabel/services/providers/walletconnectData.dart';
import 'package:ownerchip_whitelabel/services/providers/chipData.dart';
import 'package:ownerchip_whitelabel/services/providers/collectionsData.dart';
import 'package:ownerchip_whitelabel/services/providers/nftData.dart';

//import services
import 'package:ownerchip_whitelabel/services/attachments.services.dart';
import 'package:ownerchip_whitelabel/services/providers/attachmentsData.dart';
import 'package:ownerchip_whitelabel/services/providers/userData.dart';

//import widgets
import 'package:ownerchip_whitelabel/widgets/layout/ScreenBodyLayout.dart';
import 'package:ownerchip_whitelabel/widgets/ui/appBar/CustomAppBar.dart';
import 'package:ownerchip_whitelabel/widgets/ui/CustomRoundedButton.dart';
import 'package:ownerchip_whitelabel/widgets/ui/SpinningLoadingSvg.dart';
import 'package:ownerchip_whitelabel/widgets/ui/CustomCard.dart';
import 'package:ownerchip_whitelabel/widgets/ui/CustomOutlinedButton.dart';

//import misc
import 'package:ownerchip_whitelabel/utils/localization.helper.dart';
import 'package:ownerchip_whitelabel/screens/HomeScreen.dart';
import 'package:ownerchip_whitelabel/themes/colorSpecs.dart';
import 'package:file_picker/file_picker.dart';
import 'package:ownerchip_whitelabel/utils/utils.dart';
import 'package:ownerchip_whitelabel/utils/navigationArguments.dart';

import '../services/images.services.dart';
import '../services/web3.services.dart';

class AddAttachmentScreen extends ConsumerStatefulWidget {
  const AddAttachmentScreen({Key? key}) : super(key: key);

  static const routeName = '/addFile';

  @override
  _AddAttachmentScreenState createState() => _AddAttachmentScreenState();
}

enum Visibility { public, private }

class _AddAttachmentScreenState extends ConsumerState<AddAttachmentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleInputController = TextEditingController();
  final _urlInputController = TextEditingController();

  bool isLoading = false;
  bool isRotating = true;
  String loadingSvgPath =
      '${dotenv.get('IMAGE_ASSETS_BASE_URL')}/chip_dark_blue.svg';
  String loadingText = '';

  String titleTextInput = '';
  String urlTextInput = '';
  String buttonText = 'Choose File';
  bool isPrivate = false;
  String? fileName;
  PlatformFile? file;

  Visibility? _visibility =
      Visibility.public; //this is the radio button state for isPrivate/isPublic

  CancelableOperation? cancellableOperation;

  DigitalTwinAttachment? creationAttachment;
  String? metadataId;

  @override
  void dispose() {
    _titleInputController.dispose();
    _urlInputController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final navArgs = ModalRoute.of(context)!.settings.arguments != null
          ? ModalRoute.of(context)!.settings.arguments
              as AttachmentScreensArguments
          : null;

      creationAttachment = navArgs?.twinAttachment;
      metadataId = navArgs?.metadataId;

      //IF FILE TYPE IS URL
      if (navArgs != null && navArgs.type == AttachmentType.url) {
        setState(() {
          buttonText = context.loc.save;
        });

        //if edit mode, set title and url
        if (navArgs.isEditMode && navArgs.index != null) {
          final List<Attachment> attachments =
              ref.watch(localAttachmentsProvider);
          Attachment attachment = attachments[navArgs.index!];

          setState(() {
            _titleInputController.text = attachment.title;
            _urlInputController.text = attachment.url;
            titleTextInput = attachment.title;
            urlTextInput = attachment.url;
            isPrivate = attachment.isPrivate;
          });
          //set radio button state
          _visibility = attachment.isPrivate
              ? Visibility.private
              : Visibility.public; //set visibility
        }
      } else {
        //IF FILE TYPE IS NOT URL (video, image, text, etc.)
        //if edit mode, set title and file and button text
        if (navArgs != null && navArgs.isEditMode && navArgs.index != null) {
          Attachment attachment =
              ref.read(localAttachmentsProvider.notifier).state[navArgs.index!];

          setState(() {
            _titleInputController.text = attachment.title;
            titleTextInput = attachment.title;
            buttonText = context.loc.save;
            isPrivate = attachment.isPrivate;
            fileName = attachment.fileName;
          });
          //set radio button state
          _visibility = attachment.isPrivate
              ? Visibility.private
              : Visibility.public; //set visibility
        } else {
          //if not edit mode, set button text to "Choose File"
          setState(() {
            buttonText = context.loc.chooseFile;
          });
        }
      }
    });
  }

  Future<void> pickMedia() async {
    XFile? imageFile = await getMediaFromGallery();
    //change XFile to File
    if (imageFile != null) {
      Uint8List bytes = await imageFile.readAsBytes();
      int size = await File(imageFile.path).length();
      setState(() {
        file = PlatformFile(
          path: imageFile.path,
          name: imageFile.name,
          size: size,
          bytes: bytes,
        );
        fileName = imageFile.name;
        buttonText = context.loc.save;
      });
    }
  }

  //pick file
  Future<void> pickFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles();

    if (result != null) {
      setState(() {
        file = result.files.first;
        fileName = result.files.first.name;
        buttonText = context.loc.save;
      });
    } else {
      // User canceled the picker
    }
  }

  Future<void> editAttachment(AttachmentType type) async {
    final navArgs = ModalRoute.of(context)!.settings.arguments
        as AttachmentScreensArguments;

    ChipInfoModel chipInfo = ref.read(chipInfoProvider);

    List chainAndCollectionId = await returnChainAndCollectionId();
    int chainId = chainAndCollectionId[0];
    EthereumAddress collectionId = chainAndCollectionId[1];

    Attachment attachmentBeingEdited =
        ref.read(localAttachmentsProvider.notifier).state[navArgs.index!];
    UserSession? userSession = ref.read(userSessionProvider);

    try {
      setState(() {
        isLoading = true;
        loadingText = context.loc.uploadingAttachment;
      });

      if (creationAttachment != null) {
        await BackendCreation.updateAttachmentMetadata(
          metadata: creationAttachment!.metadataId,
          attachmentId: creationAttachment!.uid,
          payload: UploadDigitalTwinCreationAttachmentPayload(
            title: titleTextInput,
            isPrivate: isPrivate,
            link: attachmentBeingEdited.type == AttachmentType.url
                ? urlTextInput
                : null,
            fileSize: creationAttachment!.fileSize,
            fileHash: creationAttachment!.fileHash,
            contentType: creationAttachment!.contentType,
            fileName: creationAttachment!.fileName,
          ),
        );
      } else {
        await BackendAttachments.putAttachmentMetadataToBackend(
            userSession!,
            ref.read(userAddressProvider),
            chainId,
            collectionId,
            chipInfo.tokenId,
            attachmentBeingEdited.backendUuid,
            attachmentBeingEdited.fileName,
            titleTextInput,
            isPrivate,
            attachmentUrl: attachmentBeingEdited.type == AttachmentType.url
                ? urlTextInput
                : null);
      }

      await ref.refresh(fetchAttachmentsProvider.future);
      await ref.refresh(digitalTwinAttachmentsProvider.future);


      setState(() {
        isLoading = false;
        loadingText = '';
      });

      BackendApp.sendAnalyticsTrace(userSession!.sessionId,
          attachmentBeingEdited.backendUuid, "ATTACHMENT_EDITED",
          tags: {
            'connectedWallet': ref.read(userAddressProvider).hex,
            'chipWallet': convertTokenIdToEthereumAddress(chipInfo.tokenId)
          });

      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        returnSnackBarWidget(context.loc.successHeadingSnackbar,
            context.loc.fileEdited, 'success'),
      );
    } catch (e) {
      setState(() {
        isLoading = false;
        loadingText = '';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        returnSnackBarWidget(context.loc.errorHeadingSnackBar,
            context.loc.errorUpdatingData, 'error'),
      );
      print(e);
      Sentry.captureException(e);
    }
  }

  void uploadFile() async {
    try {
      setState(() {
        isLoading = true;
        loadingText = 'Uploading...';
      });

      //get sha256_hash of file
      String fileHash = await getSha256HashOfFile(File(file!.path!));
      int fileSize = file!.size;
      String contentType = lookupMimeType(file!.path!)!;

      UserSession? userSession = ref.read(userSessionProvider);
      EthereumAddress walletAddress = await ref.read(userAddressProvider);
      List chainAndCollectionId = await returnChainAndCollectionId();
      int chainId = chainAndCollectionId[0];
      EthereumAddress collectionId = chainAndCollectionId[1];

      late String fileUuid;
      late String awsUrl;

      if (metadataId == null) {
        List response =
            await BackendAttachments.postAttachmentMetadataToBackend(
                userSession!,
                ref.read(userAddressProvider),
                chainId,
                collectionId,
                ref.read(chipInfoProvider).tokenId,
                fileName!,
                _titleInputController.text,
                isPrivate,
                fileHash: fileHash,
                contentType: contentType,
                fileSize: fileSize);

        fileUuid = response[0];
        awsUrl = response[1];
      } else {
        final response = await BackendCreation.prepareAttachmentUpload(
          id: metadataId!,
          payload: UploadDigitalTwinCreationAttachmentPayload(
            title: titleTextInput,
            isPrivate: isPrivate,
            fileSize: fileSize,
            link: null,
            fileHash: fileHash,
            contentType: contentType,
            fileName: file!.name,
          ),
        );

        fileUuid = response!.uid;
        awsUrl = response.url!;
      }

      //upload file to aws presigned url
      var awsResponse = await BackendAttachments.uploadFileToAWS(
          File(file!.path!), awsUrl, contentType);

      if (metadataId != null) {
        await BackendCreation.setAttachmentUploaded(
          id: metadataId!,
          attachmentId: fileUuid,
        );
      }

      var _ = await ref.refresh(fetchAttachmentsProvider.future);
      await ref.refresh(digitalTwinAttachmentsProvider.future);

      setState(() {
        isLoading = false;
        loadingText = '';
      });
      if (file != null) {
        BackendApp.sendAnalyticsTrace(
            userSession!.sessionId, fileUuid, "ATTACHMENT_FILE_UPLOADED",
            tags: {
              'connectedWallet': ref.read(userAddressProvider).hex,
              'chipWallet': convertTokenIdToEthereumAddress(
                  ref.read(chipInfoProvider).tokenId),
            });

        Navigator.pop(context, file);

        ScaffoldMessenger.of(context).showSnackBar(
          returnSnackBarWidget(context.loc.successHeadingSnackbar,
              context.loc.fileAttached, 'success'),
        );
      }
    } catch (e) {
      setState(() {
        isLoading = false;
        loadingText = '';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        returnSnackBarWidget(context.loc.errorHeadingSnackBar,
            context.loc.errorUploadingFile, 'error'),
      );
      print(e);
      Sentry.captureException(e);
    }
  }

  void saveUrl() async {
    setState(() {
      isLoading = true;
      loadingText = context.loc.savingUrl;
    });

    List chainAndCollectionId = await returnChainAndCollectionId();
    int chainId = chainAndCollectionId[0];
    EthereumAddress collectionId = chainAndCollectionId[1];

    UserSession? userSession = ref.read(userSessionProvider);

    try {
      late String fileUuid;
      late String status;

      if (metadataId == null) {
        List result = await BackendAttachments.postAttachmentMetadataToBackend(
            userSession!,
            ref.read(userAddressProvider),
            chainId,
            collectionId,
            ref.read(chipInfoProvider).tokenId,
            _titleInputController.text,
            _titleInputController.text,
            isPrivate,
            attachmentLink: _urlInputController.text);

        fileUuid = result[0];
        status = result[1];
      } else {
        final response = await BackendCreation.prepareAttachmentUpload(
            id: metadataId!,
            payload: UploadDigitalTwinCreationAttachmentPayload(
              title: titleTextInput,
              isPrivate: isPrivate,
              fileSize: null,
              link: _urlInputController.text.isEmpty
                  ? "https://"
                  : _urlInputController.text,
              fileHash: null,
              contentType: null,
              fileName: null,
            ));

        fileUuid = response!.uid;
        status = 'OK';
      }

      await ref.refresh(fetchAttachmentsProvider.future);
      await ref.refresh(digitalTwinAttachmentsProvider.future);

      setState(() {
        isLoading = false;
        loadingText = '';
      });

      if (status == 'OK') {
        BackendApp.sendAnalyticsTrace(
            userSession!.sessionId, fileUuid, "ATTACHMENT_URL_UPLOADED",
            tags: {
              'connectedWallet': ref.read(userAddressProvider).hex,
              'chipWallet': convertTokenIdToEthereumAddress(
                  ref.read(chipInfoProvider).tokenId),
            });

        Navigator.pop(context);

        ScaffoldMessenger.of(context).showSnackBar(
          returnSnackBarWidget(context.loc.successHeadingSnackbar,
              context.loc.urlAttached, 'success'),
        );
      } else {
        throw Exception(context.loc.errorSavingUrl);
      }
    } catch (e) {
      setState(() {
        isLoading = false;
        loadingText = '';
      });
      //show error snackbar
      ScaffoldMessenger.of(context).showSnackBar(
        returnSnackBarWidget(context.loc.errorHeadingSnackBar,
            context.loc.errorSavingUrl, 'error'),
      );
    }
  }

  //remove attachment
  void removeAttachment() async {
    //get navigation arguments
    final navArgs = ModalRoute.of(context)!.settings.arguments
        as AttachmentScreensArguments;
    final List<Attachment> attachments = ref.watch(localAttachmentsProvider);
    Attachment attachment = attachments[navArgs.index!];

    List chainAndCollectionId = await returnChainAndCollectionId();
    int chainId = chainAndCollectionId[0];
    EthereumAddress collectionId = chainAndCollectionId[1];

    UserSession? userSession = ref.read(userSessionProvider);

    try {
      setState(() {
        isLoading = true;
        loadingText = context.loc.deletingAttachment;
      });

      if (creationAttachment == null) {
        var result = await BackendAttachments.deleteAttachmentFromBackend(
            userSession!,
            ref.read(userAddressProvider),
            chainId,
            collectionId,
            ref.read(chipInfoProvider).tokenId,
            attachment.backendUuid);
      } else {
        await BackendCreation.deleteAttachment(
          id: creationAttachment!.metadataId,
          attachmentId: creationAttachment!.uid,
        );
      }

      var _ = await ref.refresh(fetchAttachmentsProvider.future);
      await ref.refresh(digitalTwinAttachmentsProvider.future);

      setState(() {
        isLoading = false;
        loadingText = '';
      });
    } catch (e) {
      setState(() {
        isLoading = false;
        loadingText = '';
      });

      ScaffoldMessenger.of(context).showSnackBar(
        returnSnackBarWidget(context.loc.errorHeadingSnackBar,
            context.loc.errorDeletingAttachment, 'error'),
      );

      throw Exception(context.loc.errorDeletingAttachment);
    }

    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      returnSnackBarWidget(context.loc.successHeadingSnackbar,
          context.loc.attachmentDeleted, 'success'),
    );
    setState(() {
      file = null;
      buttonText = context.loc.chooseFile;
      file = null;
    });

    BackendApp.sendAnalyticsTrace(
        userSession!.sessionId, attachment.backendUuid, "ATTACHMENT_DELETED",
        tags: {
          'connectedWallet': ref.read(userAddressProvider).hex,
          'chipWallet': convertTokenIdToEthereumAddress(
              ref.read(chipInfoProvider).tokenId),
        });
  }

  Future<List> returnChainAndCollectionId() async {
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

  @override
  Widget build(BuildContext context) {
    List<Attachment> attachmentList = ref.watch(localAttachmentsProvider);
    final navArgs = ModalRoute.of(context)!.settings.arguments != null
        ? ModalRoute.of(context)!.settings.arguments
            as AttachmentScreensArguments
        : null;
    return CustomOverlay(
        show: isLoading,
        content: SpinningLoadingSvg(
          loadingText: loadingText,
          rotateIcon: isRotating,
          svgPath: loadingSvgPath,
        ),
        child: Scaffold(
          extendBodyBehindAppBar: true,
          appBar: CustomAppBar(
            showBackButton: true,
            text: context.loc.addDigitalContent,
          ),
          body: ScreenBodyLayout(
              mainAxisAlignment: MainAxisAlignment.center,
              padding: const EdgeInsets.only(top: 0, bottom: 15),
              children: [
                const SizedBox(height: 40),
                CustomCard(
                  children: [
                    Form(
                      key: _formKey,
                      child: Column(
                        children: <Widget>[
                          //TITLE FORM FIELD
                          TextFormField(
                              style: Theme.of(context).textTheme.bodyMedium,
                              controller: _titleInputController,
                              onChanged: (text) => setState(() {
                                    titleTextInput = text;
                                  }),
                              validator: (value) {
                                //if value is too long return error
                                if (value!.length > 42) {
                                  return context.loc.titleTooLong;
                                }
                                if (value!.isEmpty) {
                                  return context.loc.titleCannotBeEmpty;
                                }
                                if (attachmentList.length >= 50) {
                                  return context.loc.maxAttachmentsReached;
                                }
                              },
                              decoration: InputDecoration(
                                  enabledBorder: UnderlineInputBorder(
                                    borderSide: BorderSide(
                                        color: Theme.of(context).primaryColor),
                                  ),
                                  focusedBorder: UnderlineInputBorder(
                                    borderSide: BorderSide(
                                        color: Theme.of(context).primaryColor),
                                  ),
                                  contentPadding:
                                      const EdgeInsets.only(left: 12),
                                  hintText: context.loc.title,
                                  hintStyle:
                                      Theme.of(context).textTheme.bodyMedium)),
                          const SizedBox(height: 10),

                          //URL FORM FIELD
                          navArgs != null && navArgs.type == AttachmentType.url
                              ? TextFormField(
                                  style: Theme.of(context).textTheme.bodyMedium,
                                  controller: _urlInputController,
                                  onChanged: (text) => setState(() {
                                        urlTextInput = text;
                                      }),
                                  validator: (value) {
                                    //check if url starts with http and add it if not
                                    if (value != null &&
                                        !value.startsWith('http')) {
                                      value = 'https://$value';
                                    }

                                    //check if url is valid
                                    if (!Uri.parse(value!).isAbsolute) {
                                      return context.loc.enterValidUrl;
                                    }

                                    if (value!.isEmpty) {
                                      return context.loc.urlCannotBeEmpty;
                                    }
                                    if (attachmentList.length >= 50) {
                                      return context.loc.maxAttachmentsReached;
                                    }
                                  },
                                  decoration: InputDecoration(
                                      enabledBorder: UnderlineInputBorder(
                                        borderSide: BorderSide(
                                            color:
                                                Theme.of(context).primaryColor),
                                      ),
                                      focusedBorder: UnderlineInputBorder(
                                        borderSide: BorderSide(
                                            color:
                                                Theme.of(context).primaryColor),
                                      ),
                                      contentPadding:
                                          const EdgeInsets.only(left: 12),
                                      hintText: 'URL',
                                      hintStyle: Theme.of(context)
                                          .textTheme
                                          .bodyMedium))
                              : Container(),
                          Column(
                            children: <Widget>[
                              ListTile(
                                contentPadding: const EdgeInsets.all(0),
                                horizontalTitleGap: 7,
                                title: Text(context.loc.public,
                                    style: TextStyle(
                                      color: CustomColors(dotenv.get('APP_ID'))
                                          .primaryColor,
                                    )),
                                subtitle: Text(
                                    style:
                                        Theme.of(context).textTheme.bodySmall,
                                    context.loc.contentCanBeViewedPublic),
                                leading: Radio<Visibility>(
                                  activeColor:
                                      CustomColors(dotenv.get('APP_ID'))
                                          .primaryColor,
                                  value: Visibility.public,
                                  groupValue: _visibility,
                                  onChanged: (Visibility? value) {
                                    setState(() {
                                      _visibility = value;
                                      isPrivate = false;
                                    });
                                  },
                                ),
                              ),
                              ListTile(
                                contentPadding: const EdgeInsets.all(0),
                                horizontalTitleGap: 7,
                                title: Text(context.loc.private,
                                    style: TextStyle(
                                      color: CustomColors(dotenv.get('APP_ID'))
                                          .primaryColor,
                                    )),
                                subtitle: Text(
                                  context.loc.contentCanOnlyBeViewedPrivate,
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                                leading: Radio<Visibility>(
                                  activeColor:
                                      CustomColors(dotenv.get('APP_ID'))
                                          .primaryColor,
                                  value: Visibility.private,
                                  groupValue: _visibility,
                                  onChanged: (Visibility? value) {
                                    setState(() {
                                      _visibility = value;
                                      isPrivate = true;
                                    });
                                  },
                                ),
                              ),
                            ],
                          ),
                          Padding(
                            padding: EdgeInsets.only(top: 10, bottom: 10),
                            child: fileName != null
                                ? Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      //if file is chosen (not null) show "[first 5 chars]...[last 9 chars]" of filename
                                      Text(getFileNameSubstring(fileName!),
                                          style: TextStyle(
                                            color: CustomColors(
                                                    dotenv.get('APP_ID'))
                                                .primaryColor,
                                          )),
                                      //round checkmark icon
                                      const Icon(Icons.check_circle_rounded,
                                          color: Colors.green)
                                    ],
                                  )
                                : Container(),
                          ),

                          if (file == null &&
                              navArgs!.type != AttachmentType.url &&
                              !navArgs.isEditMode)
                            ChooseFileButton(
                              text: context.loc.chooseFile,
                              openFileExplorerFunction: pickFile,
                              openGalleryFunction: pickMedia,
                            )
                          else
                            CustomRoundedButton(
                                text: buttonText,
                                onPressed: (() => {
                                      FocusScope.of(context).unfocus(),
                                      //save edit attachment
                                      if (navArgs != null && navArgs.isEditMode)
                                        {
                                          if (_formKey.currentState!.validate())
                                            editAttachment(navArgs.type)
                                        }
                                      //save URL
                                      else if (navArgs != null &&
                                          navArgs.type == AttachmentType.url)
                                        {
                                          if (_formKey.currentState!.validate())
                                            saveUrl()
                                        }
                                      //upload file
                                      else
                                        {
                                          if (_formKey.currentState!.validate())
                                            uploadFile()
                                        }
                                    })),

                          const SizedBox(height: 10),
                          navArgs != null && navArgs.isEditMode
                              ? CustomOutlinedButton(
                                  buttonText: context.loc.remove,
                                  onPressed: () => removeAttachment(),
                                  color: Colors.red,
                                  width: double.infinity,
                                )
                              : Container(),
                        ],
                      ),
                    ),
                  ],
                ),
              ]),
        ));
  }
}
