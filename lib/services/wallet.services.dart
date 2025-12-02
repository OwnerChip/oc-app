//package imports
import 'dart:convert';
import 'dart:io';

import 'package:convert/convert.dart';
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

//misc imports
import 'package:ownerchip_whitelabel/domain/classDefinition.dart';
import 'package:ownerchip_whitelabel/domain/eip155.dart';
import 'package:ownerchip_whitelabel/screens/PinScreen.dart';
import 'package:ownerchip_whitelabel/services/backend/metaTx/backendMetaTx.dart';
import 'package:ownerchip_whitelabel/services/gasstation.services.dart';
import 'package:ownerchip_whitelabel/services/nfc.services.dart';
import 'package:ownerchip_whitelabel/services/providers/chipData.dart';
import 'package:ownerchip_whitelabel/services/providers/collectionsData.dart';
import 'package:ownerchip_whitelabel/services/providers/userData.dart';
import 'package:ownerchip_whitelabel/services/providers/walletconnectData.dart';
import 'package:ownerchip_whitelabel/services/signature.services.dart';

//service imports
import 'package:ownerchip_whitelabel/services/web3.services.dart';
import 'package:ownerchip_whitelabel/utils/localization.helper.dart';
import 'package:ownerchip_whitelabel/utils/logger.dart';
import 'package:ownerchip_whitelabel/utils/navigationArguments.dart';
import 'package:ownerchip_whitelabel/utils/utils.dart';
import 'package:ownerchip_whitelabel/utils/web3_utils.dart';
import 'package:ownerchip_whitelabel/widgets/popups/returnSnackBarWidget.dart';
import 'package:reown_appkit/reown_appkit.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:web3auth_flutter/enums.dart';
import 'package:web3auth_flutter/input.dart';
import 'package:web3auth_flutter/web3auth_flutter.dart';
import 'package:web3dart/src/utils/rlp.dart' as rlp;

import 'providers/websocket/websocketNotifier.dart';

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
  ReownAppKitModal? wc,
  //Note: wc and wcSession are null if OwnerCard is used for tx
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
  Future<MsgSignature?> Function(String hash)? getCardSignature,
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
    token: token,
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
                    return (await makeCardSignature(
                        ref, context, hash, toggleLoading, pin));
                  })) as MsgSignature;

      signature = msgSignatureToHex(cardSignature);
    } else if (walletType.type == EWalletType.certificateCard) {
      // add this delay, because if you scan the card immediately after scanning the chip, it will cause an error
      await Future.delayed(const Duration(seconds: 3));
      final sig =
          await getCardSignature!(await getGaslessTxHash(request, toAddress));
      signature = msgSignatureToHex(sig!);
    } else if (walletType.type == EWalletType.walletConnect) {
      final ReownAppKitModal? w3mService = ref.read(w3mServiceProvider);

      await preventRepeatedNFCScan(() async {
        w3mService!.launchConnectedWallet();

        toggleLoading();

        signature = await wc!
            .request(
          topic: wc.session?.topic,
          chainId: w3mService.selectedChain?.chainId ?? 'eip155:$chainId',
          request: SessionRequestParams(
            method: 'eth_signTypedData_v4',
            params: [walletAddress.toString(), json.encode(typedData)],
          ),
        )
            .onError((error, stackTrace) {
          talker.error(
            'error signing gasless tx $error',
            stackTrace,
          );
          throw error!;
        });
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
        rethrow;
      }
    }

    if (signature.isEmpty) {
      throw Exception('Failed to sign message');
    }

    bool verified = false;

    try {
      verified = await verifyGaslessTransaction(
        request,
        chainId: chainId,
        signature: signature,
      );
    } catch (e) {
      talker
          .error('Failed to verify gasless transaction: $e proceeding anyway');
      verified = true;
    }

    if (!verified) {
      throw Exception('Failed to verify gasless transaction');
    }

    String txnHash = await BackendMetaTx.sendGaslessRequest(
        toAddress, signature, metaTxAgreementId, request);
    return txnHash;
  } catch (e) {
    print(e);
    rethrow;
  }
}

Future<EtherAmount> _getMaxPriorityFeePerGas() {
  // We may want to compute this more accurately in the future,
  // using the formula "check if the base fee is correct".
  // See: https://eips.ethereum.org/EIPS/eip-1559
  return Future.value(EtherAmount.inWei(BigInt.from(1000000000)));
}

