//import packages
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:async/async.dart';
import 'package:ownerchip_whitelabel/domain/classDefinition.dart';
import 'package:sentry/sentry.dart';

//import services
import 'package:ownerchip_whitelabel/services/providers.service.dart';

//import widgets
import 'package:ownerchip_whitelabel/widgets/layout/ScreenBodyLayout.dart';
import 'package:ownerchip_whitelabel/widgets/ui/CustomAppBar.dart';
import 'package:ownerchip_whitelabel/widgets/ui/CustomRoundedButton.dart';
import 'package:ownerchip_whitelabel/widgets/layout/CustomOverlay.dart';
import 'package:ownerchip_whitelabel/widgets/ui/SpinningLoadingSvg.dart';
import 'package:ownerchip_whitelabel/widgets/ui/CustomCard.dart';
import 'package:ownerchip_whitelabel/widgets/ui/CustomOutlinedButton.dart';

//import misc
import 'package:ownerchip_whitelabel/utils/localization.helper.dart';
import 'package:ownerchip_whitelabel/screens/HomeScreen.dart';
import 'package:ownerchip_whitelabel/themes/colorSpecs.dart';
import 'package:file_picker/file_picker.dart';
import 'package:ownerchip_whitelabel/utils/utils.dart';
import 'package:ownerchip_whitelabel/utils/navigation.arguments.dart';

