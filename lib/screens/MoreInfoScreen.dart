//import packages
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ownerchip_whitelabel/config/wallets.dart';
import 'package:ownerchip_whitelabel/screens/AdminInitCard.dart';
import 'package:ownerchip_whitelabel/screens/CardLostScreen.dart';
import 'package:ownerchip_whitelabel/screens/EnterPukScreen.dart';
import 'package:ownerchip_whitelabel/screens/EnterShippingAddressScreen.dart';
import 'package:ownerchip_whitelabel/services/providers/accountDeletionRequest/accountDeletionRequestNotifier.dart';
import 'package:ownerchip_whitelabel/services/providers/userData.dart';
import 'package:ownerchip_whitelabel/services/nfc.services.dart';
import 'package:ownerchip_whitelabel/widgets/popups/CustomPopup.dart';
import 'package:ownerchip_whitelabel/widgets/popups/returnSnackBarWidget.dart';
import 'package:ownerchip_whitelabel/widgets/ui/DisplayLongStringWithCopy.dart';
import 'package:url_launcher/url_launcher.dart';

//import widgets
import 'package:ownerchip_whitelabel/widgets/layout/ScreenBodyLayout.dart';
import 'package:ownerchip_whitelabel/widgets/ui/appBar/CustomAppBar.dart';
import 'package:ownerchip_whitelabel/widgets/ui/CustomRoundedButton.dart';
import 'package:ownerchip_whitelabel/widgets/ui/CustomOutlinedButton.dart';

//import misc
import 'package:ownerchip_whitelabel/utils/localization.helper.dart';
import 'package:ownerchip_whitelabel/config/moreInfoButtons.dart';

import '../services/providers/walletconnectData.dart';

class MoreInfoScreen extends ConsumerStatefulWidget {
  const MoreInfoScreen({Key? key}) : super(key: key);

  static const routeName = '/moreInfo';

  @override
  _MoreInfoScreenState createState() => _MoreInfoScreenState();
}

