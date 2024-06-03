//package imports
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:eth_sig_util/eth_sig_util.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ownerchip_whitelabel/config/chains.dart';
import 'package:ownerchip_whitelabel/config/constants.dart';
import 'package:ownerchip_whitelabel/config/wallets.dart';
import 'package:ownerchip_whitelabel/domain/blockchain_token.dart';
import 'package:ownerchip_whitelabel/screens/PinScreen.dart';
import 'package:ownerchip_whitelabel/services/providers/userData.dart';
import 'package:ownerchip_whitelabel/services/nfc.services.dart';
import 'package:ownerchip_whitelabel/services/providers/web3auth/web3authNotifierData.dart';
import 'package:ownerchip_whitelabel/services/signature.services.dart';
import 'package:ownerchip_whitelabel/utils/localization.helper.dart';
import 'package:ownerchip_whitelabel/utils/navigationArguments.dart';
import 'package:ownerchip_whitelabel/utils/web3authUtils.dart';
import 'package:ownerchip_whitelabel/widgets/popups/returnSnackBarWidget.dart';
import 'package:ownerchip_whitelabel/services/providers/walletconnectData.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:web3modal_flutter/web3modal_flutter.dart';
import 'package:web3auth_flutter/enums.dart';
import 'package:web3auth_flutter/input.dart';
import 'package:web3auth_flutter/web3auth_flutter.dart';
import 'package:convert/convert.dart';

//misc imports
import 'package:ownerchip_whitelabel/domain/classDefinition.dart';
import 'package:ownerchip_whitelabel/utils/utils.dart';
import 'package:ownerchip_whitelabel/domain/eip155.dart';

