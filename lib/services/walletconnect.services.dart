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
import 'package:ownerchip_whitelabel/utils/utils.dart';
import 'package:ownerchip_whitelabel/utils/localization.helper.dart';
import 'package:ownerchip_whitelabel/widgets/ui/returnSnackBarWidget.dart';

//service imports
import 'package:ownerchip_whitelabel/services/web3.services.dart';
import 'package:ownerchip_whitelabel/services/backend.services.dart';
import 'package:ownerchip_whitelabel/services/gasstation.services.dart';

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
    await connector.connect(
        chainId:
            80001, //TODO: Unsure what the difference is between passing different chain IDs
        onDisplayUri: (uri) async {
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
    {String? cid}) async {
  final List<Map<String, dynamic>> gaslessTxParams = await makeGaslessParams(
    functionSignatureHash: functionSignatureHash,
    chainRpcUrl: getRPCUrlFromChainId(chainId),
    chainId: chainId,
    tokenIdHash: signatureData.hashedMsg,
    signature: signatureData.signature,
    from: walletAddress,
    to: collectionId,
    tokenURI: cid != null ? "ipfs://$cid" : null,
  );
  final Map<String, dynamic> typedData = gaslessTxParams[0];
  final Map<String, dynamic> request = gaslessTxParams[1];

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
  WalletConnect wc, {
  String? cid,
}) async {
  var txParams = await buildEthSendTransactionRequest(
      getRPCUrlFromChainId(chainId),
      collectionId,
      walletAddress,
      functionSignatureHash,
      signatureData.hashedMsg,
      signatureData.signature,
      tokenURI: cid != null ? "ipfs://$cid" : null);

  String txnHash = await wc.sendCustomRequest(
      method: 'eth_sendTransaction', params: txParams, id: makeRandomInt());
  return txnHash;
}
