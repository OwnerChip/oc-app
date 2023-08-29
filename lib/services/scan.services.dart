// ignore_for_file: use_build_context_synchronously

//import packages
import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:ownerchip_whitelabel/screens/HomeScreen.dart';
import 'package:ownerchip_whitelabel/widgets/popups/AndroidNfcPopup.dart';
import 'package:ownerchip_whitelabel/widgets/popups/CustomPopup.dart';
import 'package:ownerchip_whitelabel/widgets/popups/returnSnackBarWidget.dart';
import 'package:ownerchip_whitelabel/widgets/ui/PukDisplay.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:web3dart/credentials.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nfc_manager/nfc_manager.dart';
import 'package:web3dart/crypto.dart';
import 'dart:io' show Platform;
import 'package:sentry/sentry.dart';

//import services
import 'package:ownerchip_whitelabel/services/nfc.services.dart';
import 'package:ownerchip_whitelabel/services/backend.services.dart';
import 'package:ownerchip_whitelabel/services/signature.services.dart';
import 'package:ownerchip_whitelabel/services/providers.services.dart';

//import screens
import 'package:ownerchip_whitelabel/screens/MetadataInputScreen.dart';
import 'package:ownerchip_whitelabel/screens/ChainSelectorScreen.dart';
import 'package:ownerchip_whitelabel/screens/UserScanResultsScreen.dart';

//import misc
import 'package:ownerchip_whitelabel/utils/navigationArguments.dart';
import 'package:ownerchip_whitelabel/utils/utils.dart';
import 'package:ownerchip_whitelabel/utils/localization.helper.dart';
import 'package:ownerchip_whitelabel/config/constants.dart';
import 'package:ownerchip_whitelabel/domain/classDefinition.dart';
import 'package:ownerchip_whitelabel/config/wallets.dart';

