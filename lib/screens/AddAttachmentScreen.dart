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
import 'package:ownerchip_whitelabel/widgets/ui/ChooseFileButton.dart';
import 'package:sentry/sentry.dart';
import 'package:crypto/crypto.dart';
import 'package:web3dart/web3dart.dart';

//import services
import 'package:ownerchip_whitelabel/services/providers.services.dart';
import 'package:ownerchip_whitelabel/services/attachments.services.dart';

//import widgets
import 'package:ownerchip_whitelabel/widgets/layout/ScreenBodyLayout.dart';
import 'package:ownerchip_whitelabel/widgets/ui/CustomAppBar.dart';
import 'package:ownerchip_whitelabel/widgets/ui/CustomRoundedButton.dart';
import 'package:ownerchip_whitelabel/widgets/layout/CustomOverlay.dart';
import 'package:ownerchip_whitelabel/widgets/ui/SpinningLoadingSvg.dart';
import 'package:ownerchip_whitelabel/widgets/ui/CustomCard.dart';
import 'package:ownerchip_whitelabel/widgets/ui/CustomOutlinedButton.dart';
import 'package:ownerchip_whitelabel/widgets/ui/returnSnackBarWidget.dart';

//import misc
import 'package:ownerchip_whitelabel/utils/localization.helper.dart';
import 'package:ownerchip_whitelabel/screens/HomeScreen.dart';
import 'package:ownerchip_whitelabel/themes/colorSpecs.dart';
import 'package:file_picker/file_picker.dart';
import 'package:ownerchip_whitelabel/utils/utils.dart';
import 'package:ownerchip_whitelabel/utils/navigation.arguments.dart';
import 'package:ownerchip_whitelabel/services/providers.services.dart';

//import services
import 'package:ownerchip_whitelabel/services/providers.services.dart';

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

  Future<void> pickGalleryImage() async {
    XFile? imageFile = await getImageFromGallery();
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
    BackendSession? backendSession = ref.read(backendSessionProvider);

    try {
      setState(() {
        isLoading = true;
        loadingText = 'Uploading...';
      });
      await putAttachmentMetadataToBackend(
          backendSession!,
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

      setState(() {
        isLoading = false;
        loadingText = '';
      });

      //set attachment in provider at corresponding index
      if (type == AttachmentType.url) {
        //ATTACHMENT IS URL
        ref.read(localAttachmentsProvider.notifier).state[navArgs.index!] =
            Attachment(
          titleTextInput,
          urlTextInput,
          type,
          urlTextInput,
          attachmentBeingEdited.backendUuid,
          isPrivate: isPrivate,
          isFromCreator: attachmentBeingEdited.isFromCreator,
        );
      } else {
        //ATTACHMENT IS FILE
        ref.read(localAttachmentsProvider.notifier).state[navArgs.index!] =
            Attachment(
          titleTextInput,
          attachmentBeingEdited.fileName,
          AttachmentType.other,
          attachmentBeingEdited.url,
          attachmentBeingEdited.backendUuid,
          isPrivate: isPrivate,
          isFromCreator: attachmentBeingEdited.isFromCreator,
        );
      }

      //copy state to trigger rebuild
      ref.read(localAttachmentsProvider.notifier).state =
          List.from(ref.read(localAttachmentsProvider.notifier).state);
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

      BackendSession? backendSession = ref.read(backendSessionProvider);
      EthereumAddress walletAddress = await ref.read(userAddressProvider);
      List chainAndCollectionId = await returnChainAndCollectionId();
      int chainId = chainAndCollectionId[0];
      EthereumAddress collectionId = chainAndCollectionId[1];

      List response = await postAttachmentMetadataToBackend(
          backendSession!,
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

      String fileUuid = response[0];
      String awsUrl = response[1];

      //upload file to aws presigned url
      var awsResponse =
          await uploadFileToAWS(File(file!.path!), awsUrl, contentType);

      ref.refresh(fetchAttachmentsProvider);

      setState(() {
        isLoading = false;
        loadingText = '';
      });
      if (file != null) {
        bool hasMinterRole = await checkMinterRole(
            getRPCUrlFromChainId(chainId), collectionId, walletAddress);
        Attachment attachment = Attachment(
            titleTextInput, fileName!, AttachmentType.other, awsUrl, fileUuid,
            isPrivate: isPrivate, isFromCreator: hasMinterRole);
        ref.read(localAttachmentsProvider.notifier).state = [
          ...ref.read(localAttachmentsProvider.notifier).state,
          attachment
        ];
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

    BackendSession? backendSession = ref.read(backendSessionProvider);

    try {
      List result = await postAttachmentMetadataToBackend(
          backendSession!,
          ref.read(userAddressProvider),
          chainId,
          collectionId,
          ref.read(chipInfoProvider).tokenId,
          _titleInputController.text,
          _titleInputController.text,
          isPrivate,
          fileLink: _urlInputController.text);

      String fileUuid = result[0];
      String status = result[1];

      final walletAddress = ref.read(userAddressProvider);

      bool hasMinterRole = await checkMinterRole(
          getRPCUrlFromChainId(chainId), collectionId, walletAddress);

      setState(() {
        isLoading = false;
        loadingText = '';
      });

      if (status == 'OK') {
        Attachment attachment = Attachment(titleTextInput, urlTextInput,
            AttachmentType.url, urlTextInput, fileUuid,
            isPrivate: isPrivate, isFromCreator: hasMinterRole);
        ref.read(localAttachmentsProvider.notifier).state = [
          ...ref.read(localAttachmentsProvider.notifier).state,
          attachment
        ];
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

    BackendSession? backendSession = ref.read(backendSessionProvider);

    try {
      var result = await deleteAttachmentFromBackend(
          backendSession!,
          ref.read(userAddressProvider),
          chainId,
          collectionId,
          ref.read(chipInfoProvider).tokenId,
          attachment.backendUuid);
    } catch (e) {
      //show error snackbar
      ScaffoldMessenger.of(context).showSnackBar(
        returnSnackBarWidget(context.loc.errorHeadingSnackBar,
            context.loc.errorDeletingAttachment, 'error'),
      );
      throw Exception(context.loc.errorDeletingAttachment);
    }

    ref.read(localAttachmentsProvider.notifier).state.removeAt(navArgs.index!);
    ref.read(localAttachmentsProvider.notifier).state = List.from(ref
        .read(localAttachmentsProvider.notifier)
        .state); //state has to be copied and set again to trigger rebuild
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
  }

  Future<List> returnChainAndCollectionId() async {
    ChipInfoModel chipInfo = ref.read(chipInfoProvider);

    //get correct chain and collection
    TokenInfoObject tokenInfo =
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
                                if (attachmentList.length >= 10) {
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
                                  controller: _urlInputController,
                                  onChanged: (text) => setState(() {
                                        urlTextInput = text;
                                      }),
                                  validator: (value) {
                                    //check if url is valid
                                    if (!Uri.parse(value!).isAbsolute) {
                                      return context.loc.enterValidUrl;
                                    }

                                    if (value!.isEmpty) {
                                      return context.loc.urlCannotBeEmpty;
                                    }
                                    if (attachmentList.length >= 10) {
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
                                title: Text('Public',
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
                                title: Text('Private',
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
                              openGalleryFunction: pickGalleryImage,
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
