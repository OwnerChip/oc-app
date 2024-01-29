//package imports
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ownerchip_whitelabel/config/chains.dart';
import 'package:ownerchip_whitelabel/config/constants.dart';
import 'package:ownerchip_whitelabel/config/wallets.dart';
import 'package:ownerchip_whitelabel/screens/PinScreen.dart';
import 'package:ownerchip_whitelabel/services/providers/nftData.dart';
import 'package:ownerchip_whitelabel/services/providers/userData.dart';
import 'package:ownerchip_whitelabel/services/nfc.services.dart';
import 'package:ownerchip_whitelabel/services/signature.services.dart';
import 'package:ownerchip_whitelabel/utils/globals.dart';
import 'package:ownerchip_whitelabel/utils/localization.helper.dart';
import 'package:ownerchip_whitelabel/utils/navigationArguments.dart';
import 'package:ownerchip_whitelabel/widgets/popups/returnSnackBarWidget.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:web3dart/crypto.dart';
import 'package:web3dart/web3dart.dart';
import 'package:url_launcher/url_launcher_string.dart';
import 'package:ownerchip_whitelabel/services/providers/walletconnectData.dart';
import 'package:web3modal_flutter/web3modal_flutter.dart';

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
    EthereumAddress toAddress,
    SignatureData signatureData,
    EthereumAddress walletAddress,
    Web3App? wc, //Note: wc and wcSession are null if OwnerCard is used for tx
    SessionData? wcSession,
    String metaTxAgreementId,
    WalletType walletType,
    {EthereumAddress? controllerContractId,
    String? typedDataHash,
    EthereumAddress? toAccount,
    String? cid,
    String? voucherTokenCID,
    BigInt? tokenId,
    bool? enableRecovery,
    EthereumAddress? sellerPayoutAddress,
    BigInt? salt,
    int? endTimestamp,
    BigInt? price,
    String? encodedOfferData,
    required Function toggleLoading,
    String? offerHash}) async {
  final List<Map<String, dynamic>> gaslessTxParams = await makeGaslessParams(
      functionSignatureHash: functionSignatureHash,
      chainRpcUrl: getRPCUrlFromChainId(chainId),
      chainId: chainId,
      randomValueHash: signatureData.hashedMsg,
      signature: signatureData.signature,
      from: walletAddress,
      to: controllerContractId ??
          toAddress, //if a controller contract addr is given, the receiver is the controller address, not to address. toAddress is only sent to backend for gas station purposes
      toAccount: toAccount,
      tokenURI: cid != null ? "ipfs://$cid" : null,
      voucherTokenURI:
          voucherTokenCID != null ? "ipfs://$voucherTokenCID" : null,
      tokenId: tokenId,
      enableRecovery: enableRecovery,
      sellerPayoutAddress: sellerPayoutAddress,
      salt: salt,
      endTimestamp: endTimestamp,
      price: price,
      encodedOfferData: encodedOfferData,
      typedDataHash: typedDataHash,
      offerHash: offerHash);
  final Map<String, dynamic> typedData = gaslessTxParams[0];
  final Map<String, dynamic> request = gaslessTxParams[1];

  try {
    String signature;
    if (walletType.name == 'OwnerCard') {
      String hash = await getGaslessTxHash(request, toAddress);

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
      final W3MService? w3mService = ref.read(w3mServiceProvider);
      await w3mService!.launchConnectedWallet();

      toggleLoading();

      signature = await wc!
          .request(
        topic: wcSession!.topic,
        // chainId: 'eip155:$chainId',
        chainId: 'eip155:1',
        request: SessionRequestParams(
          method: 'eth_signTypedData_v4',
          params: [walletAddress.toString(), json.encode(typedData)],
        ),
      )
          .onError((error, stackTrace) {
        throw 'error signing gasless tx';
      });
      //turn on loading again, while waiting for gasless tx to be mined
      toggleLoading();
    }

    String txnHash = await sendGaslessRequest(
        toAddress, signature, metaTxAgreementId, request);
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
  WidgetRef ref,
  String functionSignatureHash,
  int chainId,
  EthereumAddress toAddress,
  SignatureData signatureData,
  EthereumAddress walletAddress,
  Web3App wc,
  SessionData wcSession,
  WalletType walletType, {
  EthereumAddress? toAccount,
  BigInt? tokenId,
  String? cid,
  String? voucherTokenCID,
  EthereumAddress? sellerPayoutAddress,
  String? typedDataHash,
  String? offerHash,
  BigInt? price,
  BigInt? salt,
  int? endTimestamp,
  String? encodedOfferData,
}) async {
  var txParams = await buildEthSendTransactionRequest(
      getRPCUrlFromChainId(chainId),
      toAddress,
      walletAddress,
      functionSignatureHash,
      signatureData.hashedMsg,
      signatureData.signature,
      toAccount: toAccount,
      tokenId: tokenId,
      tokenURI: cid != null ? "ipfs://$cid" : null,
      voucherTokenURI:
          voucherTokenCID != null ? "ipfs://$voucherTokenCID" : null,
      enableRecovery: false,
      sellerPayoutAddress: sellerPayoutAddress,
      typedDataHash: typedDataHash,
      chainId: chainId,
      offerHash: offerHash,
      offerPrice: price,
      salt: salt,
      end: endTimestamp,
      encodedOfferData: encodedOfferData);

  final W3MService? w3mService = ref.read(w3mServiceProvider);
  await w3mService!.launchConnectedWallet();

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
  WidgetRef ref,
  String message,
  EthereumAddress walletAddress,
  Web3App wc,
  SessionData wcSession,
  WalletType walletType,
) async {
  final W3MService? w3mService = ref.read(w3mServiceProvider);
  await w3mService!.launchConnectedWallet();

  List<int> utf8CodeUnits = utf8.encode(message);
  String hexUtf8EncodedMessage =
      "0x" + utf8CodeUnits.map((e) => e.toRadixString(16)).join();

  String signature = await wc.request(
    topic: wcSession.topic,
    chainId: 'eip155:1',
    // chainId: w3mService.selectedChain?.chainId == null
    // ? 'eip155:1'
    // : 'eip155:${w3mService.selectedChain?.chainId}',
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

Future<Web3App> initWcClient(WidgetRef ref, BuildContext context) async {
  Web3App wcClient = await Web3App.createInstance(
    relayUrl: 'wss://relay.walletconnect.com',
    projectId: dotenv.env['WC_PROJECT_ID']!,
    metadata: const PairingMetadata(
      name: 'OwnerChip',
      description: 'OwnerChip - Connecting physical objects to the blockchain',
      url: 'https://www.ownerchip.com',
      icons: ['https://avatars.githubusercontent.com/u/116345848'],
    ),
  );
  //set walletconnect client provider
  ref.read(wcProvider.notifier).state = wcClient;

  //create Web3Modal service and set provider
  final W3MService w3mService = W3MService(web3App: wcClient);
  await w3mService.init();
  ref.read(w3mServiceProvider.notifier).state = w3mService;

  // Register event handlers
  final events = EIP155.events.values.toList();
  for (int chainId in chainConfig.keys) {
    for (final event in events) {
      wcClient.registerEventHandler(chainId: 'eip155:$chainId', event: event);
    }
  }

  wcClient.onSessionEvent.subscribe(wrapOnSessionEvent(ref));
  wcClient.onSessionConnect.subscribe(wrapOnSessionConnect(ref, context));
  wcClient.onSessionDelete.subscribe(wrapOnSessionDisconnect(ref));
  wcClient.onSessionExpire.subscribe(wrapOnSessionExpire(ref));

  return wcClient;
}

void Function(SessionConnect?) wrapOnSessionConnect(
    WidgetRef ref, BuildContext context) {
  return (SessionConnect? args) {
    Web3App? wc = ref.read(wcProvider);

    //set session and wallet type provider
    ref.read(wcSessionProvider.notifier).state = args?.session;
    ref.read(walletTypeProvider.notifier).state = walletConfig['walletConnect'];

    //store session and wallet type
    final storage = SharedPreferences.getInstance();
    final session = jsonEncode(args?.session);
    storage.then((value) => value.setString('session', session));
    storage.then((value) => value.setString(
        'walletType', jsonEncode(walletConfig['walletConnect']!.toJson())));

    authPopupBuilder(context, ref, wc!, 'WalletConnect');
  };
}

void Function(SessionDelete?) wrapOnSessionDisconnect(WidgetRef ref) {
  return (SessionDelete? args) {
    onSessionDisconnect(args, ref);
  };
}

void Function(SessionExpire?) wrapOnSessionExpire(WidgetRef ref) {
  return (SessionExpire? event) {
    if (event?.topic != null) {
      SessionDelete deleteArgs = SessionDelete(event!.topic);
      onSessionDisconnect(deleteArgs, ref);
    }
  };
}

void Function(SessionEvent?) wrapOnSessionEvent(WidgetRef ref) {
  return (SessionEvent? args) {};
}

void onSessionDisconnect(SessionDelete? args, WidgetRef ref) {
  //remove session and wallet type
  final storage = SharedPreferences.getInstance();
  storage.then((value) => value.remove('session'));
  storage.then((value) => value.remove('walletType'));
  storage.then((value) => value.remove('userSession'));

  ref.read(userSessionProvider.notifier).state = null;
  ref.read(wcSessionProvider.notifier).state = null;
  ref.read(walletTypeProvider.notifier).state = null;
  ref.read(userAddressProvider.notifier).state = zeroAddress;
}

void unsubscribeWcListeners(WidgetRef ref, BuildContext context) {
  Web3App? wcClient = ref.read(wcProvider);
  if (wcClient != null) {
    wcClient.onSessionConnect.unsubscribe(wrapOnSessionConnect(ref, context));
    wcClient.onSessionDelete.unsubscribe(wrapOnSessionDisconnect(ref));
    wcClient.onSessionEvent.unsubscribe(wrapOnSessionEvent(ref));
    wcClient.onSessionExpire.unsubscribe(wrapOnSessionExpire(ref));
  }
}

Future<void> onCardPress(WidgetRef ref, BuildContext context, String pin,
    bool removeWalletPopup) async {
  try {
    if (!await checkInternetConnection()) {
      throw "No internet connection";
    }
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(returnSnackBarWidget(
        context.loc.errorHeadingSnackBar,
        context.loc.errorNoInternetConnection,
        'error'));
    return;
  }
  await authenticateCard(ref, context, pin);
  ScaffoldMessenger.of(context).showSnackBar(returnSnackBarWidget(
      context.loc.successHeadingSnackbar,
      context.loc.successCardLogin,
      'success'));
  //navigate to previous screen
  Navigator.pop(context);
  if (removeWalletPopup) {
    //remove wallet popup
    Navigator.pop(context);
  }
}
