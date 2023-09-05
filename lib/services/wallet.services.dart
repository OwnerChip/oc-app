//package imports
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ownerchip_whitelabel/screens/PinScreen.dart';
import 'package:ownerchip_whitelabel/services/providers.services.dart';
import 'package:ownerchip_whitelabel/services/scan.services.dart';
import 'package:ownerchip_whitelabel/services/signature.services.dart';
import 'package:ownerchip_whitelabel/utils/navigationArguments.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:web3dart/crypto.dart';
import 'package:web3dart/web3dart.dart';
import 'package:url_launcher/url_launcher_string.dart';
import 'package:flutter/services.dart';

//misc imports
import 'package:ownerchip_whitelabel/domain/classDefinition.dart';
import 'package:ownerchip_whitelabel/utils/utils.dart';
import 'package:ownerchip_whitelabel/domain/eip155.dart';

//service imports
import 'package:ownerchip_whitelabel/services/web3.services.dart';
import 'package:ownerchip_whitelabel/services/backend.services.dart';
import 'package:ownerchip_whitelabel/services/gasstation.services.dart';
import 'package:walletconnect_flutter_v2/walletconnect_flutter_v2.dart';

import '../widgets/popups/AuthPopup.dart';

// This function starts a wallet connection with the WalletConnect connector.
Future<ConnectResponse> startWalletConnection(
    BuildContext context, WidgetRef ref, Web3App wc, WalletType wallet) async {
  List<String> chains = [];

  // store walletType
  ref.read(walletTypeProvider.notifier).state = wallet;
  final storage = SharedPreferences.getInstance();
  storage.then(
      (value) => value.setString('walletType', jsonEncode(wallet.toJson())));

  //TODO: connect to all supported chainIds ... once MetaMask complies with WC2
  switch (wallet.name) {
    case 'Metamask':
      chains = ['eip155:1'];
      break;
    case 'Trust Wallet':
      chains = ['eip155:1', 'eip155:137'];
      break;
    case '1inch Wallet':
      chains = ['eip155:1'];
      break;
    default:
      chains = ['eip155:1', 'eip155:137', 'eip155:80001'];
      break;
  }
  ConnectResponse wcResp = await wc.connect(requiredNamespaces: {
    'eip155': RequiredNamespace(
        chains: chains,
        methods: [
          'eth_sendTransaction',
          'eth_signTypedData_v4',
          'personal_sign'
        ],
        events: EIP155.events.values.toList()),
  });
  String? uri = wcResp.uri.toString();
  Uri walletDeepLink = convertToWcLink(appLink: wallet.deeplinkUri, wcUri: uri);

  await launchUrlString(walletDeepLink.toString(),
      mode: LaunchMode.externalApplication);
  SessionData session = await wcResp.session.future;
  Navigator.pop(context);
  authPopupBuilder(context, ref, wc, wallet.name);

  return wcResp;
}

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

// This code creates a gasless transaction.
// It calls the makeGaslessParams function to get the typedData and request parameters,
// and then sends a custom request to the WalletConnect client to get the signature.
// It then sends the gasless transaction request to the backend and returns the txnHash.

Future<String> makeAndSendGaslessTx(
    WidgetRef ref,
    BuildContext context,
    String functionSignatureHash,
    int chainId,
    EthereumAddress collectionId,
    SignatureData signatureData,
    EthereumAddress walletAddress,
    Web3App? wc, //Note: wc and wcSession are null if OwnerCard is used for tx
    SessionData? wcSession,
    String metaTxAgreementId,
    WalletType walletType,
    {EthereumAddress? toAccount,
    String? cid,
    BigInt? tokenId,
    bool? enableRecovery,
    required Function toggleLoading}) async {
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
      tokenId: tokenId,
      enableRecovery: enableRecovery);
  final Map<String, dynamic> typedData = gaslessTxParams[0];
  final Map<String, dynamic> request = gaslessTxParams[1];

  try {
    String signature;
    if (walletType.name == 'OwnerCard') {
      String hash = await getGaslessTxHash(request, collectionId);

      var cardSignature =
          // ignore: use_build_context_synchronously
          await Navigator.pushNamed(context, PinScreen.routeName,
              arguments: PinScreenArguments(
                  activeFeature: PinScreenActiveFeature.verifyPinTx,
                  callback: (String pin) async {
                    return await makeCardSignature(
                        ref, context, hash, toggleLoading, pin);
                  })) as MsgSignature;

      signature = msgSignatureToHex(cardSignature);
    } else {
      String walletLink = walletType.deeplinkUri;
      Uri walletDeepLink = convertToWcLink(appLink: walletLink, wcUri: "wc:");

      //turn off loading while user is in Metamask/Other Wallet
      toggleLoading();
      await launchUrlString(walletDeepLink.toString(),
          mode: LaunchMode.externalApplication);

      signature = await wc!.request(
        topic: wcSession!.topic,
        chainId: 'eip155:1',
        request: SessionRequestParams(
          method: 'eth_signTypedData_v4',
          params: [walletAddress.toString(), json.encode(typedData)],
        ),
      );
      //turn on loading again, while waiting for gasless tx to be mined
      toggleLoading();
    }

    String txnHash = await sendGaslessRequest(
        collectionId, signature, metaTxAgreementId, request);
    return txnHash;
  } catch (e) {
    print(e);
    rethrow;
  }
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
    Web3App wc,
    SessionData wcSession,
    WalletType walletType,
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
      tokenURI: cid != null ? "ipfs://$cid" : null,
      enableRecovery: false);

  String walletLink = walletType.deeplinkUri;
  Uri walletDeepLink = convertToWcLink(appLink: walletLink, wcUri: "wc:");
  await launchUrlString(walletDeepLink.toString(),
      mode: LaunchMode.externalApplication);

  String txnHash = await wc.request(
    topic: wcSession.topic,
    chainId: 'eip155:$chainId',
    request: SessionRequestParams(
      method: 'eth_sendTransaction',
      params: txParams,
    ),
  );

  return txnHash;
}

//personal sign
Future<String> sendPersonalSignRequest(
  String message,
  EthereumAddress walletAddress,
  Web3App wc,
  SessionData wcSession,
  WalletType walletType,
) async {
  Uri walletDeepLink =
      convertToWcLink(appLink: walletType.deeplinkUri, wcUri: "wc:");

  await launchUrlString(walletDeepLink.toString(),
      mode: LaunchMode.externalApplication);

  List<int> utf8CodeUnits = utf8.encode(message);
  String hexUtf8EncodedMessage =
      "0x" + utf8CodeUnits.map((e) => e.toRadixString(16)).join();

  String signature = await wc.request(
    topic: wcSession.topic,
    chainId: 'eip155:1',
    request: SessionRequestParams(
      method: 'personal_sign',
      params: [hexUtf8EncodedMessage, walletAddress.toString()],
    ),
  );

  return signature;
}

Future<String> getGaslessTxHash(request, collectionId) async {
  String hash = await getEthSignTypedDataSignature(collectionId, request);

  return hash;
}
