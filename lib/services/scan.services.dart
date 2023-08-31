// ignore_for_file: use_build_context_synchronously

//import packages
import 'dart:async';
import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:ownerchip_whitelabel/widgets/popups/AndroidNfcPopup.dart';
import 'package:web3dart/credentials.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nfc_manager/nfc_manager.dart';
import 'package:web3dart/crypto.dart';
import 'package:sentry/sentry.dart';

//import services
import 'package:ownerchip_whitelabel/services/nfc.services.dart';
import 'package:ownerchip_whitelabel/services/backend.services.dart';
import 'package:ownerchip_whitelabel/services/signature.services.dart';
import 'package:ownerchip_whitelabel/services/providers.services.dart';

//import screens
import 'package:ownerchip_whitelabel/screens/ChainSelectorScreen.dart';
import 'package:ownerchip_whitelabel/screens/UserScanResultsScreen.dart';

//import misc
import 'package:ownerchip_whitelabel/utils/navigationArguments.dart';
import 'package:ownerchip_whitelabel/utils/utils.dart';
import 'package:ownerchip_whitelabel/utils/localization.helper.dart';
import 'package:ownerchip_whitelabel/config/constants.dart';
import 'package:ownerchip_whitelabel/domain/classDefinition.dart';

Future<void> initializeItem(WidgetRef ref, BuildContext context) async {
  Future callback(NFCPlatform nfc, String sessionId,
      List createFirstKeyChipResponse) async {
    EthereumAddress chipEthereumAddress = createFirstKeyChipResponse[0];
    String chipWalletAddress = chipEthereumAddress.toString();
    BigInt chipTokenId = createFirstKeyChipResponse[1];
    bool ndefTagInitialized = createFirstKeyChipResponse[2];
    if (ndefTagInitialized) {
      sendAnalyticsTrace(sessionId, chipWalletAddress, "CHIP_INITIALIZED");
    }

    //set chip info data in provider
    setChipInfoProvider(ref, chipEthereumAddress, chipTokenId);

    TokenInfoObject config =
        await ref.watch(findTokenProvider(chipTokenId).future);

    //verify signature
    List verificationResult = await verifySignatureAuthenticity(
        nfc, sessionId, chipEthereumAddress, chipTokenId);
    Uint8List hashedMsg = verificationResult[0];
    MsgSignature signature = verificationResult[1];
    ref.read(chipSignatureDataProvider.notifier).setSignatureData(
        SignatureData(hashedMsg: hashedMsg, signature: signature));

    //TOKEN DOES NOT EXIST
    if (config.collectionId == zeroAddress) {
      sendAnalyticsTrace(sessionId, "", "SCAN_RESULT_NEGATIVE",
          tags: {"chipWallet": chipWalletAddress});

      //TODO: WHY DO I PASS METADATAScreen Arguments t o ChainSelectorScreen??
      Navigator.pushNamed(context, ChainSelectorScreen.routeName,
          arguments: MetadataInputScreenArguments(sessionId, 0, zeroAddress));
    }
    //TOKEN EXISTS
    else {
      await verifyAuthenticity(config, chipEthereumAddress, hashedMsg,
          signature, sessionId, chipWalletAddress, context);

      Navigator.pushNamed(
        context,
        UserScanResultsScreen.routeName,
      );
    }
  }

  return await scanClosure(
      context, ref, callback, "initializeItem", context.loc.holdPhoneToNfcChip);
}