Future<void> initializeItem(WidgetRef ref, BuildContext context) async {
  UserSession? session = ref.read(userSessionProvider);
  String sessionId = session?.sessionId ?? makeRandomInt().toString();

  NFCOverlay nfcOverlay = NFCOverlay();

  //stop previoud NFC session if existing
  await NfcManager.instance.stopSession();

  //start NFC scan
  final scanProcess = Sentry.startTransaction('initScanning()', 'task');

  if (Platform.isAndroid) {
    nfcOverlay.showNfcOverlay(context, 'Hold your phone close to the NFC chip');
  }

  NfcManager.instance.startSession(
      alertMessage:
          'Hold phone near NFC chip to start creation of digital twin.',
      onDiscovered: (NfcTag tag) async {
        sendAnalyticsTrace(sessionId, "", "INITIALIZE_SCAN_STARTED");
        try {
          var nfc = NFCPlatform(tag);

          //check if iso7816 or isodep is available and exit if not
          await nfcPlatformCheck(context, sessionId, nfc);
          //initialize chip (including NDEF tag if existing)

          sendAnalyticsTrace(sessionId, "", "INITIALIZE_NDEF_START");

          List result = await createFirstKeypairOnChip(nfc, true, sessionId);
          EthereumAddress chipEthereumAddress = result[0];
          String chipWalletAddress = chipEthereumAddress.toString();
          BigInt chipTokenId = result[1];
          bool ndefTagInitialized = result[2];
          if (ndefTagInitialized) {
            sendAnalyticsTrace(
                sessionId, chipWalletAddress, "CHIP_INITIALIZED");
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

          //stop NFC session if iOS, Android nfc Session is stopped later to block NDEF read for longer
          if (Platform.isIOS) {
            NfcManager.instance.stopSession();
          }

          if (Platform.isAndroid) {
            nfcOverlay.removeNfcOverlay();
          }

          //TOKEN DOES NOT EXIST
          if (config.collectionId == zeroAddress) {
            scanProcess.finish();
            sendAnalyticsTrace(sessionId, "", "SCAN_RESULT_NEGATIVE",
                tags: {"chipWallet": chipWalletAddress});

            //TODO: WHY DO I PASS METADATAScreen Arguments t o ChainSelectorScreen??
            Navigator.pushNamed(context, ChainSelectorScreen.routeName,
                arguments:
                    MetadataInputScreenArguments(sessionId, 0, zeroAddress));
          }
          //TOKEN EXISTS
          else {
            await verifyAuthenticity(config, chipEthereumAddress, hashedMsg,
                signature, scanProcess, sessionId, chipWalletAddress, context);

            Navigator.pushNamed(
              context,
              UserScanResultsScreen.routeName,
            );
          }
          // delay to block NDEF read/popup on Android
          if (Platform.isAndroid) {
            await Future.delayed(const Duration(seconds: 2));
            NfcManager.instance.stopSession();
          }
        } catch (e, stackTrace) {
          // send Error to analytics
          sendAnalyticsTrace(sessionId, "$e", "INIALIZE_SCAN_ERROR");
          print(e);
          scanProcess.throwable = e;
          scanProcess.status = const SpanStatus.deadlineExceeded();
          scanProcess.finish();
          await Sentry.captureException(
            e,
            stackTrace: stackTrace,
          );
          //error reading chip
          NfcManager.instance.stopSession();
          if (Platform.isAndroid) {
            nfcOverlay.removeNfcOverlay();
          }
          ScaffoldMessenger.of(context).showSnackBar(
            returnSnackBarWidget(context.loc.errorHeadingSnackBar,
                context.loc.nfcError, 'error'),
          );
        }
      });
}

Future<void> scanItem(WidgetRef ref, BuildContext context) async {
  UserSession? session = ref.read(userSessionProvider);
  String sessionId = session?.sessionId ?? makeRandomInt().toString();

  NFCOverlay nfcOverlay = NFCOverlay();

  //stop previoud NFC session if existing
  await NfcManager.instance.stopSession();
  //start NFC scan
  final scanProcess = Sentry.startTransaction('initScanning()', 'task');

  if (Platform.isAndroid) {
    //show NFC popup
    nfcOverlay.showNfcOverlay(context, 'Hold your phone close to the NFC chip');
  }
  NfcManager.instance.startSession(
      alertMessage: 'Hold phone near NFC tag to scan item.',
      onDiscovered: (NfcTag tag) async {
        sendAnalyticsTrace(sessionId, "", "SCAN_STARTED");
        try {
          var nfc = NFCPlatform(tag);

          //check if iso7816 or isodep is available and exit if not
          await nfcPlatformCheck(context, sessionId, nfc);

          //create first keypair if not existing
          List result = await createFirstKeypairOnChip(nfc, false, sessionId);
          EthereumAddress chipEthereumAddress = result[0];
          String chipWalletAddress = chipEthereumAddress.toString();
          BigInt chipTokenId = result[1];

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

          //stop NFC session if iOS, Android nfc Session is stopped later to block NDEF read for longer
          if (Platform.isIOS) {
            NfcManager.instance.stopSession();
          }

          if (Platform.isAndroid) {
            nfcOverlay.removeNfcOverlay();
          }

          //TOKEN DOES NOT EXIST
          if (config.collectionId == zeroAddress) {
            scanProcess.finish();
            sendAnalyticsTrace(sessionId, "", "SCAN_RESULT_NEGATIVE",
                tags: {"chipWallet": chipWalletAddress});

            Navigator.pushNamed(
              context,
              UserScanResultsScreen.routeName,
            );
          } else {
            //TOKEN EXISTS
            await verifyAuthenticity(config, chipEthereumAddress, hashedMsg,
                signature, scanProcess, sessionId, chipWalletAddress, context);

            Navigator.pushNamed(
              context,
              UserScanResultsScreen.routeName,
            );
          }
          // delay to block NDEF read/popup on Android
          if (Platform.isAndroid) {
            await Future.delayed(const Duration(seconds: 2));
            NfcManager.instance.stopSession();
          }
        } catch (e, stackTrace) {
          // send Error to analytics
          sendAnalyticsTrace(sessionId, "$e", "SCAN_ERROR");
          print(e);
          scanProcess.throwable = e;
          scanProcess.status = const SpanStatus.deadlineExceeded();
          scanProcess.finish();
          await Sentry.captureException(
            e,
            stackTrace: stackTrace,
          );
          //error reading chip
          NfcManager.instance.stopSession();

          if (Platform.isAndroid) {
            nfcOverlay.removeNfcOverlay();
          }

          ScaffoldMessenger.of(context).showSnackBar(
            returnSnackBarWidget(context.loc.errorHeadingSnackBar,
                context.loc.nfcError, 'error'),
          );
        }
      });
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
    ISentrySpan scanProcess,
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

    scanProcess.finish();
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
  MsgSignature? signature;
  NFCOverlay nfcOverlay = NFCOverlay();

  String sessionId = ref.read(userSessionProvider) != null
      ? ref.read(userSessionProvider)!.sessionId
      : makeRandomInt().toString();

  //create a completer to return a future
  Completer<MsgSignature?> completer = Completer();

  //start NFC scan
  Sentry.startTransaction('makeCardSignature()', 'task');
  try {
    if (Platform.isAndroid) {
      nfcOverlay.showNfcOverlay(
          context, 'Hold your phone close to your OwnerCard.');
    }

    NfcManager.instance.startSession(
        onError: (error) => toggleLoading(),
        alertMessage: 'Hold phone near OwnerCard to sign transaction.',
        onDiscovered: (NfcTag tag) async {
          var nfc = NFCPlatform(tag);

          //check if iso7816 or isodep is available and exit if not
          await nfcPlatformCheck(context, sessionId, nfc);

          //create first key if not existing
          List result = await createFirstKeypairOnChip(nfc, false, sessionId);
          EthereumAddress cardWalletAddress = result[0];

          //verify pin
          bool pinVerified = await verifyPin(nfc, pin);

          //get chip signature
          signature = await signHash(
              nfc, 0x01, cardWalletAddress, hexToBytes(msgHashToSign), false);

          //stop NFC session if iOS, Android nfc Session is stopped later to block NDEF read for longer
          if (Platform.isIOS) {
            NfcManager.instance.stopSession();
          }

          if (Platform.isAndroid) {
            nfcOverlay.removeNfcOverlay();
            await Future.delayed(const Duration(milliseconds: 1500));
            NfcManager.instance.stopSession();
          }

          //complete the future with the signature
          completer.complete(signature);
        });
    //return the future from the completer
    return completer.future;
  } catch (e) {
    print(e);
    NfcManager.instance.stopSession();
    if (Platform.isAndroid) {
      nfcOverlay.removeNfcOverlay();
    }

    //show error snackbar
    ScaffoldMessenger.of(context).showSnackBar(returnSnackBarWidget(
        context.loc.errorHeadingSnackBar, 'Error making signature.', 'error'));

    //complete the future with null
    completer.complete(null);
    return completer.future;
  }
}

Future<void> authenticateCard(
    WidgetRef ref, BuildContext context, String pin) async {
//stop previoud NFC session if existing
  await NfcManager.instance.stopSession();

  //start NFC scan
  Sentry.startTransaction('authenticateCard()', 'task');
  NFCOverlay nfcOverlay = NFCOverlay();
  if (Platform.isAndroid) {
    nfcOverlay.showNfcOverlay(
        context, 'Hold your phone close to your OwnerCard.');
  }

  NfcManager.instance.startSession(
      onError: (error) async {
        if (Platform.isAndroid) {
          nfcOverlay.removeNfcOverlay();
        }
        //show error snackbar
        ScaffoldMessenger.of(context).showSnackBar(returnSnackBarWidget(
            context.loc.errorHeadingSnackBar,
            'Error authenticating card.',
            'error'));
        print(error);
      },
      alertMessage: 'Hold phone near OwnerCard sign in.',
      onDiscovered: (NfcTag tag) async {
        try {
          var nfc = NFCPlatform(tag);

          String sessionId = await getSessionId();
          String message =
              "Sign this message to confirm that you are the owner of your wallet (SessionId: $sessionId)";
          Uint8List msgHashToSign = keccakUtf8(message);

          //check if iso7816 or isodep is available and exit if not
          await nfcPlatformCheck(context, sessionId, nfc);

          //create first key if not existing
          List result = await createFirstKeypairOnChip(nfc, false, sessionId);
          EthereumAddress cardWalletAddress = result[0];

          //verify pin
          bool pinVerified = await verifyPin(nfc, pin);

          //get chip signature
          MsgSignature signature = await signHash(
              nfc, 0x01, cardWalletAddress, msgHashToSign, false);

          if (Platform.isIOS) {
            NfcManager.instance.stopSession();
          }
          if (Platform.isAndroid) {
            nfcOverlay.removeNfcOverlay();
          }

          await saveUserSession(sessionId, cardWalletAddress, signature, ref);

          if (Platform.isAndroid) {
            await Future.delayed(const Duration(seconds: 2));
            NfcManager.instance.stopSession();
          }
        } catch (e) {
          NfcManager.instance.stopSession();
          if (Platform.isAndroid) {
            nfcOverlay.removeNfcOverlay();
          }
          //show error snackbar
          ScaffoldMessenger.of(context).showSnackBar(returnSnackBarWidget(
              context.loc.errorHeadingSnackBar,
              'Error authenticating card.',
              'error'));

          print(e);
        }
      });
}

// PIN CODE
Future<String?> setPinOnCard(BuildContext context, String pin) async {
//stop previoud NFC session if existing
  await NfcManager.instance.stopSession();

  //start NFC scan
  Sentry.startTransaction('setPinOnCard()', 'task');
  NFCOverlay nfcOverlay = NFCOverlay();
  if (Platform.isAndroid) {
    nfcOverlay.showNfcOverlay(
        context, 'Hold your phone close to your OwnerCard.');
  }
  String? puk;
  NfcManager.instance.startSession(
      alertMessage: 'Hold phone near OwnerCard sign in.',
      onDiscovered: (NfcTag tag) async {
        try {
          var nfc = NFCPlatform(tag);

          String sessionId = makeRandomInt().toString();

          //check if iso7816 or isodep is available and exit if not
          await nfcPlatformCheck(context, sessionId, nfc);

          //create first key if not existing
          List result = await createFirstKeypairOnChip(nfc, false, sessionId);
          EthereumAddress cardWalletAddress = result[0];

          puk = await setPin(nfc, pin);

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
          showCustomPopup(context, 'Save your PUK', PukDisplay(puk: '1234'));
        } catch (e) {
          NfcManager.instance.stopSession();
          if (Platform.isAndroid) {
            nfcOverlay.removeNfcOverlay();
          }
          // ScaffoldMessenger.of(context).showSnackBar(returnSnackBarWidget(
          //     context.loc.errorHeadingSnackBar,
          //     'Error setting card pin.',
          //     'error'));
          print(e);
        }
      });
  return puk;
}

Future<void> resetPinOnCard(WidgetRef ref, context, String puk) async {
  //stop previoud NFC session if existing
  await NfcManager.instance.stopSession();

  // get user session & connected wallet
  final session = ref.read(userSessionProvider);
  String connectedWallet = session?.userWalletAddress.toString() ?? "";
  String sessionId = session?.sessionId ?? "";

  //start NFC scan
  Sentry.startTransaction('setPinOnCard()', 'task');
  NFCOverlay nfcOverlay = NFCOverlay();
  if (Platform.isAndroid) {
    nfcOverlay.showNfcOverlay(context, 'Hold your phone near OwnerCard.');
  }
  NfcManager.instance.startSession(
      alertMessage: 'Hold phone near OwnerCard.',
      onDiscovered: (NfcTag tag) async {
        try {
          var nfc = NFCPlatform(tag);

          String sessionId = makeRandomInt().toString();

          //check if iso7816 or isodep is available and exit if not
          await nfcPlatformCheck(context, sessionId, nfc);

          //create first key if not existing
          List result = await createFirstKeypairOnChip(nfc, false, sessionId);
          EthereumAddress cardWalletAddress = result[0];

          bool success = await unlockPin(nfc, puk);

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
          ScaffoldMessenger.of(context).showSnackBar(returnSnackBarWidget(
              context.loc.errorHeadingSnackBar,
              'Old PIN removed. Please set a new PIN.',
              'success'));
          sendAnalyticsTrace(sessionId, "", "RESET_PIN_SUCCESS", tags: {
            'connectedWallet': connectedWallet,
            'connectedCard': cardWalletAddress.toString()
          });
        } catch (e) {
          NfcManager.instance.stopSession();
          if (Platform.isAndroid) {
            nfcOverlay.removeNfcOverlay();
          }
          ScaffoldMessenger.of(context).showSnackBar(returnSnackBarWidget(
              context.loc.errorHeadingSnackBar,
              'Error resetting puk.',
              'error'));

          sendAnalyticsTrace(sessionId, e.toString(), "RESET_PIN_ERROR",
              tags: {'connectedWallet': connectedWallet});
          print(e);
        }
      });
}