// Max Fee = (2 * Base Fee) + Max Priority Fee
Future<EtherAmount> _getMaxFeePerGas(
  Web3Client client,
  BigInt maxPriorityFeePerGas,
) async {
  final blockInformation = await client.getBlockInformation();
  final baseFeePerGas = blockInformation.baseFeePerGas;

  if (baseFeePerGas == null) {
    return EtherAmount.zero();
  }

  return EtherAmount.inWei(
    baseFeePerGas.getInWei * BigInt.from(2) + maxPriorityFeePerGas,
  );
}

Future<Transaction> _fillMissingData({
  required Transaction transaction,
  int? chainId,
  bool loadChainIdFromNetwork = false,
  Web3Client? client,
}) async {
  if (loadChainIdFromNetwork && chainId != null) {
    throw ArgumentError(
      "You can't specify loadChainIdFromNetwork and specify a custom chain id!",
    );
  }

  final sender = transaction.from!;
  var gasPrice = transaction.gasPrice;

  if (client == null &&
      (transaction.nonce == null ||
          transaction.maxGas == null ||
          loadChainIdFromNetwork ||
          (!transaction.isEIP1559 && gasPrice == null))) {
    throw ArgumentError('Client is required to perform network actions');
  }

  if (!transaction.isEIP1559 && gasPrice == null) {
    gasPrice = await client!.getGasPrice();
  }

  var maxFeePerGas = transaction.maxFeePerGas;
  var maxPriorityFeePerGas = transaction.maxPriorityFeePerGas;

  if (transaction.isEIP1559) {
    maxPriorityFeePerGas ??= await _getMaxPriorityFeePerGas();
    maxFeePerGas ??= await _getMaxFeePerGas(
      client!,
      maxPriorityFeePerGas.getInWei,
    );
  }

  return transaction.copyWith(
    value: transaction.value ?? EtherAmount.zero(),
    maxGas: transaction.maxGas ??
        await client!
            .estimateGas(
              sender: sender,
              to: transaction.to,
              data: transaction.data,
              value: transaction.value,
              gasPrice: gasPrice,
              maxPriorityFeePerGas: maxPriorityFeePerGas,
              maxFeePerGas: maxFeePerGas,
            )
            .then((bigInt) => bigInt.toInt()),
    from: sender,
    data: transaction.data ?? Uint8List(0),
    gasPrice: gasPrice,
    nonce: transaction.nonce ??
        await client!
            .getTransactionCount(sender, atBlock: const BlockNum.pending()),
    maxPriorityFeePerGas: maxPriorityFeePerGas,
    maxFeePerGas: maxFeePerGas,
  );
}

List<dynamic> _encodeToRlp(
  Transaction transaction,
  MsgSignature? signature, {
  required int chainId,
}) {
  final list = [
    transaction.nonce,
    transaction.gasPrice?.getInWei,
    transaction.maxGas,
    transaction.to?.addressBytes ?? Uint8List(0),
    // Ensure addressBytes is not null
    transaction.value?.getInWei,
    transaction.data ?? Uint8List(0),
    // Ensure data is not null
  ];

  if (signature != null) {
    list
      ..add(signature.v)
      ..add(signature.r)
      ..add(signature.s);
  }

  return list;
}
// This code creates a normal transaction.
//It calls the buildEthSendTransactionRequest function to get the transaction parameters,
//and then sends a custom request to the WalletConnect client to send the transaction.
//It then returns the txnHash.

