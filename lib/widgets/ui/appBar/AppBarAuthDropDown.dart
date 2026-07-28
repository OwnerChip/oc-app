import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ownerchip_whitelabel/config/constants.dart';
import 'package:ownerchip_whitelabel/screens/myBalance/MyBalanceScreen.dart';
import 'package:ownerchip_whitelabel/screens/qrCode/QRCodeScannerScreen.dart';
import 'package:ownerchip_whitelabel/screens/qrCode/websocket_connection_error_popup.dart';
import 'package:ownerchip_whitelabel/services/backend/auth/backendAuth.dart';
import 'package:ownerchip_whitelabel/services/providers/creations/creationsNotifier.dart';
import 'package:ownerchip_whitelabel/services/providers/userData.dart';
import 'package:ownerchip_whitelabel/services/providers/walletconnectData.dart';
import 'package:ownerchip_whitelabel/services/providers/privy/privyNotifier.dart';
import 'package:ownerchip_whitelabel/services/privyService.dart';
import 'package:ownerchip_whitelabel/services/providers/websocket/websocketNotifier.dart';
import 'package:ownerchip_whitelabel/themes/colorSpecs.dart';
import 'package:ownerchip_whitelabel/utils/globals.dart';
import 'package:ownerchip_whitelabel/utils/localization.helper.dart';
import 'package:ownerchip_whitelabel/utils/logger.dart';
import 'package:ownerchip_whitelabel/widgets/popups/CustomPopup.dart';
import 'package:ownerchip_whitelabel/widgets/popups/returnSnackBarWidget.dart';
import 'package:ownerchip_whitelabel/widgets/ui/CustomSnackBarContent.dart';
import 'package:ownerchip_whitelabel/widgets/ui/appBar/CustomAppBar.dart';
import 'package:reown_appkit/reown_appkit.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppBarAuthDropDown extends ConsumerStatefulWidget {
  const AppBarAuthDropDown({
    super.key,
    required this.closeOverlay,
    required this.parentContext,
  });

  final Function closeOverlay;
  final BuildContext parentContext;

  @override
  ConsumerState<ConsumerStatefulWidget> createState() =>
      _AppBarAuthDropDownState();
}

