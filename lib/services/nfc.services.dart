// ignore_for_file: use_build_context_synchronously

//import packages
import 'dart:async';
import 'dart:convert';
import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nfc_manager/nfc_manager.dart';
import 'package:ownerchip_whitelabel/config/constants.dart';
import 'package:ownerchip_whitelabel/config/ownercard.dart';
import 'package:ownerchip_whitelabel/config/wallets.dart';
import 'package:ownerchip_whitelabel/domain/classDefinition.dart';
import 'package:ownerchip_whitelabel/domain/jwt/jwt_token.dart';

//import screens
import 'package:ownerchip_whitelabel/screens/ChainSelectorScreen.dart';
import 'package:ownerchip_whitelabel/screens/metadataInput/MetadataInputScreen.dart';
import 'package:ownerchip_whitelabel/screens/PinScreen.dart';
import 'package:ownerchip_whitelabel/screens/UserScanResultsScreen.dart';
import 'package:ownerchip_whitelabel/services/backend/app/backendApp.dart';
import 'package:ownerchip_whitelabel/services/backend/auth/backendAuth.dart';
import 'package:ownerchip_whitelabel/services/backend/backend.services.dart';
import 'package:ownerchip_whitelabel/services/backend/collection/backendCollection.dart';
import 'package:ownerchip_whitelabel/services/backend/customer/backendCustomer.dart';
import 'package:ownerchip_whitelabel/services/providers/chipData.dart';
import 'package:ownerchip_whitelabel/services/providers/collectionsData.dart';
import 'package:ownerchip_whitelabel/services/providers/creations/creationsNotifier.dart';
import 'package:ownerchip_whitelabel/services/providers/nftData.dart';
import 'package:ownerchip_whitelabel/services/providers/userData.dart';
import 'package:ownerchip_whitelabel/services/providers/walletconnectData.dart';
import 'package:ownerchip_whitelabel/services/providers/websocket/websocketNotifier.dart';

//import services
import 'package:ownerchip_whitelabel/services/secora.services.dart';
import 'package:ownerchip_whitelabel/services/signature.services.dart';
import 'package:ownerchip_whitelabel/services/wallet.services.dart';
import 'package:ownerchip_whitelabel/utils/localization.helper.dart';
import 'package:ownerchip_whitelabel/utils/logger.dart';

