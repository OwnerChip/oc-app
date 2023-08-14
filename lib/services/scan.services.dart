// ignore_for_file: use_build_context_synchronously

//import packages
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:ownerchip_whitelabel/screens/HomeScreen.dart';
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

//import widgets
import 'package:ownerchip_whitelabel/widgets/ui/returnSnackBarWidget.dart';

//import misc
import 'package:ownerchip_whitelabel/utils/navigationArguments.dart';
import 'package:ownerchip_whitelabel/utils/utils.dart';
import 'package:ownerchip_whitelabel/utils/localization.helper.dart';
import 'package:ownerchip_whitelabel/config/constants.dart';
import 'package:ownerchip_whitelabel/domain/classDefinition.dart';

Future<void> initializeItem(WidgetRef ref, BuildContext context) async {
  // this random # is used as analytics trace id, case id and session id
  String sessionIdFromServer = await getSessionId();
  String sessionId = sessionIdFromServer != ""
      ? sessionIdFromServer
      : makeRandomInt().toString();

  //stop previoud NFC session if existing
  await NfcManager.instance.stopSession();

  //start NFC scan
  final scanProcess = Sentry.startTransaction('initScanning()', 'task');
  NfcManager.instance.startSession(onDiscovered: (NfcTag tag) async {
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

      //stop NFC session if iOS, Android nfc Session is stopped later to block NDEF read for longer
      if (Platform.isIOS) {
        NfcManager.instance.stopSession();
      }

      //TOKEN DOES NOT EXIST
      if (config.collectionId == zeroAddress) {
        scanProcess.finish();
        sendAnalyticsTrace(sessionId, "", "SCAN_RESULT_NEGATIVE",
            tags: {"chipWallet": chipWalletAddress});

        //TODO: WHY DO I PASS METADATAScreen Arguments t o ChainSelectorScreen??
        Navigator.pushNamed(context, ChainSelectorScreen.routeName,
            arguments: MetadataInputScreenArguments(sessionId, 0, zeroAddress));
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
      if (!Platform.isIOS) {
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
      ScaffoldMessenger.of(context).showSnackBar(
        returnSnackBarWidget(
            context.loc.errorHeadingSnackBar, context.loc.nfcError, 'error'),
      );
    }
  });
}

Future<void> scanItem(WidgetRef ref, BuildContext context) async {
  // this random # is used as analytics trace id, case id and session id
  String sessionIdFromServer = await getSessionId();
  String sessionId = sessionIdFromServer != ""
      ? sessionIdFromServer
      : makeRandomInt().toString();

  //stop previoud NFC session if existing
  await NfcManager.instance.stopSession();
  //start NFC scan
  final scanProcess = Sentry.startTransaction('initScanning()', 'task');
  NfcManager.instance.startSession(onDiscovered: (NfcTag tag) async {
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
      if (!Platform.isIOS) {
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
      ScaffoldMessenger.of(context).showSnackBar(
        returnSnackBarWidget(
            context.loc.errorHeadingSnackBar, context.loc.nfcError, 'error'),
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
Future<MsgSignature?> makeCardSignature(
    WidgetRef ref, BuildContext context) async {
  MsgSignature? signature;

  final navArgs =
      ModalRoute.of(context)!.settings.arguments as ScanningScreenArguments;

  //if user is int he process of authentication, msgToSign is the sessionId, else a backendsession already exists
  //and sessionId is taken from backendSessionProvider
  String sessionId = navArgs.isAuthSign != null && navArgs.isAuthSign!
      ? navArgs.sessionId!
      : ref.read(backendSessionProvider)!.sessionId;

  //stop previoud NFC session if existing
  await NfcManager.instance.stopSession();

  //start NFC scan
  Sentry.startTransaction('makeCardSignature()', 'task');
  try {
    NfcManager.instance.startSession(onDiscovered: (NfcTag tag) async {
      var nfc = NFCPlatform(tag);

      //check if iso7816 or isodep is available and exit if not
      await nfcPlatformCheck(context, sessionId, nfc);

      //create first key if not existing
      List result = await createFirstKeypairOnChip(nfc, false, sessionId);
      EthereumAddress cardWalletAddress = result[0];

      //get chip signature
      signature =
          await signHash(nfc, 0x01, cardWalletAddress, navArgs.msgHashToSign!);

      NfcManager.instance.stopSession();

      // if (navArgs.isAuthSign != null && navArgs.isAuthSign!) {
      //   await saveBackendSession(
      //       sessionId, cardWalletAddress, signature, ref);
      // } else {
      //   ChipInfoModel chipInfo = ref.read(chipInfoProvider);
      //   TokenInfoObject tokenInfo =
      //       await ref.read(findTokenProvider(chipInfo.tokenId).future);
      //   //TODO: send transaction to blockchain
      //   //check if user is allowed to use gas station
      //   final List response =
      //       await checkMetaTx(tokenInfo.collectionId, gaslessMintFunctionSignature);
      //   final bool canUseGasStation = response[0];
      //   final metaTxAgreementId = response[1];
      //   String txnHash = await sendGaslessRequest(
      //       tokenInfo.collectionId, msgSignatureToHex(signature), metaTxAgreementId, request);
      // }
    });
  } catch (e) {
    print(e);
    NfcManager.instance.stopSession();

    //show error snackbar
    ScaffoldMessenger.of(context).showSnackBar(returnSnackBarWidget(
        context.loc.errorHeadingSnackBar,
        'Error connecting smart card.',
        'error'));
  }
  return signature;
}

Future<void> authenticateCard(WidgetRef ref, BuildContext context) async {
//stop previoud NFC session if existing
  await NfcManager.instance.stopSession();

  //start NFC scan
  Sentry.startTransaction('makeCardSignature()', 'task');
  try {
    NfcManager.instance.startSession(onDiscovered: (NfcTag tag) async {
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

      //get chip signature
      MsgSignature signature =
          await signHash(nfc, 0x01, cardWalletAddress, msgHashToSign);

      NfcManager.instance.stopSession();

      await saveBackendSession(sessionId, cardWalletAddress, signature, ref);
    });
  } catch (e) {
    print(e);
  }
}

Future<void> saveBackendSession(
    String sessionId,
    EthereumAddress cardWalletAddress,
    MsgSignature signature,
    WidgetRef ref) async {
  int sevenDaysInSeconds = 60 * 60 * 24 * 7;
  int sessionExpirationDate = await getSessionExpiration(
      sevenDaysInSeconds, sessionId, cardWalletAddress, signature);

  BackendSession backendSession = BackendSession(sessionId, signature,
      ref.read(userAddressProvider), sessionExpirationDate);

  ref.read(backendSessionProvider.notifier).state = backendSession;

  //persist session date
  final SharedPreferences storage = await SharedPreferences.getInstance();
  final String jsonBackendSession = jsonEncode(backendSession.toJson());
  storage.setString('backendSession', jsonBackendSession);
}
