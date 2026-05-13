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
import 'package:ownerchip_whitelabel/domain/local_attachment.dart';
import 'package:ownerchip_whitelabel/services/backend/app/backendApp.dart';
import 'package:ownerchip_whitelabel/services/backend/attachments/backendAttachments.dart';
import 'package:ownerchip_whitelabel/services/backend/backend.services.dart';
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
          final List<LocalAttachment> attachments =
              ref.read(localAttachmentsProvider.notifier).state;
          LocalAttachment attachment = attachments[navArgs.index!];

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
          LocalAttachment attachment =
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

  //remove attachment
  void removeAttachment() async {
    final navArgs = ModalRoute.of(context)!.settings.arguments as AttachmentScreensArguments;
    if (navArgs != null && navArgs.isEditMode && navArgs.index != null) {
      final notifier = ref.read(localAttachmentsProvider.notifier);
      final attachments = List<LocalAttachment>.from(notifier.state);
      attachments.removeAt(navArgs.index!);
      notifier.state = attachments;
      Navigator.pop(context);
    }
  }

  // Helper to update local attachment in edit mode
  void updateLocalAttachment({String? title, String? url, bool? isPrivate, String? fileName, PlatformFile? file}) {
    final navArgs = ModalRoute.of(context)!.settings.arguments as AttachmentScreensArguments?;
    if (navArgs != null && navArgs.isEditMode && navArgs.index != null) {
      final notifier = ref.read(localAttachmentsProvider.notifier);
      final attachments = List<LocalAttachment>.from(notifier.state);
      final idx = navArgs.index!;
      final old = attachments[idx];
      attachments[idx] = old.copyWith(
        title: title,
        fileName: fileName,
        url: url,
        isPrivate: isPrivate,
        file: file,
        isUpdated: true,
      );
      notifier.state = attachments;
    }
  }

  @override
  Widget build(BuildContext context) {
    List<LocalAttachment> attachmentList = ref.watch(localAttachmentsProvider);
    final navArgs = ModalRoute.of(context)!.settings.arguments != null
        ? ModalRoute.of(context)!.settings.arguments as AttachmentScreensArguments
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
                              onChanged: (text) {
                                setState(() {
                                  titleTextInput = text;
                                });
                                updateLocalAttachment(title: text);
                              },
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
                                  onChanged: (text) {
                                    setState(() {
                                      urlTextInput = text;
                                    });
                                    updateLocalAttachment(url: text);
                                  },
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
                                    updateLocalAttachment(isPrivate: false);
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
                                    updateLocalAttachment(isPrivate: true);
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
                                onPressed: (() {
                                  FocusScope.of(context).unfocus();
                                  if (_formKey.currentState!.validate()) {
                                    if (navArgs != null && navArgs.isEditMode) {
                                      Navigator.pop(context);
                                    } else {
                                      // Add new attachment to local state
                                      final notifier = ref.read(localAttachmentsProvider.notifier);
                                      final attachments = List<LocalAttachment>.from(notifier.state);
                                      final uuid = UniqueKey().toString();
                                      attachments.add(LocalAttachment(
                                        title: _titleInputController.text,
                                        fileName: fileName ?? '',
                                        type: navArgs?.type ?? AttachmentType.other,
                                        url: navArgs?.type == AttachmentType.url ? _urlInputController.text : '',
                                        backendUuid: uuid,
                                        isFromCreator: true,
                                        isPrivate: isPrivate,
                                        file: file,
                                        isNew: true,
                                      ));
                                      notifier.state = attachments;
                                      Navigator.pop(context);
                                    }
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

