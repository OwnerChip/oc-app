// ignore_for_file: use_build_context_synchronously

//import packages
import 'dart:async';
import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:ownerchip_whitelabel/widgets/popups/AndroidNfcPopup.dart';
import 'package:ownerchip_whitelabel/widgets/popups/returnSnackBarWidget.dart';
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

Future<void> generateKeyOnChip(WidgetRef ref, BuildContext context) async {
  Future callback(NFCPlatform nfc, String sessionId,
      List createFirstKeyChipResponse) async {
    return await generatePubAddress(nfc);
  }

  return await scanClosure(context, ref, callback, "testGenerateKeyOnChip",
      context.loc.holdPhoneToNfcChip);
}

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
    Uint8List pubKeyZero = await getPubKeyN(nfc, 0x00);
    if (pubKeyZero.isNotEmpty) {
      return await setPin(nfc, pin);
    } else {
      throw context.loc.cardNotInitializedByAdmin;
    }
  }

  return await scanClosure(context, ref, callback, "setPinOnCard",
      context.loc.holdPhoneCloseToOwnerCardToInit);
}

Future<String?> resetPinOnCard(
    BuildContext context, WidgetRef ref, String puk, String pin) async {
  Future callback(NFCPlatform nfc, String sessionId,
      List createFirstKeyChipResponse) async {
    bool success = await unlockPin(nfc, puk);
    if (success) {
      return await setPin(nfc, pin);
    }
  }

  return await scanClosure(
      context, ref, callback, "resetPinOnCard", context.loc.holdPhoneToCard);
}

Future<dynamic> getChipWalletAddress(
    BuildContext context, WidgetRef ref) async {
  Future callback(NFCPlatform nfc, String sessionId,
      List createFirstKeyChipResponse) async {
    //get second key
    Uint8List cardWalletAddress2 = await getPubKeyN(nfc, 2);
    if (cardWalletAddress2.isEmpty) {
      throw context.loc.transferOnlyToOwnerCard;
    }
    return createFirstKeyChipResponse[0];
  }

  return await scanClosure(context, ref, callback, "getChipWalletAddress",
      context.loc.holdPhoneToCard);
}

Future<dynamic> getAllChipWalletAddresses(
    BuildContext context, WidgetRef ref) async {
  Future callback(NFCPlatform nfc, String sessionId,
      List createFirstKeyChipResponse) async {
    List<EthereumAddress> pubKeys = [];
    for (int i = 0; i < 256; i++) {
      Uint8List pubKey = await getPubKeyN(nfc, i);
      if (pubKey.isEmpty && i == 0) {
        //ignore if slot 0 is not initialized
        continue;
      }
      if (pubKey.isEmpty) {
        break;
      }
      Uint8List addr = publicKeyToAddress(pubKey);
      pubKeys.add(EthereumAddress(addr));
    }
    return pubKeys;
  }

  return await scanClosure(context, ref, callback, "getAllChipWalletAddresses",
      context.loc.holdPhoneToNfcChip);
}

Future<bool> triggerCardLost(
    BuildContext context, WidgetRef ref, String email, String name) async {
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

    //verify signature
    List verificationResult = await verifySignatureAuthenticity(
        nfc, sessionId, chipEthereumAddress, chipTokenId);
    Uint8List hashedMsg = verificationResult[0];
    MsgSignature signature = verificationResult[1];
    ref.read(chipSignatureDataProvider.notifier).setSignatureData(
        SignatureData(hashedMsg: hashedMsg, signature: signature));

    final ChipInfoModel chipInfo = ref.read(chipInfoProvider);
    final TokenInfoObject tokenInfo =
        await ref.refresh(findTokenProvider(chipInfo.tokenId).future);
    SignatureData chipSignature = ref.read(chipSignatureDataProvider);
    if (tokenInfo.collectionId != zeroAddress) {
      return await sendCardLostToBackend(createFirstKeyChipResponse[0],
          tokenInfo.collectionId, chipSignature, sessionId, email, name);
    } else {
      throw context.loc.tokenDoesNotExist;
    }
  }

  return await scanClosure(context, ref, callback, "triggerCardLost",
      context.loc.scanToTriggerCardLost);
}

Future<dynamic> importKeyToSlotZero(BuildContext context, WidgetRef ref,
    Function setStateCallback, String customerId) async {
  Uint8List seed = Uint8List.fromList([
    0x00,
    0x01,
    0x02,
    0x03,
    0x04,
    0x05,
    0x06,
    0x07,
    0x08,
    0x09,
    0x0a,
    0x0b,
    0x0c,
    0x0d,
    0x0e,
    0x0f,
  ]);
  Future callback(NFCPlatform nfc, String sessionId,
      List createFirstKeyChipResponse) async {
    var pubKeyZero;
    pubKeyZero = await getPubKeyN(nfc, 0x00);
    if (pubKeyZero.isEmpty) {
      await writeKeyToSlotZero(nfc, seed);
      pubKeyZero = await getPubKeyN(nfc, 0x00);
    }
    sendCardInitToBackend(customerId, createFirstKeyChipResponse[0]);

    EthereumAddress cardWalletAddress = EthereumAddress.fromHex(
        "0x${bytesToHex(publicKeyToAddress(pubKeyZero))}");

    setStateCallback(cardWalletAddress);
  }

  return await scanClosure(context, ref, callback, "IMPORT_KEY_TO_SLOT_ZERO",
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
    nfcOverlay.showNfcOverlay(context, alertMessage);
  }

  NfcManager.instance.startSession(
      onError: (error) async {
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
              await createFirstKeypairOnChip(nfc, true, sessionId);

          final result =
              await callback(nfc, sessionId, createFirstKeyChipResponse);

          completer.complete(result);
          stopNfcOniOSAndAndroid(nfcOverlay);
          scanProcess.finish();
          sendAnalyticsTrace(
              sessionId,
              'Scanned chip addr: ${createFirstKeyChipResponse[0]}',
              functionName);
        } catch (e, stackTrace) {
          String errorMessage = e.toString();
          print(errorMessage);
          //if errorMessage contains string 'tag was lost' set errorMessage to 'tag was lost'
          if (errorMessage.contains('Tag was lost')) {
            errorMessage = 'Please hold phone to chip a bit longer.';
          }
          NfcManager.instance.stopSession(
              errorMessage: errorMessage); //the error is passed to onError here
          stopNfcOniOSAndAndroid(nfcOverlay);
          if (Platform.isAndroid) {
            ScaffoldMessenger.of(context).showSnackBar(
              returnSnackBarWidget(
                  context.loc.errorHeadingSnackBar,
                  errorMessage.length > 40
                      ? errorMessage.substring(0, 40) + '...'
                      : errorMessage,
                  'error'),
            );
          }
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
          rethrow;
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

  //delay stopping nfc session, to avoid reading the same tag twice
  if (Platform.isAndroid) {
    await Future.delayed(const Duration(seconds: 2));
    NfcManager.instance.stopSession();
  }
}
