//package imports
import 'dart:convert';

import 'package:convert/convert.dart';
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
import 'package:ownerchip_whitelabel/services/alchemy_bundler.services.dart';
import 'package:ownerchip_whitelabel/services/backend/collection/backendCollection.dart';
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
import 'package:ownerchip_whitelabel/services/privyService.dart';
import 'package:privy_flutter/privy_flutter.dart';
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

Future<String> makeAndSendGaslessTx(WidgetRef ref,
    BuildContext context,
    String functionSignatureHash,
    int chainId,
    EthereumAddress toAddress,
    SignatureData signatureData,
    EthereumAddress walletAddress,
    ReownAppKitModal? wc,
    WalletType walletType, {
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
  final callData = buildContractCallData(
    functionSignatureHash,
    walletAddress,
    toAddress,
    toAccount,
    signatureData.hashedMsg,
    signatureData.signature,
    tokenURI: twinTokenMetadataCID != null ? 'ipfs://$twinTokenMetadataCID' : null,
    voucherTokenURI:
        voucherTokenMetadataCID != null ? 'ipfs://$voucherTokenMetadataCID' : null,
    tokenId: tokenId,
    enableRecovery: enableRecovery,
    sellerPayoutAddress: sellerPayoutAddress,
    price: price,
    encodedOfferData: encodedOfferData,
    typedDataHash: typedDataHash,
    offerHash: offerHash,
    amount: amount,
    token: token,
    chainId: chainId,
  );

  // Fetch MetaTx agreement ID early; soft-fail so the tx still proceeds if it errors.
  String? _metaTxAgreementId;
  try {
    final collectionAddr = toAddress;
    final checkResult = await BackendMetaTx.checkMetaTx(
      collectionAddr,
      functionSignatureHash,
    );
    if (checkResult[0] == true) {
      _metaTxAgreementId = checkResult[1] as String?;
    }
  } catch (e) {
    talker.warning('checkMetaTx failed (non-fatal, will skip recordTx): $e');
  }

  if (walletType.type == EWalletType.walletConnect) {
    talker.log('WalletConnect wallet detected — using normal eth_sendTransaction (no gas sponsorship)');
    final w3mService = ref.read(w3mServiceProvider)!;
    final toAddr = toAddress;
    final valueHex = (functionSignatureHash.isEmpty && amount != null)
        ? '0x${amount!.toRadixString(16)}'
        : '0x0';

    late Future<dynamic> txnFuture;

    await preventRepeatedNFCScan(() async {
      await wcSwitchToChainConditionally(w3mService, chainId).catchError((e) {
        talker.error('WalletConnect: failed to switch chain: $e');
      });
      await Future.delayed(const Duration(seconds: 3));

      // Log a warning if the chain is not yet in the session namespaces, but
      // still attempt the request — MetaMask handles chain selection internally.
      final sessionTopic = wc!.session?.topic;
      final sessionNamespaces = w3mService.appKit
              ?.getActiveSessions()[sessionTopic]
              ?.namespaces ??
          {};
      if (!isValidNamespacesChainId(
        chainId: 'eip155:$chainId',
        namespaces: sessionNamespaces,
      )) {
        talker.warning(
          'WalletConnect: chain eip155:$chainId not found in session namespaces — '
          'proceeding anyway (wallet may handle it). '
          'If this fails, disconnect and reconnect your wallet.',
        );
      }

      txnFuture = wc.request(
        topic: sessionTopic,
        chainId: 'eip155:$chainId',
        request: SessionRequestParams(
          method: 'eth_sendTransaction',
          params: [
            {
              'from': walletAddress.hexEip55,
              'to': toAddr.hexEip55,
              'data': callData,
              'value': valueHex,
            }
          ],
        ),
      );

      w3mService.launchConnectedWallet();
    });

    late String txnHash;
    try {
      txnHash = (await txnFuture) as String;
    } catch (e) {
      final msg = e.toString();
      // ReownSignError code 5100 means the target chain was not included in
      // the WalletConnect session namespaces when the wallet connected.
      // MetaMask approves only its currently active chain at pairing time.
      // Ask the user to reconnect with the correct chain active.
      if (msg.contains('5100') || msg.contains('Unsupported chains')) {
        final chainName = chainConfig[chainId]?.networkName ?? 'chain $chainId';
        throw Exception(
          'Your wallet session does not include $chainName. '
          'Please disconnect your wallet, switch MetaMask to $chainName, '
          'then reconnect and try again.',
        );
      }
      rethrow;
    }
    talker.log('WalletConnect eth_sendTransaction confirmed: $txnHash');

    if (_metaTxAgreementId != null) {
      BackendCollection.recordTx(
        toAddress,
        txHash: txnHash,
        senderAddress: walletAddress.hex,
        metaTxAgreementId: _metaTxAgreementId!,
        functionSignature: functionSignatureHash,
        callData: callData,
        tokenId: tokenId?.toString(),
      ).catchError((e) => talker.error('recordTx failed (non-fatal): $e'));
    }

    return txnHash;
  }

  final preparedResult = await alchemyPrepareCalls(
    chainId: chainId,
    from: walletAddress,
    to: toAddress,
    callData: callData,
    value: (functionSignatureHash.isEmpty && amount != null)
        ? '0x${amount.toRadixString(16)}'
        : '0x0',
  );

  // wallet_prepareCalls returns one of two shapes:
  //
  //  A. type: "user-operation-v070"         (normal case, existing account)
  //       → signatureRequest.data.raw = hash to personal_sign
  //
  //  B. type: "array"                        (first-time EIP-7702 delegation)
  //       data[0]: type "authorization"     → signatureRequest.rawPayload
  //       data[1]: type "user-operation-v070" → signatureRequest.data.raw
  //
  final resultType = preparedResult['type'] as String? ?? '';
  talker.log('wallet_prepareCalls result type: $resultType');

  String hashHex;
  String? authHashHex;

  if (resultType == 'array') {
    final items =
        (preparedResult['data'] as List).cast<Map<String, dynamic>>();

    final userOpItem = items.firstWhere(
      (i) => (i['type'] as String?) == 'user-operation-v070',
      orElse: () => throw Exception(
          'No user-operation-v070 item in wallet_prepareCalls array'),
    );
    final uopSigReq =
        userOpItem['signatureRequest'] as Map<String, dynamic>?;
    final uopSigData = uopSigReq?['data'] as Map<String, dynamic>?;
    hashHex = (uopSigData?['raw'] as String?) ??
        (uopSigReq?['rawPayload'] as String?) ??
        (throw Exception('user-operation signatureRequest missing hash'));
    talker.log('UserOp hash (from array): $hashHex');

    final authItem = items.cast<Map<String, dynamic>?>().firstWhere(
          (i) => (i?['type'] as String?) == 'authorization',
          orElse: () => null,
        );
    if (authItem != null) {
      final authSigReq =
          authItem['signatureRequest'] as Map<String, dynamic>?;
      authHashHex = authSigReq?['rawPayload'] as String?;
      talker.log('EIP-7702 auth required, rawPayload: $authHashHex');
    }
  } else {
    final sigReq =
        preparedResult['signatureRequest'] as Map<String, dynamic>?;
    if (sigReq == null) {
      talker.error(
          'wallet_prepareCalls result missing signatureRequest. Full: $preparedResult');
      throw Exception(
          'wallet_prepareCalls did not return a signatureRequest');
    }
    final sigData = sigReq['data'] as Map<String, dynamic>?;
    talker.log('signatureRequest: $sigReq');
    hashHex = (sigData?['raw'] as String?) ??
        (sigData?['data'] as String?) ??
        (throw Exception(
            'wallet_prepareCalls signatureRequest.data.raw missing'));
  }

  String signature = '';
  String? _ownerCardAuthSignature;

  if (walletType.type == EWalletType.ownerCard) {
    final hashBytes = hexToBytes(hashHex.substring(2));
    final prefixedHash = applyPersonalSignPrefix(hashBytes);

    if (authHashHex != null) {
      // EIP-7702 first-time setup: sign BOTH auth hash AND userOp hash in
      // a SINGLE card tap + PIN entry to avoid asking the user twice.
      //
      // auth hash:   raw bytes (no EIP-191 prefix) — EIP-7702 requires raw secp256k1
      // userOp hash: with EIP-191 prefix         — LightAccount uses toEthSignedMessageHash
      final authBytes = hexToBytes(authHashHex.substring(2));
      // ignore: use_build_context_synchronously
      final sigs = await Navigator.pushNamed(
        context,
        PinScreen.routeName,
        arguments: PinScreenArguments(
          activeFeature: PinScreenActiveFeature.verifyPinTx,
          callback: (String pin) async => makeTwoCardSignatures(
            ref, context,
            authBytes,    // hash1 → authSignature (raw, no prefix)
            prefixedHash, // hash2 → userOpSignature (with EIP-191 prefix)
            pin,
          ),
        ),
      ) as List<MsgSignature?>;
      signature = msgSignatureToHex(sigs[1]!);
      _ownerCardAuthSignature = msgSignatureToHex(sigs[0]!);
    } else {
      // ignore: use_build_context_synchronously
      final cardSignature = await Navigator.pushNamed(
        context,
        PinScreen.routeName,
        arguments: PinScreenArguments(
          activeFeature: PinScreenActiveFeature.verifyPinTx,
          callback: (String pin) async =>
              makeCardSignature(ref, context, prefixedHash, toggleLoading, pin),
        ),
      ) as MsgSignature;
      signature = msgSignatureToHex(cardSignature);
    }
  } else if (walletType.type == EWalletType.certificateCard) {
    await Future.delayed(const Duration(seconds: 3));
    final hashBytes = hexToBytes(hashHex.substring(2));
    final prefixedHash = applyPersonalSignPrefix(hashBytes);
    final sig = await getCardSignature!(hex.encode(prefixedHash));
    if (sig == null) throw Exception('Certificate card returned null signature');
    signature = msgSignatureToHex(sig);
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
              method: 'personal_sign',
              params: [hashHex, walletAddress.toString()],
            ),
          )
          .onError((error, stackTrace) {
        talker.error('WalletConnect personal_sign error: $error', stackTrace);
        throw error!;
      });
    });

    toggleLoading();
  } else {
    // Privy embedded wallet.
    //
    // personal_sign requires user interaction via a WebView modal which blocks
    // behind any loading overlay and times out.  Instead we pre-apply the
    // EIP-191 prefix ourselves (exactly as card signers do) and then use
    // secp256k1_sign, which signs raw bytes silently without any UI prompt,
    // producing an identical signature.
    try {
      final hashBytes = hexToBytes(hashHex.substring(2));
      final prefixedHash = applyPersonalSignPrefix(hashBytes);
      final prefixedHex =
          '0x${prefixedHash.map((b) => b.toRadixString(16).padLeft(2, '0')).join()}';
      signature = await _privySecp256k1Sign(
        hashHex: prefixedHex,
        label: 'UserOp',
      );
    } catch (e, st) {
      Sentry.captureException(e, stackTrace: st);
      debugPrint(e.toString());
      debugPrintStack(stackTrace: st);
      rethrow;
    }
  }

  if (signature.isEmpty) throw Exception('Failed to obtain signature');

  // EIP-7702 auth hash (rawPayload) must be signed RAW — no EIP-191 prefix.
  // personal_sign would prepend "\x19Ethereum Signed Message:\n32" and hash
  // again, making Alchemy recover the wrong authority address.
  //
  // OwnerCard: already signed in step 4 (single tap), stored in _ownerCardAuthSignature.
  // WalletConnect: use eth_sign (params: [address, data]) — no prefix.
  // Privy: use secp256k1_sign (raw, no UI prompt).
  // CertificateCard: sign raw bytes.
  String? authSignature = _ownerCardAuthSignature; // pre-filled for OwnerCard
  if (authHashHex != null && authSignature == null) {
    talker.log('Signing EIP-7702 auth hash: $authHashHex');
    if (walletType.type == EWalletType.certificateCard) {
      await Future.delayed(const Duration(seconds: 3));
      final authBytes = hexToBytes(authHashHex.substring(2));
      final sig = await getCardSignature!(hex.encode(authBytes));
      if (sig == null) throw Exception('Certificate card returned null auth signature');
      authSignature = msgSignatureToHex(sig);
    } else if (walletType.type == EWalletType.walletConnect) {
      final ReownAppKitModal? w3mService = ref.read(w3mServiceProvider);
      await preventRepeatedNFCScan(() async {
        w3mService!.launchConnectedWallet();
        toggleLoading();
        // EIP-7702 auth must be signed raw (no EIP-191 prefix).
        // eth_sign params are [address, data] — opposite of personal_sign.
        authSignature = await wc!
            .request(
              topic: wc.session?.topic,
              chainId:
                  w3mService.selectedChain?.chainId ?? 'eip155:$chainId',
              request: SessionRequestParams(
                method: 'eth_sign',
                params: [walletAddress.toString(), authHashHex],
              ),
            )
            .onError((error, stackTrace) {
          talker.error('WalletConnect auth eth_sign error: $error');
          throw error!;
        });
      });
      toggleLoading();
    } else {
      // Privy embedded wallet.
      // EIP-7702 auth MUST be signed raw (no EIP-191 prefix).
      // secp256k1_sign signs the hash directly, no user confirmation needed.
      authSignature = await _privySecp256k1Sign(
        hashHex: authHashHex!,
        label: 'EIP-7702 auth',
      );
    }
    talker.log('EIP-7702 auth signature obtained');
  }

  final userOpHash = await alchemySendPreparedCalls(
    chainId: chainId,
    preparedResult: preparedResult,
    userOpSignature: signature,
    authSignature: authSignature,
  );
  talker.log('UserOperation submitted: $userOpHash');

  final txHash = await waitForUserOpReceipt(chainId, userOpHash);
  talker.log('UserOperation confirmed, txHash: $txHash');

  if (_metaTxAgreementId != null) {
    BackendCollection.recordTx(
      toAddress,
      txHash: txHash,
      senderAddress: walletAddress.hex,
      metaTxAgreementId: _metaTxAgreementId!,
      functionSignature: functionSignatureHash,
      callData: callData,
      tokenId: tokenId?.toString(),
    ).catchError((e) => talker.error('recordTx failed (non-fatal): $e'));
  }

  return txHash;
}

