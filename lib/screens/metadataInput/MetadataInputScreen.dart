//package imports
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';

//misc imports
import 'package:ownerchip_whitelabel/domain/classDefinition.dart';

//screen imports
import 'package:ownerchip_whitelabel/screens/AddAttachmentScreen.dart';
import 'package:ownerchip_whitelabel/screens/metadataInput/MetadataInputController.dart';
import 'package:ownerchip_whitelabel/services/providers/attachmentsData.dart';
import 'package:ownerchip_whitelabel/services/providers/chipData.dart';
import 'package:ownerchip_whitelabel/services/providers/walletconnectData.dart';

//service imports
import 'package:ownerchip_whitelabel/services/attachments.services.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';

import '../../domain/local_attachment.dart';

//theme imports
import 'package:ownerchip_whitelabel/themes/colorSpecs.dart';
import 'package:ownerchip_whitelabel/utils/globals.dart';
import 'package:ownerchip_whitelabel/utils/localization.helper.dart';
import 'package:ownerchip_whitelabel/utils/navigationArguments.dart';
import 'package:ownerchip_whitelabel/widgets/layout/ScreenBodyLayout.dart';
import 'package:ownerchip_whitelabel/widgets/popups/CustomOverlay.dart';
import 'package:ownerchip_whitelabel/widgets/ui/AttachmentBox.dart';
import 'package:ownerchip_whitelabel/widgets/ui/AttachmentUploadButton.dart';

//widget imports
import 'package:ownerchip_whitelabel/widgets/ui/CustomCard.dart';
import 'package:ownerchip_whitelabel/widgets/ui/CustomRoundedButton.dart';
import 'package:ownerchip_whitelabel/widgets/ui/SetImageWidget.dart';
import 'package:ownerchip_whitelabel/widgets/ui/SpinningLoadingSvg.dart';
import 'package:ownerchip_whitelabel/widgets/ui/StyledTextInputBox.dart';
import 'package:ownerchip_whitelabel/widgets/ui/TraitsForm.dart';
import 'package:ownerchip_whitelabel/widgets/ui/appBar/CustomAppBar.dart';
import 'package:web3dart/web3dart.dart';

import '../../services/images.services.dart';

class MetadataScreen extends ConsumerStatefulWidget {
  const MetadataScreen({super.key});

  static const routeName = '/metadata-input';

  @override
  ConsumerState<MetadataScreen> createState() => _MetadataScreenState();
}

