//import packages
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ownerchip_whitelabel/services/backend/attachments/backendAttachments.dart';
import 'package:ownerchip_whitelabel/services/images.services.dart';

//import services
import 'package:ownerchip_whitelabel/services/providers/attachmentsData.dart';
import 'package:ownerchip_whitelabel/services/providers/chipData.dart';
import 'package:ownerchip_whitelabel/services/providers/userData.dart';
import 'package:ownerchip_whitelabel/services/providers/walletconnectData.dart';
import 'package:ownerchip_whitelabel/themes/colorSpecs.dart';
import 'package:ownerchip_whitelabel/utils/logger.dart';

//import widgets
import 'package:ownerchip_whitelabel/widgets/layout/ScreenBodyLayout.dart';
import 'package:ownerchip_whitelabel/widgets/popups/CustomPopup.dart';
import 'package:ownerchip_whitelabel/widgets/ui/CustomOutlinedButton.dart';
import 'package:ownerchip_whitelabel/widgets/ui/CustomRoundedButton.dart';
import 'package:ownerchip_whitelabel/widgets/ui/appBar/CustomAppBar.dart';

//import misc
import 'package:ownerchip_whitelabel/utils/localization.helper.dart';
import 'package:ownerchip_whitelabel/domain/classDefinition.dart';
import 'package:ownerchip_whitelabel/domain/local_attachment.dart';

import 'package:ownerchip_whitelabel/utils/navigationArguments.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:web3dart/web3dart.dart';
import '../widgets/ui/AttachmentBox.dart';
import '../widgets/ui/AttachmentUploadButton.dart';
import 'AddAttachmentScreen.dart';

class ListAttachmentsScreen extends ConsumerStatefulWidget {
  const ListAttachmentsScreen({Key? key}) : super(key: key);

  static const routeName = '/listAttachments';

  @override
  _ListAttachmentsScreenState createState() => _ListAttachmentsScreenState();
}