//import services
import 'package:ownerchip_whitelabel/services/providers.service.dart';

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
  PlatformFile? file;

  Visibility? _visibility = Visibility.public;

  CancelableOperation? cancellableOperation;

  @override
  void dispose() {
    _titleInputController.dispose();
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
          buttonText = 'Save';
        });

        //if edit mode, set title and url
        if (navArgs.isEditMode && navArgs.index != null) {
          Attachment attachment =
              ref.read(attachmentListProvider.notifier).state[navArgs.index!];

          setState(() {
            _titleInputController.text = attachment.title;
            _urlInputController.text = attachment.url!;
            titleTextInput = attachment.title;
            urlTextInput = attachment.url!;
            buttonText = 'Save';
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
              ref.read(attachmentListProvider.notifier).state[navArgs.index!];

          setState(() {
            _titleInputController.text = attachment.title;
            titleTextInput = attachment.title;
            file = attachment.file;
            buttonText = 'Save';
            isPrivate = attachment.isPrivate;
          });
          //set radio button state
          _visibility = attachment.isPrivate
              ? Visibility.private
              : Visibility.public; //set visibility
        }
      }
    });
  }

  //pick file
  Future<void> pickFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles();

    if (result != null) {
      setState(() {
        file = result.files.first;
        buttonText = 'Save';
      });
    } else {
      // User canceled the picker
    }
  }

  Future<void> editAttachment(AttachmentType type) async {
    final navArgs = ModalRoute.of(context)!.settings.arguments
        as AttachmentScreensArguments;
    //set attachment at corresponding index
    if (type == AttachmentType.url) {
      ref.read(attachmentListProvider.notifier).state[navArgs.index!] =
          Attachment(titleTextInput, urlTextInput, type,
              url: urlTextInput, isPrivate: isPrivate);
    } else {
      ref.read(attachmentListProvider.notifier).state[navArgs.index!] =
          Attachment(titleTextInput, file!.name, AttachmentType.other,
              isPrivate: isPrivate, file: file);
    }

    //copy state to trigger rebuild
    ref.read(attachmentListProvider.notifier).state =
        List.from(ref.read(attachmentListProvider.notifier).state);

    Navigator.pop(context);
  }

  void uploadFile() {
    //TODO: upload file here
    if (file != null) {
      Attachment attachment = Attachment(
          titleTextInput, file!.name, AttachmentType.other,
          isPrivate: isPrivate, file: file);
      ref.read(attachmentListProvider.notifier).state = [
        ...ref.read(attachmentListProvider.notifier).state,
        attachment
      ];
      Navigator.pop(context, file);
    }
  }

  void saveUrl() {
    //TODO: save URL to backend
    Attachment attachment = Attachment(
        titleTextInput, urlTextInput, AttachmentType.url,
        isPrivate: isPrivate, url: urlTextInput);
    ref.read(attachmentListProvider.notifier).state = [
      ...ref.read(attachmentListProvider.notifier).state,
      attachment
    ];
    Navigator.pop(context, file);
  }

  //remove file
  void removeFile() {
    //get navigation arguments
    final navArgs = ModalRoute.of(context)!.settings.arguments
        as AttachmentScreensArguments;
    ref.read(attachmentListProvider.notifier).state.removeAt(navArgs.index!);
    ref.read(attachmentListProvider.notifier).state = List.from(ref
        .read(attachmentListProvider.notifier)
        .state); //state has to be copied and set again to trigger rebuild
    Navigator.pop(context);
    setState(() {
      file = null;
      buttonText = 'Choose File';
      file = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    List<Attachment> attachmentList = ref.watch(attachmentListProvider);
    final navArgs = ModalRoute.of(context)!.settings.arguments != null
        ? ModalRoute.of(context)!.settings.arguments
            as AttachmentScreensArguments
        : null;
    return CustomOverlay(
        show: isLoading,
        content: SpinningLoadingSvg(
          onPressed: () {
            cancellableOperation?.cancel();
            setState(() {
              isLoading = false;
            });
            Navigator.pushNamedAndRemoveUntil(
                context, HomeScreen.routeName, (route) => false);
          },
          loadingText: loadingText,
          rotateIcon: isRotating,
          svgPath: loadingSvgPath,
          // enable secondary button
          secondaryButton: true,
          secondaryButtonText: context.loc.troubleshoot,
          secondaryButtonUrl: dotenv.get('SUPPORT_PAGE_URL'),
        ),
        child: Scaffold(
          extendBodyBehindAppBar: true,
          appBar: const CustomAppBar(
            showBackButton: true,
            text: 'Add Digital Content',
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
                              controller: _titleInputController,
                              onChanged: (text) => setState(() {
                                    titleTextInput = text;
                                  }),
                              validator: (value) {
                                //if value is too long return error
                                if (value!.length > 42) {
                                  return 'Title too long.';
                                }
                                if (value!.isEmpty) {
                                  return 'Title cannot be empty.';
                                }
                                if (attachmentList.length >= 10) {
                                  return 'You can only add max. 10 attachments.';
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
                                      return 'Please enter a valid URL starting with https://.';
                                    }

                                    if (value!.isEmpty) {
                                      return 'URL cannot be empty.';
                                    }
                                    if (attachmentList.length >= 10) {
                                      return 'You can only add max. 10 attachments.';
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
                                    style: TextStyle(fontSize: 12),
                                    'This content can be viewed by everyone who scans the item.'),
                                leading: Radio<Visibility>(
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
                                subtitle: const Text(
                                    //font size 12
                                    style: TextStyle(fontSize: 12),
                                    'This content can only be viewed by the verified owner. '),
                                leading: Radio<Visibility>(
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
                            child: file != null //&& file!.names[0] != null
                                ? Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      //if file is chosen (not null) show "[first 5 chars]...[last 9 chars]" of filename
                                      Text(getFileNameSubstring(file!.name),
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
                          CustomRoundedButton(
                              text: buttonText,
                              onPressed: (() => {
                                    if (navArgs != null && navArgs.isEditMode)
                                      {
                                        if (_formKey.currentState!.validate())
                                          editAttachment(navArgs.type)
                                      }
                                    else if (navArgs != null &&
                                        navArgs.type == AttachmentType.url)
                                      {saveUrl()}
                                    else if (file == null)
                                      {pickFile()}
                                    else
                                      {
                                        if (_formKey.currentState!.validate())
                                          uploadFile()
                                      }
                                  })),
                          const SizedBox(height: 10),
                          navArgs != null && navArgs.isEditMode
                              ? CustomOutlinedButton(
                                  buttonText: 'Remove',
                                  onPressed: () => removeFile(),
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
