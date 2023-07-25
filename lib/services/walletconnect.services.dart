//package imports
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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

// This function starts a wallet connection with the WalletConnect connector.
Future<ConnectResponse> startWalletConnection(
    BuildContext context, WidgetRef ref, Web3App wc, WalletType wallet) async {
  List<String> chains = [];
  //TODO: connect to all supported chainIds ... once MetaMask complies with WC2
  switch (wallet.name) {
    case 'Metamask':
      chains = ['eip155:1'];
      break;
    case 'Trust Wallet':
      chains = ['eip155:1', 'eip155:137'];
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
          'eth_signTypedData',
          'eth_signTypedData_v4',
          'personal_sign'
        ],
        events: EIP155.events.values.toList()),
  });
  String? uri = wcResp.uri.toString();
  Uri walletDeepLink = convertToWcLink(appLink: wallet.deeplinkUri, wcUri: uri);

  await launchUrlString(walletDeepLink.toString(),
      mode: LaunchMode.externalApplication);
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
    String functionSignatureHash,
    int chainId,
    EthereumAddress collectionId,
    SignatureData signatureData,
    EthereumAddress walletAddress,
    Web3App wc,
    SessionData wcSession,
    String metaTxAgreementId,
    WalletType walletType,
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

  String walletLink = walletType.deeplinkUri;
  Uri walletDeepLink = convertToWcLink(appLink: walletLink, wcUri: "wc:");
  await launchUrlString(walletDeepLink.toString(),
      mode: LaunchMode.externalApplication);

  String signature = await wc.request(
    topic: wcSession.topic,
    chainId: 'eip155:1',
    request: SessionRequestParams(
      method: 'eth_signTypedData_v4',
      params: [walletAddress.toString(), json.encode(typedData)],
    ),
  );

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
      tokenURI: cid != null ? "ipfs://$cid" : null);

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