class _AppBarAuthDropDownState extends ConsumerState<AppBarAuthDropDown> {
  @override
  Widget build(BuildContext context) {
    final userSession = ref.watch(userSessionProvider);
    return Material(
      color: Colors.transparent,
      child: Stack(
        children: [
          GestureDetector(
            onTap: () {
              widget.closeOverlay();
            },
            child: Container(
              color: Colors.black.withOpacity(0.05),
            ),
          ),
          Positioned(
            right: 12,
            top: CustomAppBar.kCustomAppBarHeight - 16,
            width: 220,
            height: 160,
            child: Container(
              decoration: BoxDecoration(
                color: CustomColors(dotenv.get('APP_ID')).cardColor,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    spreadRadius: 1,
                    blurRadius: 5,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: 8.0,
                  horizontal: 24,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: userSession != null
                      ? [
                          _buildItem(
                              context,
                              _copyAddress,
                              (
                                BuildContext context,
                              ) =>
                                  Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        context.loc.appBarWalletIdTitle,
                                        style: Theme.of(context)
                                            .textTheme
                                            .headlineSmall!
                                            .copyWith(fontSize: 14),
                                      ),
                                      const SizedBox(
                                        width: 12,
                                      ),
                                      Icon(
                                        Icons.copy,
                                        color:
                                            CustomColors(dotenv.get('APP_ID'))
                                                .primaryColor,
                                      ),
                                    ],
                                  )),
                          _buildDivider(),
                          _buildItem(
                            context,
                            () {
                              _onBalanceClicked(context);
                            },
                            (context) => Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  context.loc.appbarMyBalanceButton,
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ],
                            ),
                          ),
                          _buildDivider(),
                          _buildItem(
                            context,
                            () {
                              _onScanQRClicked(context);
                            },
                            (context) => Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  context.loc.scanQRCode,
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ],
                            ),
                          ),
                          _buildDivider(),
                          _buildItem(
                            context,
                            () {
                              _onLogoutClicked(context);
                            },
                            (context) => Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  context.loc.logout,
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ],
                            ),
                          ),
                        ]
                      : [
                          const CircularProgressIndicator(),
                        ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItem(
    BuildContext context,
    VoidCallback onTap,
    Widget Function(
      BuildContext context,
    ) builder,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 200,
        height: 24,
        color: Colors.transparent,
        child: builder(context),
      ),
    );
  }

  void _onLogoutClicked(BuildContext context) async {
    await disconnectWallet(ref, context);
    Navigator.of(context).popUntil((route) => route.isFirst);
    widget.closeOverlay();
  }

  void _onBalanceClicked(BuildContext context) {
    Navigator.of(context).popUntil((route) => route.isFirst);
    Navigator.of(context).pushNamed(MyBalancePage.routeName);
    widget.closeOverlay();
  }

  void _onScanQRClicked(BuildContext context) {
    final messenger = ScaffoldMessenger.of(
      ScaffoldKey.getScaffoldKey("HomeScreen").currentContext ??
          navigatorKey.currentContext!,
    );

    final socket = ref.read(websocketProvider);

    if (!socket.connected) {
      showCustomPopup(
        context,
        context.loc.errorHeadingSnackBar,
         WebsocketConnectionErrorPopup(
          parentContext: widget.parentContext,
        ),
      );
      widget.closeOverlay();
      return;
    }

    final sessionId = ref.read(userSessionProvider)!.sessionId;
    final socketId = socket.socket!.id!;

    Navigator.of(context)
        .pushNamed(QRCodeScannerScreen.routeName)
        .then((dynamic response) {
      if (response == null) {
        return null;
      }
      if (response is! String) {
        return null;
      }

      final split = response.split(':');

      if (split[0] == "OWNERCHIP_LOGIN") {
        final requestId = split[1];

        BackendAuth.confirmQrCodeLogin(
          requestId: requestId,
          sessionId: sessionId,
          socketId: socketId,
        ).then((value) {
          if (value) {
            messenger.showSnackBar(
              returnSnackBarWidget(
                context.loc.successHeadingSnackbar,
                context.loc.walletAuthenticated,
                'success',
              ),
            );
          } else {
            messenger.showSnackBar(
              returnSnackBarWidget(
                context.loc.errorHeadingSnackBar,
                context.loc.invalidQRCode,
                'error',
              ),
            );
          }
        });
      } else {
        messenger.showSnackBar(
          returnSnackBarWidget(
            context.loc.errorHeadingSnackBar,
            context.loc.invalidQRCode,
            'error',
          ),
        );
      }
    });
    widget.closeOverlay();
  }

  void _copyAddress() {
    final userSession = ref.read(userSessionProvider);
    if (userSession == null) return;

    Clipboard.setData(ClipboardData(text: userSession.userWalletAddress.hex));
    ScaffoldMessenger.of(context).showSnackBar(
      returnSnackBarWidget(
        context.loc.successHeadingSnackbar,
        context.loc.copiedAddressToClipboard,
        'success',
      ),
    );
  }

  Divider _buildDivider() {
    return Divider(
      color: CustomColors(dotenv.get('APP_ID')).boxDecorationColor,
    );
  }
}

Future<void> disconnectWallet(
  WidgetRef ref,
  BuildContext context,
) async {
  final wc = ref.read(w3mServiceProvider);
  ReownAppKitModalSession? wcSession = ref.watch(wcSessionProvider);

  //reset providers
  ref.read(userAddressProvider.notifier).state = zeroAddress;
  ref.read(walletTypeProvider.notifier).state = null;
  ref.read(userSessionProvider.notifier).state = null;
  ref.read(websocketProvider.notifier).disconnect();
  ref.read(creationsNotifierProvider.notifier).onLogout();

  final storage = await SharedPreferences.getInstance();

  //remove session and wallet type from storage
  storage.remove('walletType');
  storage.remove('userSession');

  ref.refresh(privyNotifierProvider);

  try {
    await privyInstance.logout();
  } catch (e) {
    talker.error('Error logging out of Privy', e);
  }

  if (wc != null && wcSession != null) {
    await wc
        .disconnect(); //WC disconnect event is triggered and riverpod state is deleted in listener
  }

  await BackendAuth.terminateSession();

  try {
    // clean up services
    await BackendAuth.initGuestSession();
  } catch (e) {
    talker.error('Error cleaning up services', e);
  }

  //navigate back until homescreen
  Navigator.of(context).popUntil((route) => route.isFirst);
}