class _MoreInfoScreenState extends ConsumerState<MoreInfoScreen> {
  @override
  Widget build(BuildContext context) {
    final session = ref.watch(userSessionProvider);
    final walletType = ref.watch(walletTypeProvider);
    final accountDeletionRequest = ref.watch(accountDeletionRequestProvider);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: const CustomAppBar(
        showBackButton: true,
      ),
      body: ScreenBodyLayout(
          mainAxisAlignment: MainAxisAlignment.center,
          flexSides: 0,
          padding: const EdgeInsets.only(top: 0, bottom: 15),
          children: [
            const SizedBox(height: 20),
            SizedBox(
              width: MediaQuery.of(context).size.width * 0.8,
              child: Align(
                alignment: Alignment.center,
                child: Text(
                  textAlign: TextAlign.center,
                  context.loc.infoScreenText,
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
              ),
            ),
            const SizedBox(
              height: 60,
            ),
            ...MoreInfoButtons(
              dotenv.get('APP_ID'),
              context.loc,
              session?.jwt.raw,
            )
                .roundedButtons
                .map((button) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: CustomRoundedButton(
                        text: button.text,
                        onPressed: () => {
                              launchUrl(Uri.parse(button.url),
                                  mode: LaunchMode.externalApplication)
                            },
                        width: 250)))
                .toList(),
            Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: CustomRoundedButton(
                    text: context.loc.resetPIN,
                    onPressed: () => {
                          Navigator.pushNamed(context, EnterPukScreen.routeName)
                        },
                    width: 250)),
            Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: CustomRoundedButton(
                    text: context.loc.cardLost,
                    onPressed: () async {
                      Navigator.pushNamed(context, CardLostScreen.routeName);
                    },
                    width: 250)),
            dotenv.get('BITRISEIO_PACKAGE_NAME') == 'com.ownerchip.internal'
                ? Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: CustomRoundedButton(
                        text: 'Admin Init Card',
                        onPressed: () => {
                              Navigator.pushNamed(
                                  context, AdminInitCard.routeName)
                            },
                        width: 250))
                : Container(),
            const SizedBox(height: 60),
            if (session != null && walletType?.type == EWalletType.privy)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: CustomOutlinedButton(
                  buttonText: context.loc.accountDeletionButton,
                  onPressed: () => {
                    if (accountDeletionRequest.response == null)
                      {
                        showCustomPopup(
                          context,
                          context.loc.accountDeletionPopupTitle,
                          Column(
                            children: [
                              Text(
                                context.loc.accountDeletionPopupMessage,
                              ),
                              const SizedBox(
                                height: 24,
                              ),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceAround,
                                mainAxisSize: MainAxisSize.max,
                                children: [
                                  CustomRoundedButton(
                                    text: context
                                        .loc.accountDeletionPopupCancelButton,
                                    onPressed: () {
                                      Navigator.of(context).pop();
                                    },
                                    width: 100,
                                  ),
                                  CustomRoundedButton(
                                    text: context
                                        .loc.accountDeletionPopupDeleteButton,
                                    onPressed: () {
                                      ref
                                          .read(accountDeletionRequestProvider
                                              .notifier)
                                          .deleteAccount();
                                      Navigator.of(context).pop();

                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        returnSnackBarWidget(
                                          context.loc
                                              .accountDeletionSentNotificationTitle,
                                          context.loc
                                              .accountDeletionSentNotificationMessage,
                                          'success',
                                        ),
                                      );
                                    },
                                    width: 100,
                                    backgroundColor:
                                        Theme.of(context).colorScheme.error,
                                  ),
                                ],
                              )
                            ],
                          ),
                        )
                      }
                    else
                      {
                        showCustomPopup(
                          context,
                          context.loc.accountDeletionInProgressPopupTitle,
                          Column(
                            children: [
                              Text(
                                context
                                    .loc.accountDeletionInProgressPopupMessage,
                              ),
                              const SizedBox(
                                height: 24,
                              ),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceAround,
                                mainAxisSize: MainAxisSize.max,
                                children: [
                                  CustomRoundedButton(
                                    text: context.loc
                                        .accountDeletionInProgressPopupOkButton,
                                    onPressed: () {
                                      Navigator.of(context).pop();
                                    },
                                    width: 100,
                                  ),
                                  CustomRoundedButton(
                                    text: context.loc
                                        .accountDeletionInProgressPopupCancelButton,
                                    onPressed: () {
                                      ref
                                          .read(accountDeletionRequestProvider
                                              .notifier)
                                          .cancelAccountDeletion();
                                      Navigator.of(context).pop();

                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        returnSnackBarWidget(
                                          context.loc
                                              .accountDeletionCanceledNotificationTitle,
                                          context.loc
                                              .accountDeletionCanceledNotificationMessage,
                                          'success',
                                        ),
                                      );
                                    },
                                    backgroundColor:
                                        Theme.of(context).colorScheme.error,
                                    width: 100,
                                  ),
                                ],
                              )
                            ],
                          ),
                        )
                      }
                  },
                  width: 250,
                  disabled: accountDeletionRequest.loading ||
                      !accountDeletionRequest.initialized,
                  color: Theme.of(context).colorScheme.error,
                ),
              ),
            ...MoreInfoButtons(
              dotenv.get('APP_ID'),
              context.loc,
              session?.jwt.raw,
            )
                .outlinedRoundedButtons
                .map((button) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: CustomOutlinedButton(
                        buttonText: button.text,
                        onPressed: () => {
                              launchUrl(Uri.parse(button.url),
                                  mode: LaunchMode.externalApplication)
                            },
                        width: 250)))
                .toList(),
            const SizedBox(height: 20),
            Text('Version: ${dotenv.get('VERSION_NUMBER')}',
                style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 10),
            ref.read(userSessionProvider) != null
                ? Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Wallet: ',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      DisplayLongStringWithCopy(
                        textCopiedMessage:
                            context.loc.walletAddressCopiedToClipboard,
                        string: ref
                            .read(userSessionProvider)!
                            .userWalletAddress
                            .hex,
                        textStyles: Theme.of(context).textTheme.bodySmall,
                        iconSize: 18,
                      )
                    ],
                  )
                : Container()
          ]),
    );
  }
}
