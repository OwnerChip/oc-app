// ignore_for_file: use_build_context_synchronously

//import packages
import 'dart:async';
import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:ownerchip_whitelabel/screens/MetadataInputScreen.dart';
import 'package:ownerchip_whitelabel/screens/PinScreen.dart';
import 'package:ownerchip_whitelabel/services/backend/auth/backendAuth.dart';
import 'package:ownerchip_whitelabel/services/providers/collectionsData.dart';
import 'package:ownerchip_whitelabel/services/providers/walletconnectData.dart';
import 'package:ownerchip_whitelabel/services/wallet.services.dart';
import 'package:ownerchip_whitelabel/widgets/popups/AndroidNfcPopup.dart';
import 'package:ownerchip_whitelabel/widgets/popups/returnSnackBarWidget.dart';
import 'package:web3dart/credentials.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nfc_manager/nfc_manager.dart';
import 'package:web3dart/crypto.dart';
import 'package:sentry/sentry.dart';

//import services
import 'package:ownerchip_whitelabel/services/secora.services.dart';
import 'package:ownerchip_whitelabel/services/backend/backend.services.dart';
import 'package:ownerchip_whitelabel/services/signature.services.dart';
import 'package:ownerchip_whitelabel/services/providers/chipData.dart';
import 'package:ownerchip_whitelabel/services/providers/nftData.dart';
import 'package:ownerchip_whitelabel/services/providers/userData.dart';

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

    TokenChainAndCollection config =
        await ref.watch(findTokenProvider(chipTokenId).future);
    BlockchainCollectionList relevantCollections =
        await ref.watch(findAllMinterRolesProvider.future);

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

      //decide if chain selector screen should be shown
      bool showChainSelector = false;
      if (relevantCollections.collections.keys.length > 1) {
        showChainSelector = true;
      } else {
        //loop over all chain IDs in relevantCollections
        for (int chainId in relevantCollections.collections.keys) {
          if (relevantCollections.collections[chainId]!.length > 1) {
            showChainSelector = true;
            break;
          }
        }
      }

      if (showChainSelector) {
        Navigator.pushNamed(context, ChainSelectorScreen.routeName,
            arguments: MetadataInputScreenArguments(sessionId, 0, zeroAddress));
      } else {
        int chainId = relevantCollections.collections.keys.first;
        Collection? collection =
            relevantCollections.collections[chainId]!.first;
        Navigator.pushNamed(context, MetadataScreen.routeName,
            arguments: MetadataInputScreenArguments(
                sessionId, chainId, collection.id,
                voucherAddress: collection.voucherAddress));
      }
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

  return await scanClosure(context, ref, callback, "INITIALIZE_ITEM",
      context.loc.holdPhoneToNfcChip);
}

Future<void> scanItem(WidgetRef ref, BuildContext context) async {
  Future callback(NFCPlatform nfc, String sessionId,
      List createFirstKeyChipResponse) async {
    EthereumAddress chipEthereumAddress = createFirstKeyChipResponse[0];
    String chipWalletAddress = chipEthereumAddress.toString();
    BigInt chipTokenId = createFirstKeyChipResponse[1];

    //set chip info data in provider
    setChipInfoProvider(ref, chipEthereumAddress, chipTokenId);

    TokenChainAndCollection config =
        await ref.watch(findTokenProvider(chipTokenId).future);

    //verify signature
    try {
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
    } catch (e) {
      // check if wallet is connected

      if (ref.read(wcSessionProvider) == null &&
          e == "Error: Chip is PIN code locked.") {
        await NfcManager.instance.stopSession();
        //navigate to PinScreen
        Navigator.pushNamed(context, PinScreen.routeName,
            arguments: PinScreenArguments(
                activeFeature: PinScreenActiveFeature.verifyPinAuth,
                callback: (String pin) async {
                  onCardPress(ref, context, pin, false);
                }));
      } else {
        rethrow;
      }
    }
  }

  return await scanClosure(
      context, ref, callback, "SCAN_ITEM", context.loc.holdPhoneToNfcChip);
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
    TokenChainAndCollection config,
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

/*GET SIGNATURE OF A MESSAGE/HASH FROM A CHIP WHICH IS NOT PIN LOCKED*/
Future<MsgSignature?> getChipSignature(WidgetRef ref, BuildContext context,
    msgHashToSign, Function toggleLoading) async {
  Future callback(NFCPlatform nfc, String sessionId,
      List createFirstKeyChipResponse) async {
    EthereumAddress chipWalletAddress = createFirstKeyChipResponse[0];
    MsgSignature signature = await signHash(
        nfc, 0x01, chipWalletAddress, hexToBytes(msgHashToSign), true);
    return signature;
  }

  return await scanClosure(context, ref, callback, "MAKE_CHIP_SIGNATURE",
      context.loc.holdPhoneToNfcChip);
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

  return await scanClosure(context, ref, callback, "MAKE_CARD_SIGNATURE",
      context.loc.holdPhoneToCard);
}

Future<void> authenticateCard(
    WidgetRef ref, BuildContext context, String pin) async {
  Future callback(NFCPlatform nfc, String sessionId,
      List createFirstKeyChipResponse) async {
    final message = BackendAuth.createSiweMessage(
      address: createFirstKeyChipResponse[0],
      statement: "Sign in with Ethereum to the app.",
      nonce: sessionId,
    );
    final Uint8List msgHashToSign = keccakUtf8(message[1]);
    final bool pinVerified = await verifyPin(nfc, pin);
    final EthereumAddress cardWalletAddress = createFirstKeyChipResponse[0];
    final MsgSignature signature = await signHash(
      nfc,
      0x01,
      cardWalletAddress,
      msgHashToSign,
      false,
    );

    final rHex = signature.r.toRadixString(16).padLeft(64, '0');
    final sHex = signature.s.toRadixString(16).padLeft(64, '0');
    final vHex = signature.v.toRadixString(16).padLeft(2, '0');

    final jwt = await BackendAuth.validateSiwe(
      message: message[0],
      signature: "0x$rHex$sHex$vHex",
    );

    await BackendAuth.saveUserSession(
      sessionId,
      cardWalletAddress,
      signature,
      ref,
      jwt,
    );
  }

  return await scanClosure(
      context, ref, callback, "AUTHENTICATE_CARD", context.loc.holdPhoneToCard);
}

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

  return await scanClosure(context, ref, callback, "SET_PIN_ON_CARD",
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
      context, ref, callback, "RESET_PIN_ON_CARD", context.loc.holdPhoneToCard);
}