Future<String> makeAndSendNormalTx(
  BuildContext context,
  WidgetRef ref,
  String functionSignatureHash,
  int chainId,
  EthereumAddress toAddress,
  SignatureData signatureData,
  EthereumAddress walletAddress,
  ReownAppKitModal wc,
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
  BlockchainToken? token,
  Future<MsgSignature?> Function(String hash)? getCardSignature,
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
    token: token,
  );

  late String txnHash;

  final walletType = ref.read(walletTypeProvider);
  if (walletType == null) {
    throw Exception('Wallet type not found');
  }

  if ([
    EWalletType.ownerCard,
    EWalletType.certificateCard,
    EWalletType.web3auth,
  ].contains(walletType.type)) {
    final client = getWeb3Client(chainConfig[chainId]!.rpcUrl);
    final params = txParams[0];

    final transaction = await buildTransactionObject(
      walletAddress: walletAddress,
      toAddress: toAddress,
      params: params,
      chainId: chainId,
      client: client,
    );

    final encoded = _encodeToRlp(
      transaction,
      MsgSignature(
        BigInt.zero,
        BigInt.zero,
        chainId,
      ),
      chainId: chainId,
    );

    final rawTx = Uint8List.fromList(rlp.encode(encoded));
    final hash = keccak256(rawTx);

    final MsgSignature signature;

    if (walletType.type == EWalletType.ownerCard) {
      final sig =
          // ignore: use_build_context_synchronously
          await Navigator.pushNamed(context, PinScreen.routeName,
              arguments: PinScreenArguments(
                  activeFeature: PinScreenActiveFeature.verifyPinTx,
                  callback: (String pin) async {
                    return await makeCardSignature(
                      ref,
                      context,
                      hash,
                      () {},
                      pin,
                    );
                  })) as MsgSignature?;

      if (sig == null) {
        throw Exception('Failed to sign message');
      }

      signature = MsgSignature(sig.r, sig.s, sig.v - 27 + (chainId * 2 + 35));
    } else if (walletType.type == EWalletType.certificateCard) {
      // add this delay, because if you scan the card immediately after scanning the chip, it will cause an error
      await Future.delayed(const Duration(seconds: 3));
      final sig = await getCardSignature!(
        hex.encode(hash),
      );

      signature = MsgSignature(sig!.r, sig.s, sig.v - 27 + (chainId * 2 + 35));
    } else {
      final priv = await Web3AuthFlutter.getPrivKey();

      final Credentials creds = EthPrivateKey.fromHex(priv);

      signature = creds.signToEcSignature(
        rawTx,
        chainId: chainId,
      );
    }

    final signedTx = rlp.encode(
      _encodeToRlp(
        transaction,
        signature,
        chainId: chainId,
      ),
    );

    txnHash = await client.sendRawTransaction(
      uint8ListFromList(signedTx),
    );

    talker.log('Transaction sent: $txnHash');
  } else {
    final ReownAppKitModal? w3mService = ref.read(w3mServiceProvider);

    late Future<dynamic> txnFuture;

    await preventRepeatedNFCScan(() async {
      // await Future.delayed(const Duration(seconds: 3));
      await wcSwitchToChainConditionally(w3mService, chainId).catchError((e) {
        talker.error('Failed to switch to chain: $e');
      });
      await Future.delayed(const Duration(seconds: 3));

      txnFuture = wc.request(
        topic: wc.session?.topic!,
        chainId: 'eip155:$chainId',
        request: SessionRequestParams(
          method: 'eth_sendTransaction',
          params: txParams,
        ),
      );

      w3mService!.launchConnectedWallet();
    });

    txnHash = await txnFuture;
  }

  return txnHash;
}

Future<Transaction> buildTransactionObject({
  required EthereumAddress walletAddress,
  required EthereumAddress toAddress,
  required params,
  required int chainId,
  required Web3Client client,
}) async {
  return await _fillMissingData(
    transaction: Transaction(
      from: walletAddress,
      to: toAddress,
      data: params['data'] != null ? hexToBytes(params['data']) : Uint8List(0),
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
          : EtherAmount.zero(),
      nonce: params['nonce'] != null
          ? int.parse(params['nonce'].toString().substring(2), radix: 16)
          : null,
    ),
    chainId: chainId,
    client: client,
  );
}

