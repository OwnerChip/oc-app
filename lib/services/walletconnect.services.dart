// ignore_for_file: use_build_context_synchronously

//package imports
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:web3dart/web3dart.dart';
import 'package:url_launcher/url_launcher_string.dart';
import 'package:walletconnect_dart/walletconnect_dart.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:walletconnect_secure_storage/walletconnect_secure_storage.dart';

//misc imports
import 'package:ownerchip_whitelabel/domain/classDefinition.dart';
import 'package:ownerchip_whitelabel/config/constants.dart';
import 'package:ownerchip_whitelabel/utils/utils.dart';
import 'package:ownerchip_whitelabel/utils/localization.helper.dart';
import 'package:ownerchip_whitelabel/widgets/ui/returnSnackBarWidget.dart';

//service imports
import 'package:ownerchip_whitelabel/services/web3.services.dart';
import 'package:ownerchip_whitelabel/services/backend.services.dart';
import 'package:ownerchip_whitelabel/services/gasstation.services.dart';

//create wallet connector function
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

Future<void> startWalletConnection(
    BuildContext context, WalletConnect connector) async {
  try {
    var sessionStatus = await connector.connect(
        chainId:
            80001, //TODO: Unsure what the difference is between passing different chain IDs
        onDisplayUri: (uri) async {
          await launchUrlString(uri, mode: LaunchMode.externalApplication);
        });
    connector.sessionStorage?.store(connector.session);
  } catch (e) {
    //returnSnackBar
    ScaffoldMessenger.of(context).showSnackBar(returnSnackBarWidget(
        context.loc.errorHeadingSnackBar,
        context.loc.errorConnectingWallet,
        'success'));
    print(e);
  }
  // }
}

Future<String> sendGaslessTx(
    int chainId,
    SignatureData signatureData,
    EthereumAddress walletAddress,
    EthereumAddress collectionId,
    String cid,
    WalletConnect wc,
    metaTxAgreementId) async {
  final List<Map<String, dynamic>> gaslessMintParams = await makeGaslessParams(
    functionSignatureHash: gaslessMintFunctionSignature,
    chainRpcUrl: getRPCUrlFromChainId(chainId),
    chainId: chainId,
    tokenIdHash: signatureData.hashedMsg,
    signature: signatureData.signature,
    from: walletAddress,
    to: collectionId,
    tokenURI: "ipfs://$cid",
  );
  final Map<String, dynamic> typedData = gaslessMintParams[0];
  final Map<String, dynamic> request = gaslessMintParams[1];

  String signature = await wc.sendCustomRequest(
      method: 'eth_signTypedData_v4',
      params: [walletAddress.toString(), json.encode(typedData)],
      id: makeRandomInt());

  String txnHash = await sendGaslessRequest(
      collectionId, signature, metaTxAgreementId, request);
  return txnHash;
}

Future<String> sendNormalTx(
    int chainId,
    EthereumAddress collectionId,
    EthereumAddress walletAddress,
    SignatureData signatureData,
    String cid,
    WalletConnect wc) async {
  // generate mint parameters
  var mintParams = await buildEthSendTransactionRequest(
      getRPCUrlFromChainId(chainId),
      collectionId,
      walletAddress,
      mintFunctionSignature,
      signatureData.hashedMsg,
      signatureData.signature,
      tokenURI: "ipfs://$cid");

  //send mint transaction to metamask
  String txnHash = await wc.sendCustomRequest(
      method: 'eth_sendTransaction', params: mintParams, id: makeRandomInt());
  return txnHash;
}
