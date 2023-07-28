//import packages
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

//import services
import 'package:ownerchip_whitelabel/services/providers.services.dart';

//import widgets
import 'package:ownerchip_whitelabel/widgets/layout/ScreenBodyLayout.dart';
import 'package:ownerchip_whitelabel/widgets/ui/CustomAppBar.dart';

//import misc
import 'package:ownerchip_whitelabel/utils/localization.helper.dart';
import 'package:ownerchip_whitelabel/domain/classDefinition.dart';

import '../utils/navigation.arguments.dart';
import '../widgets/ui/AttachmentBox.dart';
import 'AddAttachmentScreen.dart';

class ListAttachmentsScreen extends ConsumerStatefulWidget {
  const ListAttachmentsScreen({Key? key}) : super(key: key);

  static const routeName = '/listAttachments';

  @override
  _ListAttachmentsScreenState createState() => _ListAttachmentsScreenState();
}

class _ListAttachmentsScreenState extends ConsumerState<ListAttachmentsScreen> {
  @override
  Widget build(BuildContext context) {
    final List<Attachment> attachments = ref.watch(localAttachmentsProvider);
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: const CustomAppBar(
        text: 'Edit attachment',
        showBackButton: true,
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
                      'Select attachment you want to edit or remove.',
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                  ),
                ),
                const SizedBox(
                  height: 20,
                ),
                for (var i = 0; i < attachments.length; i++)
                  Column(children: [
                    AttachmentBox(
                      text: attachments[i].title,
                      icon: attachments[i].type == AttachmentType.url
                          ? Icons.link
                          : Icons.attach_file,
                      isPrivate: attachments[i].isPrivate,
                      onTap: () {
                        Navigator.pushNamed(
                            context, AddAttachmentScreen.routeName,
                            arguments: AttachmentScreensArguments(
                                true, attachments[i].type,
                                index: i));
                      },
                    ),
                    const SizedBox(height: 10),
                  ]),
              ],
            )
          ]),
    );
  }
}