class _MetadataScreenState extends ConsumerState<MetadataScreen>
    with MetadataInputController {
  @override
  void initState() {
    super.initState();
    init();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(localAttachmentsProvider.notifier).state = [];
    });
  }

  @override
  void dispose() {
    close();
    super.dispose();
  }

  Future<void> uploadAllLocalAttachments(
      BuildContext context, WidgetRef ref) async {
    final localAttachments = ref.read(localAttachmentsProvider);
    if (localAttachments.isEmpty) return;

    for (final att in localAttachments) {
      if (att.type == AttachmentType.url) {
        await saveUrl(context, ref, (_) {}, att.title, att.isPrivate, att.url);
      } else if (att.file != null) {
        await uploadFile(
          context,
          ref,
          (_) {},
          att.file!,
          att.fileName,
          att.isPrivate,
          att.title,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final navArgs = ModalRoute.of(context)!.settings.arguments
        as MetadataInputScreenArguments;
    final wc = ref.watch(w3mServiceProvider);
    int chainId = navArgs.chainId;
    EthereumAddress collectionId = navArgs.collectionId;
    EthereumAddress? voucherCollectionId = navArgs.voucherAddress;
    final SignatureData signatureData = ref.watch(chipSignatureDataProvider);
    final localAttachments = ref.watch(localAttachmentsProvider);

    return CustomOverlay(
      show: isLoading,
      content: isLoading
          ? SpinningLoadingSvg(
              onPressed: loadingText == context.loc.mintingToken
                  ? () {
                      cancellableOperation?.cancel();
                      setState(() {
                        isLoading = false;
                      });
                      Navigator.of(context).popUntil((route) => route.isFirst);
                    }
                  : null,
              loadingText: loadingText,
              svgPath:
                  '${dotenv.get('IMAGE_ASSETS_BASE_URL')}/chip_dark_blue.svg',
            )
          : CustomCard(
              mainAxisSize: MainAxisSize.min,
              maxHeight: MediaQuery.of(context).size.height * 0.8,
              maxWidth: MediaQuery.of(context).size.width * 0.9,
              withScrollView: true,
              children: [
                  Text(
                    context.loc.addTraits,
                    style: Theme.of(context).textTheme.displayMedium,
                  ),
                  const SizedBox(height: 10),
                  Material(
                      child: TraitsForm(
                    submitFunction: setTraits,
                    toggleTraitsForm: toggleTraitsForm,
                    traitsStateArray: traitsStateArray,
                  ))
                ]),
      child: Scaffold(
          key: ScaffoldKey.getScaffoldKey('MetadataInputScreen'),
          extendBodyBehindAppBar: true,
          appBar: CustomAppBar(
            text: context.loc.initializeChip,
          ),
          body: GestureDetector(
              onTap: () => FocusScope.of(context).unfocus(),
              child: ScreenBodyLayout(children: [
                Row(
                  children: [
                    const SizedBox(width: 22),
                    RichText(
                      text: TextSpan(
                          text: '${context.loc.step} 2/',
                          style: Theme.of(context)
                              .textTheme
                              .titleLarge!
                              .copyWith(fontSize: 18),
                          children: [
                            TextSpan(
                                text: '2',
                                style: Theme.of(context)
                                    .textTheme
                                    .headlineSmall!
                                    .copyWith(fontSize: 18))
                          ]),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                CustomCard(
                    color: CustomColors(dotenv.get('APP_ID')).cardColor,
                    children: [
                      SetImageWidget(
                        imageFile: image,
                        setCameraImage: setCameraImage,
                        setGalleryImage: setGalleryImage,
                        resetImage: resetImage,
                      ),
                      const SizedBox(height: 20),
                      Form(
                          key: formKey,
                          child: Column(
                            children: [
                              Row(children: [
                                Expanded(
                                  flex: 5,
                                  child: TextFormField(
                                    style:
                                        Theme.of(context).textTheme.bodyMedium,
                                    controller: titleController,
                                    decoration: InputDecoration(
                                        enabledBorder: UnderlineInputBorder(
                                          borderSide: BorderSide(
                                              color: Theme.of(context)
                                                  .primaryColor),
                                        ),
                                        focusedBorder: UnderlineInputBorder(
                                          borderSide: BorderSide(
                                              color: Theme.of(context)
                                                  .primaryColor),
                                        ),
                                        hintText: context.loc.title,
                                        hintStyle: Theme.of(context)
                                            .textTheme
                                            .bodyMedium),
                                    onChanged: (text) {
                                      metadata['name'] = text;
                                    },
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return context.loc.pleaseEnterText;
                                      }
                                      return null;
                                    },
                                  ),
                                ),
                              ]),
                              const SizedBox(height: 15),
                              TraitsForm(
                                submitFunction: setTraits,
                                toggleTraitsForm: toggleTraitsForm,
                                traitsStateArray: traitsStateArray,
                              ),
                              StyledTextInputBox(
                                controller: descriptionController,
                                setText: (input) =>
                                    metadata['description'] = input,
                                keyboardType: TextInputType.multiline,
                                maxlines: 3,
                                fillColor:
                                    Theme.of(context).scaffoldBackgroundColor,
                                hintText: context.loc.description,
                              ),
                            ],
                          )),
                      const SizedBox(height: 20),
                      dotenv.get('APP_ID') == 'ownerchip_infineon'
                          ? Container()
                          : Column(children: [
                              AttachmentUploadButton(
                                text: context.loc.uploadDigitalContent,
                                icon: Icons.add,
                              ),
                              const SizedBox(height: 20),
                            ]),

                      //map over attachmentList to display all attachments as FileBox
                      for (var i = 0; i < localAttachments.length; i++)
                        Column(
                          children: [
                            AttachmentBox(
                              text: localAttachments[i].title,
                              icon:
                                  localAttachments[i].type == AttachmentType.url
                                      ? Icons.link
                                      : Icons.attach_file,
                              isPrivate: localAttachments[i].isPrivate,
                              onTap: () {
                                //navigate to AddFileScreen with navigation args
                                Navigator.pushNamed(
                                    context, AddAttachmentScreen.routeName,
                                    arguments: AttachmentScreensArguments(
                                        true, localAttachments[i].type,
                                        index: i));
                              },
                            ),
                            const SizedBox(height: 20),
                          ],
                        ),

                      Padding(
                          padding: const EdgeInsets.symmetric(vertical: 16.0),
                          child: CustomRoundedButton(
                            text: context.loc.mintNft,
                            onPressed: () async {
                              FocusManager.instance.primaryFocus?.unfocus();

                              if (!formKey.currentState!.validate()) {
                                return;
                              }

                              isLoading = true;
                              if (mounted) {
                                setState(() {});
                              }

                              await uploadAllLocalAttachments(context, ref);

                              setTraits(traitsStateArray);
                              fromCancelable(createToken(
                                  wc,
                                  signatureData,
                                  metadata,
                                  chainId,
                                  collectionId,
                                  voucherCollectionId,
                                  image: image));
                            },
                          )),
                      // const SizedBox(height: 60),
                      Row(
                        children: [
                          const SizedBox(width: 20),
                          SvgPicture.asset(
                              "${dotenv.get('IMAGE_ASSETS_BASE_URL')}/triangle_small.svg",
                              width: 25,
                              height: 25),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(context.loc.warningPublicData,
                                style: Theme.of(context).textTheme.bodySmall!),
                          ),
                        ],
                      )
                    ])
              ]))),
    );
  }
}
