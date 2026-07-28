//package imports
import 'dart:convert';

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
import 'package:ownerchip_whitelabel/services/nfc.services.dart';
import 'package:ownerchip_whitelabel/services/providers/chipData.dart';
import 'package:ownerchip_whitelabel/services/providers/collectionsData.dart';
import 'package:ownerchip_whitelabel/services/providers/userData.dart';
import 'package:ownerchip_whitelabel/services/providers/walletconnectData.dart';

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
import 'package:web3dart/src/utils/rlp.dart' as rlp;

import 'providers/websocket/websocketNotifier.dart';

Uri convertToWcLink({
  required String appLink,
  required String wcUri,
  bool isDeepLink = false,
}) {
  final wcPath = 'wc?uri=${Uri.encodeComponent(wcUri)}';
  if (isDeepLink) {
    final scheme = Uri
        .tryParse(appLink)
        ?.scheme;
    if (scheme != null) {
      return Uri.parse('$scheme://$wcPath');
    }
  }
  return Uri.parse('$appLink/$wcPath');
}

Future<EtherAmount> _getMaxPriorityFeePerGas() {
  // We may want to compute this more accurately in the future,
  // using the formula "check if the base fee is correct".
  // See: https://eips.ethereum.org/EIPS/eip-1559
  return Future.value(EtherAmount.inWei(BigInt.from(1000000000)));
}

// Max Fee = (2 * Base Fee) + Max Priority Fee
Future<EtherAmount> _getMaxFeePerGas(Web3Client client,
    BigInt maxPriorityFeePerGas,) async {
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

List<dynamic> _encodeToRlp(Transaction transaction,
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
    list..add(signature.v)..add(signature.r)..add(signature.s);
  }

  return list;
}
// This code creates a normal transaction.
//It calls the buildEthSendTransactionRequest function to get the transaction parameters,
//and then sends a custom request to the WalletConnect client to send the transaction.
//It then returns the txnHash.

Future<String> makeAndSendNormalTx(BuildContext context,
    WidgetRef ref,
    String functionSignatureHash,
    int chainId,
    EthereumAddress toAddress,
    SignatureData signatureData,
    EthereumAddress walletAddress,
    ReownAppKitModal? wc,
    WalletType walletType, {
      EthereumAddress? toAccount,
      bool? enableRecovery,
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
    enableRecovery: enableRecovery ?? false,
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

  if (walletType.type == EWalletType.ownerCard) {
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

    {
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

      txnFuture = wc!.request(
        topic: wc.session?.topic!,
        chainId: 'eip155:$chainId',
        request: SessionRequestParams(
          method: 'eth_sendTransaction',
          params: txParams,
        ),
      );

      w3mService!.launchConnectedWallet();
    });

    try {
      txnHash = await txnFuture;
    } catch (e) {
      final msg = e.toString();
      // ReownSignError 5100 means the target chain was not in the WalletConnect
      // session namespaces at pairing time; MetaMask approves only its active
      // chain. Ask the user to reconnect with the right chain selected.
      if (msg.contains('5100') || msg.contains('Unsupported chains')) {
        final chainName = chainConfig[chainId]?.networkName ?? 'chain $chainId';
        throw Exception(
          'Your wallet session does not include $chainName. '
          'Please disconnect your wallet, switch to $chainName, '
          'then reconnect and try again.',
        );
      }
      rethrow;
    }
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

Future<void> wcSwitchToChainConditionally(ReownAppKitModal? w3mService,
    int chainId) async {
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
Future<String> sendPersonalSignRequest(WidgetRef ref,
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


Future<ReownAppKitModal> initWcClient(WidgetRef ref,
    BuildContext context) async {
  final metaData = PairingMetadata(
      name: 'OwnerChip',
      description: 'OwnerChip - Connecting physical objects to the blockchain',
      url: 'https://www.ownerchip.com',
      icons: const ['https://avatars.githubusercontent.com/u/116345848'],
      redirect: Redirect(
          universal: "https://www.ownerchip.com",
          native: "${dotenv.env["APP_ID"]}://wc",
          linkMode: false,
      )
  );

  final appkit = await ReownAppKit.createInstance(
    projectId: dotenv.env['WC_PROJECT_ID']!,
    logLevel: LogLevel.error, // Reduce log noise for production
    metadata: metaData,
  );

  // Create supported network list from chain config
  final supportedNetworks = chainConfig.entries.map((entry) {
    final chain = entry.value;
    return ReownAppKitModalNetworkInfo(
      name: chain.networkName,
      chainId: "${entry.key}",
      currency: chain.nativeTokenSymbol,
      rpcUrl: chain.rpcUrl,
      explorerUrl: chain.blockchainExplorerUrl,
    );
  }).toList();

  // Using optionalNamespaces so wallets that don't support every chain can
  // still connect. Chains are included on a best-effort basis; if a chain is
  // missing from the session after connect the transaction will surface a
  // clear error asking the user to reconnect with that chain active.
  final ReownAppKitModal w3mService = ReownAppKitModal(
      context: context,
      appKit: appkit,
      projectId: dotenv.env['WC_PROJECT_ID']!,
      logLevel: LogLevel.error,
      optionalNamespaces: {
        'eip155': RequiredNamespace(
          chains: supportedNetworks
              .map((n) => 'eip155:${n.chainId}')
              .toList(),
          methods: [
            'eth_sendTransaction',
            'eth_signTransaction',
            'personal_sign',
            'eth_signTypedData',
            'eth_signTypedData_v4',
          ],
          events: ['chainChanged', 'accountsChanged'],
        ),
      },
      metadata: metaData);

  w3mService.onSessionEventEvent.subscribe(wrapOnSessionEvent(ref));
  w3mService.onModalConnect.subscribe(wrapOnSessionConnect(ref, context));
  w3mService.onModalDisconnect.subscribe(wrapOnSessionDisconnect(ref));
  w3mService.onSessionExpireEvent.subscribe(wrapOnSessionExpire(ref));

  await w3mService.init();

  ref
      .read(w3mServiceProvider.notifier)
      .state = w3mService;
  ref
      .read(wcSessionProvider.notifier)
      .state = w3mService.session;

  return w3mService;
}

void Function(ModalConnect?) wrapOnSessionConnect(WidgetRef ref,
    BuildContext context) {
  return (ModalConnect? args) {
    //set session and wallet type provider
    talker.log(' WalletConnect session connected');
    talker.log('Session topic: ${args?.session?.topic}');
    talker.log('Session namespaces: ${args?.session?.namespaces}');
    
    ref
        .read(wcSessionProvider.notifier)
        .state = args?.session;
    ref
        .read(walletTypeProvider.notifier)
        .state =
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

  ref
      .read(userSessionProvider.notifier)
      .state = null;
  ref.read(websocketProvider.notifier).disconnect();
  ref
      .read(wcSessionProvider.notifier)
      .state = null;
  ref
      .read(walletTypeProvider.notifier)
      .state = null;
  ref
      .read(userAddressProvider.notifier)
      .state = zeroAddress;
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