/// Signs [hashHex] via the Privy embedded wallet using `secp256k1_sign`.
///
/// This method signs the hash **raw** (no EIP-191 prefix) and requires no
/// user interaction — unlike `personal_sign` which opens a WebView modal.
///
/// Usage:
///  • UserOp hash: caller must pre-apply [applyPersonalSignPrefix] so that
///    the on-chain `toEthSignedMessageHash(hash)` verification passes.
///  • EIP-7702 auth rawPayload: pass as-is (no prefix — raw secp256k1 verify).
Future<String> _privySecp256k1Sign({
  required String hashHex,
  String label = '',
  int maxRetries = 3,
  Duration retryDelay = const Duration(seconds: 2),
}) async {
  int attempt = 0;
  while (true) {
    attempt++;
    try {
      final privyUser = await privyInstance.getUser();
      if (privyUser == null || privyUser.embeddedEthereumWallets.isEmpty) {
        throw Exception('No Privy embedded wallet found');
      }
      final wallet = privyUser.embeddedEthereumWallets.first;
      String result = '';
      final rpcResponse = await wallet.provider.request(
        EthereumRpcRequest(
          method: 'secp256k1_sign',
          params: [hashHex],
        ),
      );
      rpcResponse.fold(
        onSuccess: (response) => result = response.data,
        onFailure: (error) =>
            throw Exception('Privy secp256k1_sign failed: ${error.message}'),
      );
      if (attempt > 1) {
        talker.log('Privy $label secp256k1_sign succeeded on attempt $attempt');
      }
      return result;
    } catch (e) {
      final isTransient = e.toString().toLowerCase().contains('timeout') ||
          e.toString().toLowerCase().contains('timed out') ||
          e.toString().toLowerCase().contains('network');
      if (attempt < maxRetries && isTransient) {
        talker.warning(
            'Privy $label secp256k1_sign attempt $attempt failed, retrying in ${retryDelay.inSeconds}s…');
        await Future.delayed(retryDelay);
        continue;
      }
      rethrow;
    }
  }
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
    EWalletType.privy,
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
      final privyUser = await privyInstance.getUser();
      if (privyUser == null || privyUser.embeddedEthereumWallets.isEmpty) {
        throw Exception('No Privy embedded wallet');
      }
      final wallet = privyUser.embeddedEthereumWallets.first;

      EthereumRpcResponse? rpcResult;
      final rpcResponse = await wallet.provider.request(
        EthereumRpcRequest(
          method: 'eth_sendTransaction',
          params: [txParams[0]],
        ),
      );
      rpcResponse.fold(
        onSuccess: (response) => rpcResult = response,
        onFailure: (error) =>
            throw Exception('Privy tx failed: ${error.message}'),
      );
      // For privy eth_sendTransaction, the result is the tx hash
      txnHash = rpcResult!.data;
      talker.log('Privy transaction sent: $txnHash');
      return txnHash;
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

  if (walletType.type == EWalletType.privy) {
    Future<String> signWithPrivy() async {
      final privyUser = await privyInstance.getUser();
      if (privyUser == null || privyUser.embeddedEthereumWallets.isEmpty) {
        throw Exception('No Privy embedded wallet');
      }
      final wallet = privyUser.embeddedEthereumWallets.first;
      String result = '';
      final rpcResponse = await wallet.provider.request(
        EthereumRpcRequest(
          method: 'personal_sign',
          params: [siweMessage ? message : hexUtf8EncodedMessage, walletAddress.toString()],
        ),
      );
      rpcResponse.fold(
        onSuccess: (response) => result = response.data,
        onFailure: (error) =>
            throw Exception('Privy personal_sign failed: ${error.message}'),
      );
      return result;
    }

    try {
      return await signWithPrivy();
    } catch (e, st) {
      Sentry.captureException(e, stackTrace: st);
      throw Exception('Failed to sign message with Privy');
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

Future<void> onCertificateCardLogin(WidgetRef ref,
    BuildContext context,
    bool removeWalletPopup,) async {
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

bool _initializedPrivy = false;

Future<void> setupPrivy() async {
  if (_initializedPrivy) return;
  try {
    await initPrivy();
    _initializedPrivy = true;
  } catch (e) {
    talker.error('Failed to initialize Privy: $e');
    // Do NOT set _initializedPrivy = true here so the next call can retry.
  }
}
