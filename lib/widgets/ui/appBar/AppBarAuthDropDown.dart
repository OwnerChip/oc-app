import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ownerchip_whitelabel/config/constants.dart';
import 'package:ownerchip_whitelabel/domain/fcm/fcm_token.dart';
import 'package:ownerchip_whitelabel/screens/myBalance/MyBalanceScreen.dart';
import 'package:ownerchip_whitelabel/services/backend/auth/backendAuth.dart';
import 'package:ownerchip_whitelabel/services/backend/fcm/backendFcm.dart';
import 'package:ownerchip_whitelabel/services/providers/userData.dart';
import 'package:ownerchip_whitelabel/services/providers/walletconnectData.dart';
import 'package:ownerchip_whitelabel/services/providers/web3auth/web3authNotifier.dart';
import 'package:ownerchip_whitelabel/themes/colorSpecs.dart';
import 'package:ownerchip_whitelabel/utils/localization.helper.dart';
import 'package:ownerchip_whitelabel/utils/logger.dart';
import 'package:ownerchip_whitelabel/widgets/popups/returnSnackBarWidget.dart';
import 'package:ownerchip_whitelabel/widgets/ui/appBar/CustomAppBar.dart';
import 'package:walletconnect_flutter_v2/walletconnect_flutter_v2.dart';
import 'package:web3auth_flutter/web3auth_flutter.dart';
import 'package:web3modal_flutter/services/w3m_service/models/w3m_session.dart';

class AppBarAuthDropDown extends ConsumerStatefulWidget {
  const AppBarAuthDropDown({
    super.key,
    required this.closeOverlay,
  });

  final Function closeOverlay;

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
            height: 120,
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
                                      const Icon(Icons.copy),
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
                          CircularProgressIndicator(),
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

  void _onLogoutClicked(BuildContext context) {
    _disconnect(context);
    Navigator.of(context).popUntil((route) => route.isFirst);
    widget.closeOverlay();
  }

  void _onBalanceClicked(BuildContext context) {
    Navigator.of(context).popUntil((route) => route.isFirst);
    Navigator.of(context).pushNamed(MyBalancePage.routeName);
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

  Future<void> _disconnect(
    BuildContext context,
  ) async {
    {
      final wc = ref.read(wcProvider);
      W3MSession? wcSession = ref.watch(wcSessionProvider);

      final session = ref.read(userSessionProvider);
      final FCMToken? fcmToken = session?.fcmToken;

      //reset providers
      ref.read(userAddressProvider.notifier).state = zeroAddress;
      ref.read(walletTypeProvider.notifier).state = null;
      ref.read(userSessionProvider.notifier).state = null;

      final storage = await SharedPreferences.getInstance();

      //remove session and wallet type from storage
      storage.remove('session');
      storage.remove('walletType');
      storage.remove('userSession');

      ref.refresh(web3AuthNotifierProvider);

      try {
        await Web3AuthFlutter.logout().catchError((_) {});
      } catch (e) {
        talker.error('Error logging out of web3auth', e);
      }

      if (wc != null && wcSession != null) {
        await wc.disconnectSession(
            topic: wcSession.topic!,
            reason: const WalletConnectError(
                code: 6000,
                message:
                    'MANUAL DISCONNECT')); //WC disconnect event is triggered and riverpod state is deleted in listener
      }

      final terminated = await BackendAuth.terminateSession();

      // fallback to delete fcm token if session termination failed
      if (!terminated && fcmToken != null) {
        await BackendFCM.deleteFCMToken(fcmToken);
      }

      try {
        // clean up services
        await BackendAuth.initGuestSession();
      } catch (e) {
        talker.error('Error cleaning up services', e);
      }

      //navigate back until homescreen
      Navigator.of(context).popUntil((route) => route.isFirst);
    }
  }
}