Future<void> scanItem(WidgetRef ref, BuildContext context) async {
  Future callback(NFCPlatform nfc, String sessionId,
      List createFirstKeyChipResponse) async {
    EthereumAddress chipEthereumAddress = createFirstKeyChipResponse[0];
    String chipWalletAddress = chipEthereumAddress.toString();
    BigInt chipTokenId = createFirstKeyChipResponse[1];

    //set chip info data in provider
    setChipInfoProvider(ref, chipEthereumAddress, chipTokenId);

    TokenInfoObject config =
        await ref.watch(findTokenProvider(chipTokenId).future);

    //verify signature
    List verificationResult = await verifySignatureAuthenticity(
        nfc, sessionId, chipEthereumAddress, chipTokenId);
    Uint8List hashedMsg = verificationResult[0];
    MsgSignature signature = verificationResult[1];
    ref.read(chipSignatureDataProvider.notifier).setSignatureData(
        SignatureData(hashedMsg: hashedMsg, signature: signature));

    //TOKEN DOES NOT EXIST
    if (config.collectionId == zeroAddress) {
      sendAnalyticsTrace(sessionId, "", "SCAN_RESULT_NEGATIVE",
          tags: {"chipWallet": chipWalletAddress});

      Navigator.pushNamed(
        context,
        UserScanResultsScreen.routeName,
      );
    } else {
      //TOKEN EXISTS
      await verifyAuthenticity(config, chipEthereumAddress, hashedMsg,
          signature, sessionId, chipWalletAddress, context);

      Navigator.pushNamed(
        context,
        UserScanResultsScreen.routeName,
      );
    }
  }

  return await scanClosure(
      context, ref, callback, "scanItem", context.loc.holdPhoneToNfcChip);
}

void setChipInfoProvider(
    WidgetRef ref, EthereumAddress chipEthereumAddress, BigInt chipTokenId) {
  ref
      .read(chipInfoProvider.notifier)
      .setChipEthereumAddress(chipEthereumAddress);
  ref.read(chipInfoProvider.notifier).setTokenId(chipTokenId);
  ref.read(chipInfoProvider.notifier).setChipToInitialized();
}

//TODO: Check if this function should actually return a bool? What happens if verifyTokenAuthenticity returns false?
Future<void> verifyAuthenticity(
    TokenInfoObject config,
    EthereumAddress chipEthereumAddress,
    Uint8List hashedMsg,
    MsgSignature signature,
    String sessionId,
    String chipWalletAddress,
    BuildContext context) async {
  try {
    //verify token authenticity via smart contract
    bool tokenIsAuthentic = await verifyTokenAuthenticity(
        getRPCUrlFromChainId(config.chainId),
        config.collectionId,
        chipEthereumAddress,
        hashedMsg,
        signature);

    sendAnalyticsTrace(sessionId, "", "SCAN_RESULT_POSITIVE",
        tags: {"chipWallet": chipWalletAddress});
  } catch (e) {
    //TOKEN IS NOT AUTHENTIC
    rethrow;
  }
}

/* GET SIGNATURE A MESSAGE/HASH FORM CARD*/
//returns MsgSignature if everything worked correctly
//returns null if user cancels scan or error occurs
Future<MsgSignature?> makeCardSignature(WidgetRef ref, BuildContext context,
    msgHashToSign, Function toggleLoading, String pin) async {
  Future callback(NFCPlatform nfc, String sessionId,
      List createFirstKeyChipResponse) async {
    bool pinVerified = await verifyPin(nfc, pin);
    EthereumAddress cardWalletAddress = createFirstKeyChipResponse[0];
    MsgSignature signature = await signHash(
        nfc, 0x01, cardWalletAddress, hexToBytes(msgHashToSign), false);
    return signature;
  }

  return await scanClosure(
      context, ref, callback, "makeCardSignature", context.loc.holdPhoneToCard);
}

Future<void> authenticateCard(
    WidgetRef ref, BuildContext context, String pin) async {
  Future callback(NFCPlatform nfc, String sessionId,
      List createFirstKeyChipResponse) async {
    String message =
        "Sign this message to confirm that you are the owner of your wallet (SessionId: $sessionId)";
    Uint8List msgHashToSign = keccakUtf8(message);
    bool pinVerified = await verifyPin(nfc, pin);
    EthereumAddress cardWalletAddress = createFirstKeyChipResponse[0];
    MsgSignature signature =
        await signHash(nfc, 0x01, cardWalletAddress, msgHashToSign, false);
    await saveUserSession(sessionId, cardWalletAddress, signature, ref);
  }

  return await scanClosure(
      context, ref, callback, "authenticateCard", context.loc.holdPhoneToCard);
}

// PIN CODE
Future<String?> setPinOnCard(
    BuildContext context, WidgetRef ref, String pin) async {
  Future callback(NFCPlatform nfc, String sessionId,
      List createFirstKeyChipResponse) async {
    // return await setPin(nfc, pin);
    //return future .delayed with some string
    return await Future.delayed(const Duration(seconds: 1), () => "123456");
  }

  return await scanClosure(context, ref, callback, "setPinOnCard",
      context.loc.holdPhoneCloseToOwnerCardToInit);
}