class _ListAttachmentsScreenState extends ConsumerState<ListAttachmentsScreen> {
  List<LocalAttachment>? _originalAttachments;
  bool _isSaving = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final fetched = ref.read(localAttachmentsProvider);
    if (_originalAttachments == null && fetched.isNotEmpty) {
      _originalAttachments =
          List<LocalAttachment>.from(fetched.map((a) => a.copyWith()));
    }
  }

  bool get hasUnsavedChanges {
    final current = ref.watch(localAttachmentsProvider);
    if (_originalAttachments == null ||
        current.length != _originalAttachments!.length) return true;
    for (int i = 0; i < current.length; i++) {
      if (!_isLocalAttachmentContentEqual(current[i], _originalAttachments![i]))
        return true;
    }
    return false;
  }

  bool _isLocalAttachmentContentEqual(LocalAttachment a, LocalAttachment b) {
    return a.title == b.title &&
        a.fileName == b.fileName &&
        a.type == b.type &&
        a.url == b.url &&
        a.isPrivate == b.isPrivate;
  }

  Future<bool> _onWillPop() async {
    if (!hasUnsavedChanges) {
      return true;
    }

    return await showCustomPopup(
        context,
        context.loc.unsaved_attachments_popup_title,
        Flexible(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 10),
              Text(context.loc.unsaved_attachments_popup_message),
              const SizedBox(height: 12),
              Builder(builder: (context) {
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CustomRoundedButton(
                      text:
                          context.loc.unsaved_attachments_popup_leave_button,
                      onPressed: () {
                        Navigator.of(context).pop(true);
                      },
                      width: MediaQuery.of(context).size.width * 0.3,
                    ),
                    const SizedBox(width: 10),
                    CustomOutlinedButton(
                        buttonText: context.loc.unsaved_attachments_popup_cancel_button,
                        onPressed: () {
                          Navigator.of(context).pop(false);
                        },
                    width: MediaQuery.of(context).size.width * 0.3,
                    )
                  ],
                );
              })
            ],
          ),
        ));
  }

  Future<void> saveAllChanges(BuildContext context, WidgetRef ref) async {
    setState(() {
      _isSaving = true;
    });
    final current = ref.read(localAttachmentsProvider);
    final userSession = ref.read(userSessionProvider);
    final userAddress = ref.read(userAddressProvider);
    final chipInfo = ref.read(chipInfoProvider);
    final chainAndCollectionId = await returnChainAndCollectionId(ref);
    final int chainId = chainAndCollectionId[0];
    final EthereumAddress collectionId = chainAndCollectionId[1];
    try {
      // 1. Find deleted attachments (in original, not in current)
      final deleted = _originalAttachments
              ?.where((orig) =>
                  !current.any((curr) => curr.backendUuid == orig.backendUuid))
              .toList() ??
          [];
      for (final del in deleted) {
        await BackendAttachments.deleteAttachmentFromBackend(
          userSession!,
          userAddress,
          chainId,
          collectionId,
          chipInfo.tokenId,
          del.backendUuid,
        );
      }

      // 2. Find new attachments (in current, not in original)
      final newOnes = current
          .where((curr) =>
              _originalAttachments == null ||
              !_originalAttachments!
                  .any((orig) => orig.backendUuid == curr.backendUuid))
          .toList();
      for (final add in newOnes) {
        if (add.type == AttachmentType.url) {
          await saveUrl(
              context, ref, (_) {}, add.title, add.isPrivate, add.url);
        } else {
          await uploadFile(context, ref, (_) {}, add.file!, add.fileName,
              add.isPrivate, add.title);
        }
      }

      // 3. Find updated attachments (in both, but changed)
      final updated = current
          .where((curr) =>
              _originalAttachments != null &&
              _originalAttachments!.any((orig) =>
                  orig.backendUuid == curr.backendUuid &&
                  !_isLocalAttachmentContentEqual(curr, orig)))
          .toList();
      for (final upd in updated) {
        final orig = _originalAttachments!
            .firstWhere((o) => o.backendUuid == upd.backendUuid);
        if (upd.fileName != orig.fileName) {
          await BackendAttachments.deleteAttachmentFromBackend(
            userSession!,
            userAddress,
            chainId,
            collectionId,
            chipInfo.tokenId,
            orig.backendUuid,
          );
        } else {
          await BackendAttachments.putAttachmentMetadataToBackend(
            userSession!,
            userAddress,
            chainId,
            collectionId,
            chipInfo.tokenId,
            upd.backendUuid,
            upd.fileName,
            upd.title,
            upd.isPrivate,
            attachmentUrl: upd.type == AttachmentType.url ? upd.url : null,
          );
        }
      }

      // Refresh remote and local state
      await ref.refresh(fetchAttachmentsProvider.future);
      _originalAttachments =
          List<LocalAttachment>.from(current.map((a) => a.copyWith()));
      _isSaving = false;
      if (mounted) {
        setState(() {});
      }

      try {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.loc.done)),
        );
      } catch (snackError) {
        talker.error('Error showing snackbar: $snackError', snackError);
      }
      // Navigate back after save and refresh
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      Sentry.captureException(e);
      talker.error('Error saving attachments: $e', e);
      _isSaving = false;
      if (mounted) {
        setState(() {});
      }
      try {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.loc.errorUploadingFile)),
        );
      } catch (snackError) {
        talker.error('Error showing snackbar: $snackError', snackError);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<LocalAttachment> attachments =
        ref.watch(localAttachmentsProvider);
    final List<LocalAttachment> ownerAttachments =
        ref.watch(ownerAttachmentsProvider);
    final List<LocalAttachment> creatorAttachments =
        ref.watch(creatorAttachmentsProvider);
    final AsyncValue<bool> hasMinterRole = ref.watch(hasMinterRoleProvider);
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: CustomAppBar(
        text: context.loc.editAttachment,
        showBackButton: true,
        overrideBackButton: () {
          _onWillPop().then((shouldPop) {
            if (shouldPop) {
              // restore original attachments if user decides to leave without saving
              if (_originalAttachments != null) {
                ref.read(localAttachmentsProvider.notifier).state =
                    List<LocalAttachment>.from(
                        _originalAttachments!.map((a) => a.copyWith()));
              }
              Navigator.of(context).pop();
            }
          });
        },
      ),
      body: ScreenBodyLayout(
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
                                    Navigator.pushNamed(
                                        context, AddAttachmentScreen.routeName,
                                        arguments: AttachmentScreensArguments(
                                            true, creatorAttachments[i].type,
                                            //gets index of attachment that is being edited in localAttachmentsProvider list
                                            index: attachments.indexWhere((e) =>
                                                e.backendUuid ==
                                                creatorAttachments[i]
                                                    .backendUuid)));
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
                            context, AddAttachmentScreen.routeName,
                            arguments: AttachmentScreensArguments(
                                true, ownerAttachments[i].type,
                                //gets index of attachment that is being edited in localAttachmentsProvider list
                                index: attachments.indexWhere((e) =>
                                    e.backendUuid ==
                                    ownerAttachments[i].backendUuid)));
                      },
                    ),
                    const SizedBox(height: 10),
                  ]),
              ],
            )
          ]),
      floatingActionButton: hasUnsavedChanges
          ? Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child: AnimatedSwitcher(
                duration: Duration(milliseconds: 350),
                transitionBuilder: (child, animation) =>
                    ScaleTransition(scale: animation, child: child),
                child: _isSaving
                    ? Container(
                        key: ValueKey('saving'),
                        padding: const EdgeInsets.symmetric(
                            vertical: 10, horizontal: 24),
                        decoration: BoxDecoration(
                          color:
                              CustomColors(dotenv.get('APP_ID')).primaryColor,
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.white)),
                            const SizedBox(width: 12),
                            Text(context.loc.loading,
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white)),
                          ],
                        ),
                      )
                    : FloatingActionButton.extended(
                        key: ValueKey('save'),
                        backgroundColor:
                            CustomColors(dotenv.get('APP_ID')).primaryColor,
                        icon: Icon(Icons.save, color: Colors.white),
                        label: Text(
                          context.loc.save,
                          style: TextStyle(
                              fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                        onPressed: () => saveAllChanges(context, ref),
                      ),
              ),
            )
          : null,
    );
  }
}