Future<void> wcSwitchToChainConditionally(
    ReownAppKitModal? w3mService, int chainId) async {
  final wallet = w3mService?.selectedWallet;

  if (wallet != null &&
      !wallet.listing.name.toLowerCase().contains("metamask")) {
    return;
  }

  final selectedChain = w3mService?.selectedChain;

  if (selectedChain?.chainId.replaceAll("eip155:", "") == chainId.toString()) {
    // Chain is already selected
    return;
  }

  await (() async {
    final chain = chainConfig[chainId]!;

    w3mService!.launchConnectedWallet();

    await w3mService.requestSwitchToChain(
      ReownAppKitModalNetworkInfo(
        name: chain.networkName,
        chainId: "$chainId",
        currency: chain.nativeTokenSymbol,
        rpcUrl: chain.rpcUrl,
        explorerUrl: chain.blockchainExplorerUrl,
      ),
    );

    // Wait for the network to change
    // so that we can redirect the user to the wallet app again
    // because <launchConnectedWallet> does not work after switching the chain
    // (because the application is still in the background)

    int tries = 0;

    await Future.delayed(const Duration(seconds: 3));
    while (!isValidNamespacesChainId(
      chainId: "eip155:$chainId",
      namespaces: w3mService.appKit
              ?.getActiveSessions()[w3mService.session!.topic!]
              ?.namespaces ??
          {} as dynamic,
    )) {
      await Future.delayed(const Duration(seconds: 5));
      if (tries++ > 10) {
        break;
      }
    }
  })();

  await Future.delayed(const Duration(seconds: 5));
}

//personal sign
Future<String> sendPersonalSignRequest(
  WidgetRef ref,
  String message,
  EthereumAddress walletAddress,
  WalletType walletType, {
  bool siweMessage = false,
  int chainId = 1,
}) async {
  List<int> utf8CodeUnits = utf8.encode(message);
  String hexUtf8EncodedMessage =
      "0x${utf8CodeUnits.map((e) => e.toRadixString(16)).join()}";

  final requestParams = [
    siweMessage ? message : hexUtf8EncodedMessage,
    walletAddress.toString()
  ];

  if (walletType.type == EWalletType.web3auth) {
    Future<String> signWithPrivateKey() async {
      final priv = await Web3AuthFlutter.getPrivKey();
      final credentials = EthPrivateKey.fromHex(priv);

      final res = credentials.signPersonalMessageToUint8List(
        Uint8List.fromList(utf8CodeUnits),
        chainId: chainId,
      );

      return '0x${hex.encode(res)}';
    }

    try {
      return await signWithPrivateKey();
    } catch (e, st) {
      Sentry.captureException(e, stackTrace: st);

      throw Exception('Failed to sign message with Web3Auth');
    }
  } else {
    final ReownAppKitModal? w3mService = ref.read(w3mServiceProvider);
    w3mService!.launchConnectedWallet();

    try {
      String signature = await w3mService.request(
        topic: w3mService.session!.topic!,
        chainId: w3mService.selectedChain?.chainId ?? "eip155:$chainId",
        request: SessionRequestParams(
          method: 'personal_sign',
          params: requestParams,
        ),
      );
      return signature;
    } catch (e, st) {
      Sentry.captureException(e, stackTrace: st);
      talker.error('Failed to sign message with WalletConnect $e', st);
      rethrow;
    }
  }
}

Future<String> getGaslessTxHash(request, collectionId) async {
  String hash =
      await BackendMetaTx.getEthSignTypedDataSignature(collectionId, request);

  return hash;
}

Future<ReownAppKitModal> initWcClient(
    WidgetRef ref, BuildContext context) async {
  final appkit = ReownAppKit(
    core: ReownCore(
      projectId: dotenv.env['WC_PROJECT_ID']!,
      relayUrl: ReownConstants.DEFAULT_RELAY_URL,
      pushUrl: ReownConstants.DEFAULT_PUSH_URL,
      logLevel: LogLevel.all
    ),
    metadata: PairingMetadata(
      name: 'OwnerChip',
      description: 'OwnerChip - Connecting physical objects to the blockchain',
      url: 'https://www.ownerchip.com',
      icons: ['https://avatars.githubusercontent.com/u/116345848'],
      redirect: Redirect(
        native: '${dotenv.get("BITRISEIO_PACKAGE_NAME")}://',
        universal: 'https://www.ownerchip.com',
      ),
    ),
  );

  //create Web3Modal service and set provider
  final ReownAppKitModal w3mService =
      ReownAppKitModal(context: context, appKit: appkit);

  w3mService.onSessionEventEvent.subscribe(wrapOnSessionEvent(ref));
  w3mService.onModalConnect.subscribe(wrapOnSessionConnect(ref, context));
  w3mService.onModalDisconnect.subscribe(wrapOnSessionDisconnect(ref));
  w3mService.onSessionExpireEvent.subscribe(wrapOnSessionExpire(ref));

  await w3mService.init();

  ref.read(w3mServiceProvider.notifier).state = w3mService;
  ref.read(wcSessionProvider.notifier).state = w3mService.session;

  return w3mService;
}