//import misc
import 'package:ownerchip_whitelabel/utils/navigationArguments.dart';
import 'package:ownerchip_whitelabel/utils/utils.dart';
import 'package:ownerchip_whitelabel/widgets/popups/AndroidNfcPopup.dart';
import 'package:ownerchip_whitelabel/widgets/popups/returnSnackBarWidget.dart';
import 'package:ownerchip_whitelabel/widgets/ui/appBar/AppBarAuthDropDown.dart';
import 'package:sentry/sentry.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:web3dart/credentials.dart';
import 'package:web3dart/crypto.dart';

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
      BackendApp.sendAnalyticsTrace(
          sessionId, chipWalletAddress, "CHIP_INITIALIZED");
    }

    EthereumAddress? firstPubKeyAddress;

    try {
      final firstPubKey = await getPubKeyN(nfc, 0x00);
      firstPubKeyAddress = OwnercardData.fromPubKeyZeros(firstPubKey);
    } catch (e) {
      // ignore as slot 0 is not initialized for chip or not supported
    }

    //set chip info data in provider
    setChipInfoProvider(
      ref,
      chipEthereumAddress,
      chipTokenId,
      firstPubKeyAddress: firstPubKeyAddress,
    );

    TokenChainAndCollection config =
        await ref.watch(findTokenProvider(chipTokenId).future);
    BlockchainCollectionList relevantCollections =
        await ref.watch(findAllMinterRolesProvider.future);

    //verify signature
    List verificationResult = await verifySignatureAuthenticity(
        nfc, sessionId, chipEthereumAddress, chipTokenId);
    Uint8List hashedMsg = verificationResult[0];
    MsgSignature signature = verificationResult[1];
    ref.read(chipSignatureDataProvider.notifier).setSignatureData(SignatureData(
          hashedMsg: hashedMsg,
          signature: signature,
          tokenId: chipTokenId,
        ));

    //TOKEN DOES NOT EXIST
    if (config.collectionId == zeroAddress) {
      BackendApp.sendAnalyticsTrace(sessionId, "", "SCAN_RESULT_NEGATIVE",
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
        Navigator.pushNamed(
          context,
          ChainSelectorScreen.routeName,
          arguments: MetadataInputScreenArguments(
            0,
            zeroAddress,
          ),
        );
      } else {
        int chainId = relevantCollections.collections.keys.first;
        Collection? collection =
            relevantCollections.collections[chainId]!.first;
        Navigator.pushNamed(context, MetadataScreen.routeName,
            arguments: MetadataInputScreenArguments(chainId, collection.id,
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

Future<dynamic> scanItem(
  WidgetRef ref,
  BuildContext context, {
  bool navigateToResultPage = true,
  bool navigateToTokenDoesNotExistPage = true,
  bool returnOnTokenDoesNotExist = false,
  bool navigateToTokenExistsPage = true,
  bool returnOnTokenExists = false,
  void Function(String)? onTokenExists,
}) async {
  Future callback(NFCPlatform nfc, String sessionId,
      List createFirstKeyChipResponse) async {
    EthereumAddress chipEthereumAddress = createFirstKeyChipResponse[0];
    String chipWalletAddress = chipEthereumAddress.toString();
    BigInt chipTokenId = createFirstKeyChipResponse[1];

    TokenChainAndCollection config =
        await ref.watch(findTokenProvider(chipTokenId).future);

    EthereumAddress? firstPubKeyAddress;

    try {
      final firstPubKey = await getPubKeyN(nfc, 0x00);
      firstPubKeyAddress = OwnercardData.fromPubKeyZeros(firstPubKey);

      // if the card is a certificate card,
      // and its a minted token,
      // we authenticate it before proceeding
      if (config.minted &&
          OwnercardData.isCertificateCard(firstPubKeyAddress)) {
        setDeferredUserSession(ref);
        await authCardCallback(
          ref,
          context,
          nfc,
          await BackendAuth.getSessionId(),
          createFirstKeyChipResponse,
          pin: null,
        );
      }
    } catch (e) {
      // ignore as slot 0 is not initialized for chip or not supported
    }

    //set chip info data in provider
    setChipInfoProvider(
      ref,
      chipEthereumAddress,
      chipTokenId,
      firstPubKeyAddress: firstPubKeyAddress,
    );

    //verify signature
    try {
      List verificationResult = await verifySignatureAuthenticity(
          nfc, sessionId, chipEthereumAddress, chipTokenId);
      Uint8List hashedMsg = verificationResult[0];
      MsgSignature signature = verificationResult[1];
      ref
          .read(chipSignatureDataProvider.notifier)
          .setSignatureData(SignatureData(
            hashedMsg: hashedMsg,
            signature: signature,
            tokenId: chipTokenId,
          ));

      if (navigateToResultPage) {
        //TOKEN DOES NOT EXIST
        if (config.collectionId == zeroAddress) {
          if (navigateToTokenDoesNotExistPage) {
            BackendApp.sendAnalyticsTrace(sessionId, "", "SCAN_RESULT_NEGATIVE",
                tags: {"chipWallet": chipWalletAddress});

            Navigator.pushNamed(
              context,
              UserScanResultsScreen.routeName,
            );
          }

          if (returnOnTokenDoesNotExist) {
            return;
          }
        } else {
          //TOKEN EXISTS
          onTokenExists?.call(
            chipWalletAddress,
          );
          if (navigateToTokenExistsPage) {
            await verifyAuthenticity(config, chipEthereumAddress, hashedMsg,
                signature, sessionId, chipWalletAddress, context);

            Navigator.pushNamed(
              context,
              UserScanResultsScreen.routeName,
            ).then((_) {
              if (ref.read(userSessionProvider)?.isCertificateCard ?? false) {
                restoreDeferredUserSession(ref);
              }
            });
          }

          if (returnOnTokenExists) {
            return;
          }
        }
      } else {
        if (ref.read(userSessionProvider)?.isCertificateCard ?? false) {
          restoreDeferredUserSession(ref);
        }
      }
      return signature;
    } catch (e) {
      // check if wallet is connected
      if (ref.read(userSessionProvider)?.isCertificateCard ?? false) {
        restoreDeferredUserSession(ref);
      }

      if (navigateToResultPage &&
          ref.read(wcSessionProvider) == null &&
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

void setDeferredUserSession(WidgetRef ref) {
  final userSession = ref.read(userSessionProvider);
  final walletType = ref.read(walletTypeProvider);

  ref.read(deferredUserSessionProvider.notifier).state =
      DeferredUserSessionData(
    userSession: userSession,
    walletType: walletType,
  );
}

Future<void> restoreDeferredUserSession(WidgetRef ref) async {
  final DeferredUserSessionData? deferredUserSession =
      ref.read(deferredUserSessionProvider);
  if (deferredUserSession != null &&
      deferredUserSession.walletType?.type != EWalletType.certificateCard &&
      deferredUserSession.userSession != null) {
    ref.read(userAddressProvider.notifier).state =
        deferredUserSession.userSession?.userWalletAddress ?? zeroAddress;
    ref.read(userSessionProvider.notifier).state =
        deferredUserSession.userSession;
    ref.read(walletTypeProvider.notifier).state =
        deferredUserSession.walletType;
    Backend.recreateServices(deferredUserSession.userSession!.jwt.raw);
    ref.read(creationsNotifierProvider.notifier).load();
    ref.read(websocketProvider.notifier).init();
    //persist session date
    final SharedPreferences storage = await SharedPreferences.getInstance();
    storage.setString(
      'userSession',
      jsonEncode(deferredUserSession.userSession!.toJson()),
    );
    storage.setString(
      'walletType',
      jsonEncode(
        deferredUserSession.walletType!.toJson() ?? '{}',
      ),
    );
  } else {
    disconnectWallet(
      ref,
      ref.context,
    );
  }
}

void setChipInfoProvider(
    WidgetRef ref, EthereumAddress chipEthereumAddress, BigInt chipTokenId,
    {EthereumAddress? firstPubKeyAddress}) {
  ref
      .read(chipInfoProvider.notifier)
      .setChipEthereumAddress(chipEthereumAddress);
  ref.read(chipInfoProvider.notifier).setTokenId(chipTokenId);
  ref.read(chipInfoProvider.notifier).setChipToInitialized();
  ref.read(chipInfoProvider.notifier).setFirstSlotKey(
        firstPubKeyAddress,
      );
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

    BackendApp.sendAnalyticsTrace(sessionId, "", "SCAN_RESULT_POSITIVE",
        tags: {"chipWallet": chipWalletAddress});
  } catch (e) {
    //TOKEN IS NOT AUTHENTIC
    rethrow;
  }
}

/*GET SIGNATURE OF A MESSAGE/HASH FROM A CHIP WHICH IS NOT PIN LOCKED*/
Future<List<MsgSignature?>> getChipSignatures(
    WidgetRef ref,
    BuildContext context,
    List<dynamic> msgHashToSign,
    Function toggleLoading) async {
  Future callback(NFCPlatform nfc, String sessionId,
      List createFirstKeyChipResponse) async {
    EthereumAddress chipWalletAddress = createFirstKeyChipResponse[0];

    final List<MsgSignature?> signatures = [];

    for (final msgHash in msgHashToSign) {
      MsgSignature signature = await signHash(nfc, 0x01, chipWalletAddress,
          msgHash is Uint8List ? msgHash : hexToBytes(msgHash), true);
      signatures.add(signature);
    }

    return signatures;
  }

  return await scanClosure(context, ref, callback, "MAKE_CHIP_SIGNATURE",
      context.loc.holdPhoneToNfcChip);
}

/* GET SIGNATURE A MESSAGE/HASH FORM CARD*/
//returns MsgSignature if everything worked correctly
//returns null if user cancels scan or error occurs
Future<MsgSignature?> makeCardSignature(WidgetRef ref, BuildContext context,
    msgHashToSign, Function toggleLoading, String? pin) async {
  Future callback(NFCPlatform nfc, String sessionId,
      List createFirstKeyChipResponse) async {
    if (pin != null) {
      bool pinVerified = await verifyPin(nfc, pin);
    }
    EthereumAddress cardWalletAddress = createFirstKeyChipResponse[0];
    MsgSignature signature = await signHash(
        nfc,
        0x01,
        cardWalletAddress,
        msgHashToSign is Uint8List ? msgHashToSign : hexToBytes(msgHashToSign),
        false);
    return signature;
  }

  return await scanClosure(
      context,
      ref,
      callback,
      "MAKE_CARD_SIGNATURE",
      pin == null
          ? context.loc.holdPhoneCloseToCertificateCardToInit
          : context.loc.holdPhoneToCard);
}

Future authCardCallback(
  WidgetRef ref,
  BuildContext context,
  NFCPlatform nfc,
  String sessionId,
  List createFirstKeyChipResponse, {
  String? pin,
}) async {
  final firstPubKey = await getPubKeyN(nfc, 0x00);
  final address = OwnercardData.fromPubKeyZeros(firstPubKey);

  final bool isCertificateCard = OwnercardData.isCertificateCard(address);

  if (pin == null) {
    // check if the card is a certificate card
    if (!OwnercardData.isCertificateCard(address)) {
      throw context.loc.cardIsNotCertificateCard;
    }
  } else {
    // check if the card is an owner card
    if (!OwnercardData.isOwnerCard(address)) {
      throw context.loc.cardIsNotOwnerCard;
    }
  }

  final String message =
      "Sign this message to confirm that you are the owner of your wallet (SessionId: $sessionId)";

  final siweMessage = BackendAuth.createSiweMessage(
    address: createFirstKeyChipResponse[0],
    statement: message,
    nonce: sessionId,
  );

  final prefixedMessage =
      "\x19Ethereum Signed Message:\n${siweMessage[1].length}${siweMessage[1]}";
  Uint8List msgHashToSign = keccakUtf8(prefixedMessage);
  if (pin != null) {
    await verifyPin(nfc, pin);
  }
  final EthereumAddress cardWalletAddress = createFirstKeyChipResponse[0];
  MsgSignature signature = await signHash(
    nfc,
    0x01,
    cardWalletAddress,
    msgHashToSign,
    false,
  );

  final rHex = signature.r.toRadixString(16).padLeft(64, '0');
  final sHex = signature.s.toRadixString(16).padLeft(64, '0');
  final vHex = signature.v.toRadixString(16).padLeft(2, '0');

  String? jwt = await BackendAuth.validateSiwe(
    message: siweMessage[0],
    signature: "0x$rHex$sHex$vHex",
  );

  try {
    JwtToken.decode(jwt);
  } catch (_) {
    talker.info("Invalid JWT, using old method to create session");
    // if the JWT is invalid, we use the old method to create session
    String message =
        "Sign this message to confirm that you are the owner of your wallet (SessionId: $sessionId)";
    Uint8List msgHashToSign = keccakUtf8(message);
    signature =
        await signHash(nfc, 0x01, cardWalletAddress, msgHashToSign, false);
    jwt = null;
  }
  await BackendAuth.saveUserSession(
    sessionId,
    cardWalletAddress,
    signature,
    ref,
    jwt,
    isCertificateCard,
  );
}

Future<void> authenticateCard(
  WidgetRef ref,
  BuildContext context, {
  String? pin,
}) async {
  Future callback(NFCPlatform nfc, String sessionId,
      List createFirstKeyChipResponse) async {
    return await authCardCallback(
      ref,
      context,
      nfc,
      sessionId,
      createFirstKeyChipResponse,
      pin: pin,
    );
  }

  return await scanClosure(
    context,
    ref,
    callback,
    "AUTHENTICATE_CARD",
    pin == null
        ? context.loc.holdPhoneCloseToCertificateCardToInit
        : context.loc.holdPhoneToCard,
  );
}

Future<String?> setPinOnCard(
    BuildContext context, WidgetRef ref, String pin) async {
  Future callback(NFCPlatform nfc, String sessionId,
      List createFirstKeyChipResponse) async {
    Uint8List pubKeyZero = await getPubKeyN(nfc, 0x00);

    final address = OwnercardData.fromPubKeyZeros(pubKeyZero);

    if (OwnercardData.isCertificateCard(address)) {
      throw context.loc.cannotSetPinOnCertificateCard;
    }

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
    Uint8List pubKeyZero = await getPubKeyN(nfc, 0x00);
    final address = OwnercardData.fromPubKeyZeros(pubKeyZero);
    if (OwnercardData.isCertificateCard(address)) {
      throw context.loc.cannotResetPinOnCertificateCard;
    }

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
      context.loc.transferToOwnerCardMessage);
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
      BackendApp.sendAnalyticsTrace(
          sessionId, chipWalletAddress, "CHIP_INITIALIZED");
    }

    //set chip info data in provider
    setChipInfoProvider(ref, chipEthereumAddress, chipTokenId);

    //verify signature
    List verificationResult = await verifySignatureAuthenticity(
        nfc, sessionId, chipEthereumAddress, chipTokenId);
    Uint8List hashedMsg = verificationResult[0];
    MsgSignature signature = verificationResult[1];
    ref.read(chipSignatureDataProvider.notifier).setSignatureData(SignatureData(
          hashedMsg: hashedMsg,
          signature: signature,
          tokenId: chipTokenId,
        ));

    final ChipInfoModel chipInfo = ref.read(chipInfoProvider);
    final TokenChainAndCollection tokenInfo =
        await ref.refresh(findTokenProvider(chipInfo.tokenId).future);
    SignatureData chipSignature = ref.read(chipSignatureDataProvider);

    final EthereumAddress chipAddress = createFirstKeyChipResponse[0];

    try {
      Uint8List pubKeyZero = await getPubKeyN(nfc, 0x00);

      final pubKeyZeroAddress = OwnercardData.fromPubKeyZeros(pubKeyZero);

      if (OwnercardData.isCertificateCard(pubKeyZeroAddress)) {
        throw context.loc.cannotCardLostOnCertificateCard;
      }
    } catch (e) {
      if (e is String) {
        rethrow;
      }
      // ignore as slot 0 is not initialized for chip
    }

    if (tokenInfo.collectionId != zeroAddress) {
      return await BackendCollection.sendCardLostToBackend(chipAddress,
          tokenInfo.collectionId, chipSignature, sessionId, email, name, telNr);
    } else {
      throw context.loc.tokenDoesNotExist;
    }
  }

  return await scanClosure(
      context, ref, callback, "CARD_LOST", context.loc.scanToTriggerCardLost);
}

Future<dynamic> importKeyToSlotZero(
  BuildContext context,
  WidgetRef ref,
  Function setStateCallback,
  String customerId, {
  required String cardBaseId,
  bool isCertificateCard = false,
  required String ocInternalPassword,
}) async {
  String identifier = generateCardIdentifier(
    int.parse(customerId),
    cardBaseId,
  );
  Uint8List seed = hexToBytes(identifier);

  Future callback(NFCPlatform nfc, String sessionId,
      List createFirstKeyChipResponse) async {
    var pubKeyZero;
    pubKeyZero = await getPubKeyN(nfc, 0x00);
    if (pubKeyZero.isEmpty) {
      await writeKeyToSlotZero(nfc, seed);
      pubKeyZero = await getPubKeyN(nfc, 0x00);
    }
    final res = await BackendCustomer.sendCardInitToBackend(
      customerId,
      createFirstKeyChipResponse[0],
      isCertificateCard,
      ocInternalPassword,
    );

    if (!res) {
      throw context.loc.errorSendingCardInitToBackend;
    }

    EthereumAddress cardWalletAddress =
        OwnercardData.fromPubKeyZeros(pubKeyZero);

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
    nfcOverlay.showNfcOverlay(context, alertMessage, () {
      NfcManager.instance.stopSession();
      completer.complete(null);
    });
  }

  NfcManager.instance.startSession(
      onError: (error) async {
        try {
          //check if future is already completed
          if (error.message.contains('Session invalidated by user')) {
            //Note: this catches NFC Error Msg with text "Bad State: Future already completed" and ignores it. This occurs when user scans very quickly in succession. Does not affect app functionality.
            completer.complete(null);
          } else {
            completer.completeError(error);
          }
        } catch (_) {
          //
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

          try {
            completer.complete(result);
          } catch (e) {
            //
          }

          stopNfcOniOSAndAndroid(nfcOverlay);
          scanProcess.finish();
          BackendApp.sendAnalyticsTrace(sessionId, '', analyticsType,
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
          BackendApp.sendAnalyticsTrace(sessionId, "$e", "SCAN_ERROR");
          scanProcess.throwable = e;
          scanProcess.status = const SpanStatus.deadlineExceeded();
          scanProcess.finish();
          await Sentry.captureException(
            e,
            stackTrace: stackTrace,
          );
          try {
            completer.complete(null);
          } catch (e) {
            //
          }
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

Future<void> preventRepeatedNFCScan(
  Function fun, {
  Duration delay = const Duration(seconds: 4),
  bool android = true,
  bool ios = false,
}) async {
  if (android && !Platform.isAndroid) {
    return fun();
  }

  if (ios && !Platform.isIOS) {
    return fun();
  }

  await NfcManager.instance.startSession(
      invalidateAfterFirstRead: false,
      onError: (error) async {
        talker.info("NFC Error: $error");
      },
      onDiscovered: (NfcTag tag) async {
        talker.info("NFC Tag discovered: $tag");
      });
  await Future.delayed(delay);

  final res = await fun();

  if (Platform.isAndroid) {
    await Future.delayed(const Duration(seconds: 2));
  }
  await NfcManager.instance.stopSession();

  return res;
}