//service imports
import 'package:ownerchip_whitelabel/services/web3.services.dart';
import 'package:ownerchip_whitelabel/services/backend.services.dart';
import 'package:ownerchip_whitelabel/services/gasstation.services.dart';

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
  W3MSession? wcSession,
  String metaTxAgreementId,
  WalletType walletType, {
  EthereumAddress? controllerContractId,
  String? typedDataHash,
  EthereumAddress? toAccount,
  String? twinTokenMetadataCID,
  String? voucherTokenMetadataCID,
  BigInt? tokenId,
  bool? enableRecovery,
  EthereumAddress? sellerPayoutAddress,
  BigInt? salt,
  int? endTimestamp,
  BigInt? price,
  String? encodedOfferData,
  required Function toggleLoading,
  String? offerHash,
  BigInt? amount,
  BlockchainToken? token,
  BigInt? gasAmount,
}) async {
  final List<Map<String, dynamic>> gaslessTxParams = await makeGaslessParams(
    functionSignatureHash: functionSignatureHash,
    chainRpcUrl: getRPCUrlFromChainId(chainId),
    chainId: chainId,
    randomValueHash: signatureData.hashedMsg,
    signature: signatureData.signature,
    from: walletAddress,
    to: controllerContractId ?? toAddress,
    //if a controller contract addr is given, the receiver is the controller address, not to address. toAddress is only sent to backend for gas station purposes
    toAccount: toAccount,
    tokenURI:
        twinTokenMetadataCID != null ? "ipfs://$twinTokenMetadataCID" : null,
    voucherTokenURI: voucherTokenMetadataCID != null
        ? "ipfs://$voucherTokenMetadataCID"
        : null,
    tokenId: tokenId,
    enableRecovery: enableRecovery,
    sellerPayoutAddress: sellerPayoutAddress,
    salt: salt,
    endTimestamp: endTimestamp,
    price: price,
    encodedOfferData: encodedOfferData,
    typedDataHash: typedDataHash,
    offerHash: offerHash,
    amount: amount,
    gas: gasAmount,
  );
  final Map<String, dynamic> typedData = gaslessTxParams[0];
  final Map<String, dynamic> request = gaslessTxParams[1];

  try {
    String signature = "";
    if (walletType.type == EWalletType.ownerCard) {
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
    } else if (walletType.type == EWalletType.walletConnect) {
      final W3MService? w3mService = ref.read(w3mServiceProvider);
      w3mService!.launchConnectedWallet();

      toggleLoading();

      // check if the user allowed the forwarder contract to spend their tokens
      if (chainConfig[chainId]!.forwarderContract != null) {
        await _wcCheckERC20Allowance(
          token,
          walletAddress,
          chainId,
          wc,
          wcSession,
          w3mService,
        );
      }

      // requqest user to allow the forwarder contract to spend their tokens
      signature = await wc!
          .request(
        topic: wcSession!.topic!,
        chainId: 'eip155:$chainId',
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
    } else {
      try {
        final priv = await Web3AuthFlutter.getPrivKey();
        signature = EthSigUtil.signTypedData(
          privateKey: priv,
          jsonData: json.encode(typedData),
          version: TypedDataVersion.V4,
        );
      } catch (e, st) {
        Sentry.captureException(e, stackTrace: st);
        debugPrint(e.toString());
        debugPrintStack(stackTrace: st);
        throw Exception('Failed to sign message with Web3Auth');
      }
    }

    if (signature.isEmpty) {
      throw Exception('Failed to sign message');
    }

    String txnHash = await sendGaslessRequest(
        toAddress, signature, metaTxAgreementId, request);
    return txnHash;
  } catch (e) {
    print(e);
    rethrow;
  }
}

// TODO: should be a gasless transaction as well
Future<void> _wcCheckERC20Allowance(
    BlockchainToken? token,
    EthereumAddress walletAddress,
    int chainId,
    Web3App? wc,
    W3MSession? wcSession,
    W3MService w3mService) async {
  final contract = await token!.getDeployedContract();
  final function = contract.function('allowance');
  ;

  final client = getWeb3Client(chainConfig[chainId]!.rpcUrl);
  final res = await client.call(
    contract: contract,
    function: function,
    params: [
      walletAddress,
      EthereumAddress.fromHex(chainConfig[chainId]!.forwarderContract!),
    ],
  );

  if (res.first == BigInt.zero) {
    final function = contract.function('approve');
    final data = function.encodeCall([
      EthereumAddress.fromHex(chainConfig[chainId]!.forwarderContract!),
      BigInt.parse(
          '115792089237316195423570985008687907853269984665640564039457584007913129639935')
    ]);

    final res = await wc!.request(
      topic: wcSession!.topic!,
      chainId: 'eip155:$chainId',
      request: SessionRequestParams(
        method: 'eth_sendTransaction',
        params: [
          {
            'from': walletAddress.toString(),
            'to': token.contractAddress.toString(),
            'data': "0x${hex.encode(data)}",
          }
        ],
      ),
    );
    print('Transaction sent: $res');

    w3mService.launchConnectedWallet();
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
  W3MSession? wcSession,
  WalletType walletType, {
  EthereumAddress? toAccount,
  BigInt? tokenId,
  String? twinTokenMetadataCID,
  String? voucherTokenMetadataCID,
  EthereumAddress? sellerPayoutAddress,
  String? typedDataHash,
  String? offerHash,
  BigInt? price,
  BigInt? salt,
  int? endTimestamp,
  String? encodedOfferData,
  BigInt? amount,
  BigInt? gasAmount,
  BigInt? gasPrice,
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
    tokenURI:
        twinTokenMetadataCID != null ? "ipfs://$twinTokenMetadataCID" : null,
    voucherTokenURI: voucherTokenMetadataCID != null
        ? "ipfs://$voucherTokenMetadataCID"
        : null,
    enableRecovery: false,
    sellerPayoutAddress: sellerPayoutAddress,
    typedDataHash: typedDataHash,
    chainId: chainId,
    offerHash: offerHash,
    offerPrice: price,
    salt: salt,
    end: endTimestamp,
    encodedOfferData: encodedOfferData,
    amount: amount,
    gasPrice: gasPrice,
    gasAmount: gasAmount,
  );

  late String txnHash;

  final walletType = ref.read(walletTypeProvider);
  if (walletType == null) {
    throw Exception('Wallet type not found');
  }

  if (walletType.type == EWalletType.web3auth) {
    final client = getWeb3Client(chainConfig[chainId]!.rpcUrl);
    final credentials =
        EthPrivateKey.fromHex(await Web3AuthFlutter.getPrivKey());
    final params = txParams[0];

    Uint8List hexToBytes(String hexString) {
      // Ensure the hex string does not contain the '0x' prefix
      if (hexString.startsWith('0x')) {
        hexString = hexString.substring(2);
      }
      return Uint8List.fromList(hex.decode(hexString));
    }

    final transaction = Transaction(
      from: walletAddress,
      to: toAddress,
      data: params['data'] != null ? hexToBytes(params['data']) : null,
      gasPrice: params['gasPrice'] != null
          ? EtherAmount.inWei(BigInt.parse(
              params['gasPrice'].toString().substring(2),
              radix: 16,
            ))
          : null,
      maxGas: params["gas"] != null
          ? BigInt.parse(
              params['gas'].toString().substring(
                    2,
                  ),
              radix: 16,
            ).toInt()
          : null,
      value: params['value'] != null
          ? EtherAmount.inWei(
              BigInt.parse(
                params['value'].toString().substring(2),
                radix: 16,
              ),
            )
          : null,
    );
    txnHash = await client.sendTransaction(
      credentials,
      transaction,
      chainId: chainId,
    );
  } else {
    final W3MService? w3mService = ref.read(w3mServiceProvider);
    w3mService!.launchConnectedWallet();

    txnHash = await wc.request(
      topic: wcSession!.topic!,
      chainId: 'eip155:$chainId',
      request: SessionRequestParams(
        method: 'eth_sendTransaction',
        params: txParams,
      ),
    );
  }

  return txnHash;
}

//personal sign
Future<String> sendPersonalSignRequest(
  WidgetRef ref,
  String message,
  EthereumAddress walletAddress,
  W3MSession? wcSession,
  Web3AuthNotifierData web3AuthData,
  WalletType walletType,
) async {
  List<int> utf8CodeUnits = utf8.encode(message);
  String hexUtf8EncodedMessage =
      "0x" + utf8CodeUnits.map((e) => e.toRadixString(16)).join();

  final requestParams = [hexUtf8EncodedMessage, walletAddress.toString()];

  if (walletType.type == EWalletType.web3auth) {
    // final cfg = ChainConfig(
    //   chainId: '11155111',
    //   rpcTarget:
    //       "https://eth-sepolia.g.alchemy.com/v2/${dotenv.env['ALCHEMY_API_KEY_ETH']}",
    // );
    // TODO: Web3Auth doesn't open the correct network
    // it always opens eth mainnet
    final cfg = ChainConfig(
      chainId: 'eip155:1',
      rpcTarget: chainConfig[1]!.rpcUrl,
    );

    Future<String> signWithPrivateKey() async {
      final priv = await Web3AuthFlutter.getPrivKey();
      final credentials = EthPrivateKey.fromHex(priv);
      final res = credentials.signPersonalMessageToUint8List(
          Uint8List.fromList(utf8CodeUnits),
          chainId: 1);

      return '0x${hex.encode(res)}';
    }

    try {
      return await signWithPrivateKey();
    } catch (e, st) {
      Sentry.captureException(e, stackTrace: st);

      throw Exception('Failed to sign message with Web3Auth');
    }
  } else {
    final W3MService? w3mService = ref.read(w3mServiceProvider);
    w3mService!.launchConnectedWallet();

    try {
      String signature = await w3mService.request(
        topic: wcSession!.topic!,
        chainId: 'eip155:1',
        // chainId: w3mService.selectedChain?.chainId == null
        // ? 'eip155:1'
        // : 'eip155:${w3mService.selectedChain?.chainId}',
        request: SessionRequestParams(
          method: 'personal_sign',
          params: requestParams,
        ),
      );
      return signature;
    } catch (e) {
      Sentry.captureException(e);
      print(e);
      rethrow;
    }
  }
}

Future<String> getGaslessTxHash(request, collectionId) async {
  String hash = await getEthSignTypedDataSignature(collectionId, request);

  return hash;
}

Future<Web3App> initWcClient(WidgetRef ref, BuildContext context) async {
  //create Web3Modal service and set provider
  final W3MService w3mService = W3MService(
    projectId: dotenv.env['WC_PROJECT_ID']!,
    metadata: PairingMetadata(
      name: 'OwnerChip',
      description: 'OwnerChip - Connecting physical objects to the blockchain',
      url: 'https://www.ownerchip.com',
      icons: ['https://avatars.githubusercontent.com/u/116345848'],
      redirect: Redirect(
        native: '${dotenv.get("APP_ID")}://',
        universal: 'https://www.ownerchip.com',
      ),
    ),
  );

  w3mService.onSessionEventEvent.subscribe(wrapOnSessionEvent(ref));
  w3mService.onModalConnect.subscribe(wrapOnSessionConnect(ref, context));
  w3mService.onModalDisconnect.subscribe(wrapOnSessionDisconnect(ref));
  w3mService.onSessionExpireEvent.subscribe(wrapOnSessionExpire(ref));

  await w3mService.init();
  ref.read(w3mServiceProvider.notifier).state = w3mService;

  final Web3App wcClient = w3mService.web3App! as Web3App;
  //set walletconnect client provider
  ref.read(wcProvider.notifier).state = wcClient;

  // Register event handlers
  final events = EIP155.events.values.toList();
  for (int chainId in chainConfig.keys) {
    for (final event in events) {
      wcClient.registerEventHandler(chainId: 'eip155:$chainId', event: event);
    }
  }

  return wcClient;
}

void Function(ModalConnect?) wrapOnSessionConnect(
    WidgetRef ref, BuildContext context) {
  return (ModalConnect? args) {
    Web3App? wc = ref.read(wcProvider);

    //set session and wallet type provider
    ref.read(wcSessionProvider.notifier).state = args?.session;
    ref.read(walletTypeProvider.notifier).state =
        walletConfig[EWalletType.walletConnect];

    //store session and wallet type
    final storage = SharedPreferences.getInstance();
    final session = jsonEncode(args?.session.toMap());
    storage.then((value) => value.setString('session', session));
    storage.then((value) => value.setString('walletType',
        jsonEncode(walletConfig[EWalletType.walletConnect]!.toJson())));
  };
}

void Function(ModalDisconnect?) wrapOnSessionDisconnect(WidgetRef ref) {
  return (ModalDisconnect? args) {
    onSessionDisconnect(args, ref);
  };
}

void Function(SessionExpire?) wrapOnSessionExpire(WidgetRef ref) {
  return (SessionExpire? event) {
    if (event?.topic != null) {
      onSessionDisconnect(
        ModalDisconnect(
          topic: event!.topic,
        ),
        ref,
      );
    }
  };
}

void Function(SessionEvent?) wrapOnSessionEvent(WidgetRef ref) {
  return (SessionEvent? args) {};
}

void onSessionDisconnect(ModalDisconnect? args, WidgetRef ref) {
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
  W3MService? w3mService = ref.read(w3mServiceProvider);
  if (wcClient != null) {
    w3mService?.onModalConnect.unsubscribe(wrapOnSessionConnect(ref, context));
    w3mService?.onModalDisconnect.unsubscribe(wrapOnSessionDisconnect(ref));
    w3mService?.onSessionEventEvent.unsubscribe(wrapOnSessionEvent(ref));
    w3mService?.onSessionExpireEvent.unsubscribe(wrapOnSessionExpire(ref));
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

bool _initializedWeb3Auth = false;

Future<void> setupWeb3Auth() async {
  if (_initializedWeb3Auth) return;

  Uri redirectUrl;
  if (Platform.isAndroid) {
    redirectUrl = Uri.parse(
        'torusapp://org.torusresearch.${dotenv.get("BITRISEIO_PACKAGE_NAME")}/auth');
  } else if (Platform.isIOS) {
    redirectUrl = Uri.parse('${dotenv.get("BITRISEIO_PACKAGE_NAME")}://auth');
  } else {
    throw UnKnownException('Unknown platform');
  }

  await Web3AuthFlutter.init(
    Web3AuthOptions(
      clientId: dotenv.get('WEB3_AUTH_CLIENT_ID'),
      network: dotenv.get('IS_INTERNAL') == 'true'
          ? Network.sapphire_devnet
          : Network.sapphire_mainnet,
      redirectUrl: redirectUrl,
      whiteLabel: WhiteLabelData(
        mode: ThemeModes.dark,
        defaultLanguage: Language.en,
      ),
    ),
  );

  await Web3AuthFlutter.initialize();

  _initializedWeb3Auth = true;
}