Future<dynamic> getFirstChipWalletAddress(
    BuildContext context, WidgetRef ref) async {
  Future callback(NFCPlatform nfc, String sessionId,
      List createFirstKeyChipResponse) async {
    return createFirstKeyChipResponse[0];
  }

  return await scanClosure(context, ref, callback, "GET_CHIP_ADDR_FOR_TRANSFER",
      context.loc.holdPhoneToCard);
}

Future<dynamic> getFirstChipWalletAddressForTransfer(
    BuildContext context, WidgetRef ref) async {
  Future callback(NFCPlatform nfc, String sessionId,
      List createFirstKeyChipResponse) async {
    //get 0th key to check if it exists, so user can only send token to owner card
    Uint8List cardWalletAddress0 = await getPubKeyN(nfc, 0);
    if (cardWalletAddress0.isEmpty) {
      throw context.loc.transferOnlyToOwnerCard;
    }
    return createFirstKeyChipResponse[0];
  }

  return await scanClosure(context, ref, callback, "GET_CHIP_ADDR_FOR_TRANSFER",
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
        //add zero addr if slot 0 is not initialized
        pubKeys.add(zeroAddress);
        continue;
      }

      if (pubKey.isEmpty && i != 0) {
        break;
      }
      Uint8List addr = publicKeyToAddress(pubKey);
      pubKeys.add(EthereumAddress(addr));
    }
    return pubKeys;
  }

  return await scanClosure(context, ref, callback, "GET_CHIP_WALLET_ADDRESSES",
      context.loc.holdPhoneToNfcChip);
}

Future<bool> triggerCardLost(BuildContext context, WidgetRef ref, String email,
    String name, String telNr) async {
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
    final TokenChainAndCollection tokenInfo =
        await ref.refresh(findTokenProvider(chipInfo.tokenId).future);
    SignatureData chipSignature = ref.read(chipSignatureDataProvider);
    if (tokenInfo.collectionId != zeroAddress) {
      return await sendCardLostToBackend(createFirstKeyChipResponse[0],
          tokenInfo.collectionId, chipSignature, sessionId, email, name, telNr);
    } else {
      throw context.loc.tokenDoesNotExist;
    }
  }

  return await scanClosure(
      context, ref, callback, "CARD_LOST", context.loc.scanToTriggerCardLost);
}

Future<dynamic> importKeyToSlotZero(BuildContext context, WidgetRef ref,
    Function setStateCallback, String customerId) async {
  String identifier = generateOwnerCardIdentifier(
      int.parse(customerId), dotenv.get('OWNERCARD_BASE_ID'));
  Uint8List seed = hexToBytes(identifier);
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

//this function takes a callback, executes the NFC scan and executes the callback (e.g. to get chip signature etc)
Future<dynamic> scanClosure(
    BuildContext context,
    WidgetRef ref,
    Future<dynamic> Function(NFCPlatform, String, List) callback,
    String analyticsType,
    String alertMessage) async {
  await NfcManager.instance.stopSession();

  if (!await checkInternetConnection()) {
    throw "No internet connection";
  }

  Completer<void> completer = Completer();

  //get saved session id if exists, else get new one from backend
  String sessionId = ref.read(userSessionProvider) != null
      ? ref.read(userSessionProvider)!.sessionId
      : await BackendAuth.getSessionId();

  //start NFC scan
  final scanProcess = Sentry.startTransaction('$analyticsType', 'task');
  NFCOverlay nfcOverlay = NFCOverlay();
  if (Platform.isAndroid) {
    nfcOverlay.showNfcOverlay(context, alertMessage);
  }

  NfcManager.instance.startSession(
      onError: (error) async {
        //check if future is already completed
        if (error.message.contains('Session invalidated by user')) {
          //Note: this catches NFC Error Msg with text "Bad State: Future already completed" and ignores it. This occurs when user scans very quickly in succession. Does not affect app functionality.
          return;
        } else {
          completer.completeError(error);
        }
      },
      alertMessage: alertMessage,
      onDiscovered: (NfcTag tag) async {
        try {
          NFCPlatform nfc = NFCPlatform(tag);

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
          sendAnalyticsTrace(sessionId, '', analyticsType,
              tags: {"chipWallet": createFirstKeyChipResponse[0].hex});
        } catch (e, stackTrace) {
          String errorMessage = e.toString();
          print(errorMessage);
          if (errorMessage.contains('Tag response error / no response') ||
              errorMessage.contains('Tag was lost.')) {
            errorMessage = context.loc.pleaseHoldPhoneLonger;
          }
          if (errorMessage.contains('RangeError')) {
            errorMessage = context.loc.unableToReadChip;
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
          sendAnalyticsTrace(sessionId, "$e", "SCAN_ERROR");
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