Future<void> resetPinOnCard(
    BuildContext context, WidgetRef ref, String puk) async {
  Future callback(NFCPlatform nfc, String sessionId,
      List createFirstKeyChipResponse) async {
    bool success = await unlockPin(nfc, puk);
  }

  scanClosure(context, ref, callback, "ownerCardAdminInit",
      context.loc.holdPhoneToCard);
}

// this function creates two slots on OwnerCard, to distinguish Smart Cards from normal NFC chips in objects
Future<void> ownerCardAdminInit(
    BuildContext context, WidgetRef ref, Function setStateCallback) async {
  Future callback(NFCPlatform nfc, String sessionId,
      List createFirstKeyChipResponse) async {
    //create or read first two keys if not existing; return them
    Map result = await createSecondKeypairOnChip(nfc, sessionId);
    EthereumAddress cardWalletAddress1 = result['key1'];
    EthereumAddress cardWalletAddress2 = result['key2'];

    setStateCallback(cardWalletAddress1, cardWalletAddress2);
  }

  scanClosure(context, ref, callback, "ownerCardAdminInit",
      context.loc.holdPhoneToCard);
}

Future<dynamic> getChipWalletAddress(
    BuildContext context, WidgetRef ref) async {
  Future callback(NFCPlatform nfc, String sessionId,
      List createFirstKeyChipResponse) async {
    return createFirstKeyChipResponse[0];
  }

  return await scanClosure(context, ref, callback, "getChipWalletAddress",
      context.loc.holdPhoneToCard);
}

//scan closure abstraction
Future<dynamic> scanClosure(
    BuildContext context,
    WidgetRef ref,
    Future<dynamic> Function(NFCPlatform, String, List) callback,
    String functionName,
    String alertMessage) async {
  await NfcManager.instance.stopSession();

  Completer<void> completer = Completer();

  //get saved session id if exists, else get new one from backend
  String sessionId = ref.read(userSessionProvider) != null
      ? ref.read(userSessionProvider)!.sessionId
      : await getSessionId();

  //start NFC scan
  final scanProcess = Sentry.startTransaction('$functionName()', 'task');
  NFCOverlay nfcOverlay = NFCOverlay();
  if (Platform.isAndroid) {
    nfcOverlay.showNfcOverlay(
        context, context.loc.holdPhoneCloseToOwnerCardToInit);
  }

  NfcManager.instance.startSession(
      onError: (error) async {
        stopNfcOniOSAndAndroid(nfcOverlay);
        completer.completeError(error);
      },
      alertMessage: alertMessage,
      onDiscovered: (NfcTag tag) async {
        try {
          var nfc = NFCPlatform(tag);

          //check if iso7816 or isodep is available and exit if not
          await nfcPlatformCheck(context, sessionId, nfc);

          //create first key if not existing
          List createFirstKeyChipResponse =
              await createFirstKeypairOnChip(nfc, false, sessionId);

          final result =
              await callback(nfc, sessionId, createFirstKeyChipResponse);

          completer.complete(result);
          stopNfcOniOSAndAndroid(nfcOverlay);
          scanProcess.finish();
        } catch (e, stackTrace) {
          NfcManager.instance.stopSession(
              errorMessage: e.toString()); //the error is passed to onError here

          //LOG ERROR
          print(e);
          sendAnalyticsTrace(sessionId, "$e", "INIALIZE_SCAN_ERROR");
          scanProcess.throwable = e;
          scanProcess.status = const SpanStatus.deadlineExceeded();
          scanProcess.finish();
          await Sentry.captureException(
            e,
            stackTrace: stackTrace,
          );
        }
      });

  return completer.future;
}

//function template
Future<void> stopNfcOniOSAndAndroid(NFCOverlay nfcOverlay) async {
  if (Platform.isIOS) {
    NfcManager.instance.stopSession();
  }
  if (Platform.isAndroid) {
    nfcOverlay.removeNfcOverlay();
  }

  if (Platform.isAndroid) {
    await Future.delayed(const Duration(seconds: 2));
    NfcManager.instance.stopSession();
  }
}
