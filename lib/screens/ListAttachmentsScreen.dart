//import packages
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ownerchip_whitelabel/domain/creation/digitalTwinAttachment.dart';
import 'package:ownerchip_whitelabel/domain/creation/digitalTwinMetadata.dart';

//import services
import 'package:ownerchip_whitelabel/services/providers/attachmentsData.dart';
import 'package:ownerchip_whitelabel/services/providers/creationData.dart';
import 'package:ownerchip_whitelabel/services/providers/userData.dart';

//import widgets
import 'package:ownerchip_whitelabel/widgets/layout/ScreenBodyLayout.dart';
import 'package:ownerchip_whitelabel/widgets/ui/appBar/CustomAppBar.dart';

//import misc
import 'package:ownerchip_whitelabel/utils/localization.helper.dart';
import 'package:ownerchip_whitelabel/domain/classDefinition.dart';

import 'package:ownerchip_whitelabel/utils/navigationArguments.dart';
import '../widgets/ui/AttachmentBox.dart';
import '../widgets/ui/AttachmentUploadButton.dart';
import 'AddAttachmentScreen.dart';
import 'package:collection/collection.dart';

class ListAttachmentsScreen extends ConsumerStatefulWidget {
  const ListAttachmentsScreen({Key? key}) : super(key: key);

  static const routeName = '/listAttachments';

  @override
  _ListAttachmentsScreenState createState() => _ListAttachmentsScreenState();
}

class _ListAttachmentsScreenState extends ConsumerState<ListAttachmentsScreen> {
  @override
  Widget build(BuildContext context) {
    final creation = ref.watch(creationData);
    final creationAttachments = ref.watch(digitalTwinAttachmentsProvider);

    final List<Attachment> attachments = ref.watch(localAttachmentsProvider);
    final List<Attachment> ownerAttachments =
        ref.watch(ownerAttachmentsProvider);
    final List<Attachment> creatorAttachments =
        ref.watch(creatorAttachmentsProvider);
    final AsyncValue<bool> hasMinterRole = ref.watch(hasMinterRoleProvider);
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: CustomAppBar(
        text: context.loc.editAttachment,
        showBackButton: true,
      ),
      body: creation.when(data: (creationData) {
        return creationAttachments.when(data: (creationAttachments) {
          return _buildBody(
            context,
            hasMinterRole,
            creatorAttachments,
            attachments,
            ownerAttachments,
            digitalTwinAttachments: creationAttachments,
            metadata: creationData,
          );
        }, loading: () {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }, error: (_, __) {
          if (creationData != null) {
            return const SizedBox();
          } else {
            return _buildBody(
              context,
              hasMinterRole,
              creatorAttachments,
              attachments,
              ownerAttachments,
              metadata: creationData,
            );
          }
        });
      }, error: (_, __) {
        return const SizedBox();
      }, loading: () {
        return const Center(
          child: CircularProgressIndicator(),
        );
      }),
    );
  }

  ScreenBodyLayout _buildBody(
    BuildContext context,
    AsyncValue<bool> hasMinterRole,
    List<Attachment> creatorAttachments,
    List<Attachment> attachments,
    List<Attachment> ownerAttachments, {
    DigitalTwinMetadata? metadata,
    List<DigitalTwinAttachment>? digitalTwinAttachments,
  }) {
    return ScreenBodyLayout(
        mainAxisAlignment: MainAxisAlignment.center,
        padding: const EdgeInsets.only(top: 0, bottom: 15),
        children: [
          Column(
            children: [
              const SizedBox(height: 20),
              SizedBox(
                width: MediaQuery.of(context).size.width * 0.8,
                child: Align(
                  alignment: Alignment.center,
                  child: Text(
                    textAlign: TextAlign.center,
                    context.loc.selectAttachmentYouWantToEdit,
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                ),
              ),
              const SizedBox(
                height: 20,
              ),
              AttachmentUploadButton(
                text: context.loc.uploadDigitalContent,
                icon: Icons.add,
                metadataId: metadata?.id,
              ),
              const SizedBox(height: 10),
              hasMinterRole.when(
                  data: (hasMinterRole) {
                    if (hasMinterRole) {
                      return Column(
                        children: [
                          creatorAttachments.isNotEmpty
                              ? Align(
                                  alignment: Alignment.centerLeft,
                                  child: Text(
                                    context.loc.creatorContent,
                                  ),
                                )
                              : Container(),
                          const SizedBox(height: 10),
                          for (var i = 0; i < creatorAttachments.length; i++)
                            Column(children: [
                              AttachmentBox(
                                text: creatorAttachments[i].title,
                                icon: creatorAttachments[i].type ==
                                        AttachmentType.url
                                    ? Icons.link
                                    : Icons.attach_file,
                                isPrivate: creatorAttachments[i].isPrivate,
                                onTap: () {
                                  final digitalTwinAttachment =
                                      digitalTwinAttachments?.firstWhereOrNull(
                                          (element) =>
                                              element.attachmentUuid ==
                                              creatorAttachments[i]
                                                  .backendUuid);

                                  Navigator.pushNamed(
                                      context, AddAttachmentScreen.routeName,
                                      arguments: AttachmentScreensArguments(
                                        true, creatorAttachments[i].type,
                                        //gets index of attachment that is being edited in localAttachmentsProvider list
                                        index: attachments.indexWhere((e) =>
                                            e.backendUuid ==
                                            creatorAttachments[i].backendUuid),
                                        twinAttachment: digitalTwinAttachment,
                                        metadataId: metadata?.id,
                                      ));
                                },
                              ),
                              const SizedBox(height: 10),
                            ])
                        ],
                      );
                    } else {
                      return Container();
                    }
                  },
                  loading: () => Container(),
                  error: (error, stack) => Container()),
              ownerAttachments.isNotEmpty
                  ? Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        context.loc.ownerContent,
                      ),
                    )
                  : Container(),
              const SizedBox(height: 10),
              for (var i = 0; i < ownerAttachments.length; i++)
                Column(children: [
                  AttachmentBox(
                    text: ownerAttachments[i].title,
                    icon: ownerAttachments[i].type == AttachmentType.url
                        ? Icons.link
                        : Icons.attach_file,
                    isPrivate: ownerAttachments[i].isPrivate,
                    onTap: () {
                      Navigator.pushNamed(
                        context,
                        AddAttachmentScreen.routeName,
                        arguments: AttachmentScreensArguments(
                          true, ownerAttachments[i].type,
                          //gets index of attachment that is being edited in localAttachmentsProvider list
                          index: attachments.indexWhere((e) =>
                              e.backendUuid == ownerAttachments[i].backendUuid),
                          metadataId: metadata?.id,
                          twinAttachment: digitalTwinAttachments?.firstWhereOrNull(
                              (element) =>
                                  element.attachmentUuid ==
                                  ownerAttachments[i].backendUuid),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 10),
                ]),
            ],
          )
        ]);
  }
}
