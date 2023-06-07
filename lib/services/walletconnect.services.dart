// ignore_for_file: use_build_context_synchronously

//package imports
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:web3dart/web3dart.dart';
import 'package:url_launcher/url_launcher_string.dart';
import 'package:walletconnect_dart/walletconnect_dart.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:walletconnect_secure_storage/walletconnect_secure_storage.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';

//misc imports
import 'package:ownerchip_whitelabel/domain/classDefinition.dart';
import 'package:ownerchip_whitelabel/utils/utils.dart';
import 'package:ownerchip_whitelabel/utils/localization.helper.dart';
import 'package:ownerchip_whitelabel/widgets/ui/returnSnackBarWidget.dart';

//service imports
import 'package:ownerchip_whitelabel/services/web3.services.dart';
import 'package:ownerchip_whitelabel/services/backend.services.dart';
import 'package:ownerchip_whitelabel/services/gasstation.services.dart';
import 'package:walletconnect_flutter_v2/walletconnect_flutter_v2.dart';

Future<WalletConnect> createWalletConnector() async {
  WalletConnectSecureStorage sessionStorage = WalletConnectSecureStorage();
  WalletConnectSession? session = await sessionStorage.getSession();

  //store current time to check if session is expired
  var now = DateTime.now().millisecondsSinceEpoch;
  int sessionDuration = 1000 * 60 * 60 * 48; //2 days

  final storage = await SharedPreferences.getInstance();
  final prevSessionExpiration = storage.getInt('sessionExpirationTime') ?? 0;
  if (now > prevSessionExpiration) {
    //session expired
    await sessionStorage.removeSession();
    session = null;
    storage.setInt('sessionExpirationTime', now + sessionDuration);
  }

  return WalletConnect(
      bridge: 'https://bridge.walletconnect.org',
      session: session == null || !session.connected ? null : session,
      sessionStorage: sessionStorage,
      clientMeta: const PeerMeta(
        name: 'OwnerChip Demo',
        description: 'Connecting physical objects to the blockchain.',
        url: 'https://walletconnect.org',
        // icons: ["${dotenv.get('IMAGE_ASSETS_BASE_URL')}/app_logo.png"]
      ));
}

// This function starts a wallet connection with the WalletConnect connector.
Future<void> startWalletConnection(
    BuildContext context, WalletConnect connector) async {
  try {
    await connector.connect(onDisplayUri: (uri) async {
      await launchUrlString(uri, mode: LaunchMode.externalApplication);
    });
    connector.sessionStorage?.store(connector.session);
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(returnSnackBarWidget(
        context.loc.errorHeadingSnackBar,
        context.loc.errorConnectingWallet,
        'success'));
    print(e);
  }
}

// Future<ConnectResponse?> startWalletConnection2(
//     BuildContext context, Web3App wcClient) async {
//   try {
//     return await wcClient.connect(requiredNamespaces: {
//       'eip155': const RequiredNamespace(
//         chains: ['eip155:1'], // Ethereum chain
//         methods: [
//           'eth_sendTransaction',
//           'eth_signTypedData',
//           'personal_sign'
//         ], // Requestable Methods
//         events: ['accountsChanged'], // Requestable Methods
//       ),
//     });
//   } catch (e) {
//     ScaffoldMessenger.of(context).showSnackBar(returnSnackBarWidget(
//         context.loc.errorHeadingSnackBar,
//         context.loc.errorConnectingWallet,
//         'success'));
//     print(e);
//     return null;
//   }
// }

Uri convertToWcLink({
  required String appLink,
  required String wcUri,
  bool isDeepLink = false,
}) {
  final wcPath = 'wc?uri=${Uri.encodeComponent(wcUri)}';
  if (isDeepLink) {
    final scheme = Uri.tryParse(appLink)?.scheme;
    if (scheme != null) {
      return Uri.parse('$scheme://$wcPath');
    }
  }
  return Uri.parse('$appLink/$wcPath');
}

Future<void> showQrCode(
  BuildContext context,
  ConnectResponse response,
) async {
  // Show the QR code
  debugPrint('Showing QR Code: ${response.uri}');

  await showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: const Text(
          'Show QR Code',
          textAlign: TextAlign.center,
        ),
        content: SizedBox(
          width: 300,
          height: 350,
          child: Center(
            child: Column(
              children: [
                QrImageView(
                  data: response.uri!.toString(),
                ),
                const SizedBox(
                  height: 16,
                ),
                ElevatedButton(
                  onPressed: () async {
                    await Clipboard.setData(
                      ClipboardData(
                        text: response.uri!.toString(),
                      ),
                    );
                    // await showPlatformToast(
                    //   child: const Text(
                    //     StringConstants.copiedToClipboard,
                    //   ),
                    //   context: context,
                    // );
                  },
                  child: const Text(
                    'Copy URL to Clipboard',
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}

// This code creates a gasless transaction.
// It calls the makeGaslessParams function to get the typedData and request parameters,
// and then sends a custom request to the WalletConnect client to get the signature.
// It then sends the gasless transaction request to the backend and returns the txnHash.

Future<String> makeAndSendGaslessTx(
    String functionSignatureHash,
    int chainId,
    EthereumAddress collectionId,
    SignatureData signatureData,
    EthereumAddress walletAddress,
    WalletConnect wc,
    String metaTxAgreementId,
    {EthereumAddress? toAccount,
    String? cid}) async {
  final List<Map<String, dynamic>> gaslessTxParams = await makeGaslessParams(
    functionSignatureHash: functionSignatureHash,
    chainRpcUrl: getRPCUrlFromChainId(chainId),
    chainId: chainId,
    randomValueHash: signatureData.hashedMsg,
    signature: signatureData.signature,
    from: walletAddress,
    to: collectionId,
    toAccount: toAccount,
    tokenURI: cid != null ? "ipfs://$cid" : null,
  );
  final Map<String, dynamic> typedData = gaslessTxParams[0];
  final Map<String, dynamic> request = gaslessTxParams[1];

  //open metamask application
  await launchUrlString('wc:', mode: LaunchMode.externalApplication);

  String signature = await wc.sendCustomRequest(
      method: 'eth_signTypedData_v4',
      params: [walletAddress.toString(), json.encode(typedData)],
      id: makeRandomInt());

  String txnHash = await sendGaslessRequest(
      collectionId, signature, metaTxAgreementId, request);
  return txnHash;
}

// This code creates a normal transaction.
//It calls the buildEthSendTransactionRequest function to get the transaction parameters,
//and then sends a custom request to the WalletConnect client to send the transaction.
//It then returns the txnHash.

Future<String> makeAndSendNormalTx(
    String functionSignatureHash,
    int chainId,
    EthereumAddress collectionId,
    SignatureData signatureData,
    EthereumAddress walletAddress,
    WalletConnect wc,
    {EthereumAddress? toAccount,
    String? cid}) async {
  var txParams = await buildEthSendTransactionRequest(
      getRPCUrlFromChainId(chainId),
      collectionId,
      walletAddress,
      functionSignatureHash,
      signatureData.hashedMsg,
      signatureData.signature,
      toAccount: toAccount,
      tokenURI: cid != null ? "ipfs://$cid" : null);

  //open metamask application
  await launchUrlString('wc:', mode: LaunchMode.externalApplication);

  String txnHash = await wc.sendCustomRequest(
      method: 'eth_sendTransaction', params: txParams, id: makeRandomInt());
  return txnHash;
}