void Function(ModalConnect?) wrapOnSessionConnect(
    WidgetRef ref, BuildContext context) {
  return (ModalConnect? args) {
    //set session and wallet type provider
    ref.read(wcSessionProvider.notifier).state = args?.session;
    ref.read(walletTypeProvider.notifier).state =
        walletConfig[EWalletType.walletConnect];

    //store session and wallet type
    SharedPreferences.getInstance().then((value) {
      value.setString(
        'walletType',
        jsonEncode(
          walletConfig[EWalletType.walletConnect]!.toJson(),
        ),
      );
    });
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
  return (SessionEvent? args) {
    talker.log('Session event: ${args?.chainId}');
  };
}

void onSessionDisconnect(ModalDisconnect? args, WidgetRef ref) {
  //remove session and wallet type
  print("OnSessionDisconnect");
  final storage = SharedPreferences.getInstance();
  storage.then((value) => value.remove('walletType'));
  storage.then((value) => value.remove('userSession'));

  ref.read(userSessionProvider.notifier).state = null;
  ref.read(websocketProvider.notifier).disconnect();
  ref.read(wcSessionProvider.notifier).state = null;
  ref.read(walletTypeProvider.notifier).state = null;
  ref.read(userAddressProvider.notifier).state = zeroAddress;
}

void unsubscribeWcListeners(WidgetRef ref, BuildContext context) {
  ReownAppKitModal? w3mService = ref.read(w3mServiceProvider);
  if (w3mService != null) {
    w3mService.onModalConnect.unsubscribe(wrapOnSessionConnect(ref, context));
    w3mService.onModalDisconnect.unsubscribe(wrapOnSessionDisconnect(ref));
    w3mService.onSessionEventEvent.unsubscribe(wrapOnSessionEvent(ref));
    w3mService.onSessionExpireEvent.unsubscribe(wrapOnSessionExpire(ref));
  }
}

Future<void> onCertificateCardLogin(
  WidgetRef ref,
  BuildContext context,
  bool removeWalletPopup,
) async {
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

  await authenticateCard(
    ref,
    context,
    pin: null,
  );
  final walletType = ref.read(walletTypeProvider);
  if (walletType != null) {
    ScaffoldMessenger.of(context).showSnackBar(returnSnackBarWidget(
        context.loc.successHeadingSnackbar,
        context.loc.certificateCardLoginSuccess,
        'success'));
  }

  //navigate to previous screen
  Navigator.pop(context);
  if (removeWalletPopup) {
    //remove wallet popup
    Navigator.pop(context);
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
  await authenticateCard(
    ref,
    context,
    pin: pin,
  );
  final type = ref.read(walletTypeProvider);
  if (type != null) {
    ScaffoldMessenger.of(context).showSnackBar(returnSnackBarWidget(
        context.loc.successHeadingSnackbar,
        context.loc.successCardLogin,
        'success'));
  }

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
        'torusapp://org.torusresearch.${dotenv.get("BITRISEIO_PACKAGE_NAME")}');
  } else if (Platform.isIOS) {
    redirectUrl = Uri.parse('${dotenv.get("BITRISEIO_PACKAGE_NAME")}://auth');
  } else {
    throw UnKnownException('Unknown platform');
  }

  await Web3AuthFlutter.init(
    Web3AuthOptions(
      clientId: dotenv.get('WEB3_AUTH_CLIENT_ID'),
      //     "BCGuB4TOrWXvmJKbZB2V1u0R-iyo1jJxsVKwTheUBSyQ850lquUtJO6YHALOtY6cbd_ZbmCIInHbrwlTy2wxYRI",
      network: Network.sapphire_mainnet,
      // buildEnv: BuildEnv.production,
      redirectUrl: redirectUrl,
      whiteLabel: WhiteLabelData(
        mode: ThemeModes.dark,
        defaultLanguage: Language.en,
      ),
    ),
  );

  await Web3AuthFlutter.initialize().catchError((e) {
    talker.error('Failed to initialize Web3Auth: $e');
  });

  _initializedWeb3Auth = true;
}
