import 'dart:convert';

import 'package:ownerchip_whitelabel/config/constants.dart';
import 'package:ownerchip_whitelabel/config/wallets.dart';
import 'package:ownerchip_whitelabel/domain/jwt/jwt_token.dart';
import 'package:ownerchip_whitelabel/domain/tokenTypes.dart';
import 'package:ownerchip_whitelabel/services/signature.services.dart';
import 'package:ownerchip_whitelabel/utils/logger.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:web3dart/web3dart.dart';
import 'package:flutter/services.dart';
import 'package:web3dart/crypto.dart';

class MoreInfoButton {
  final String text;
  final String url;

  MoreInfoButton(this.text, this.url);
}

class WalletType {
  final String name;
  final String iconUri;

  final EWalletType type;

  WalletType(
    this.name,
    this.iconUri,
    this.type,
  );

  Map<String, dynamic> toJson() => {
        'name': name,
        'iconUri': iconUri,
        'type': type.name,
      };

  WalletType.fromJson(Map<String, dynamic> json)
      : name = json['name'],
        iconUri = json['iconUri'],
        type = parseWalletTypeJson(json['type']);
}

/// Thrown when a persisted session references a wallet type this build no
/// longer supports. Callers are expected to treat this as "clear the session".
class StaleWalletTypeException implements Exception {
  final Object? value;

  const StaleWalletTypeException(this.value);

  @override
  String toString() => 'StaleWalletTypeException: unsupported wallet type '
      '"$value" — persisted by an older build';
}

/// Reads a persisted wallet type.
///
/// Accepts the current name form (`'ownerCard'`) and the legacy index form
/// (`0`) that older builds wrote. Anything unrecognised — including the
/// indices of wallet types this build dropped — raises
/// [StaleWalletTypeException] rather than an unhandled RangeError.
EWalletType parseWalletTypeJson(Object? raw) {
  if (raw is String) {
    for (final t in EWalletType.values) {
      if (t.name == raw) return t;
    }
    throw StaleWalletTypeException(raw);
  }
  if (raw is int) {
    if (raw < 0 || raw >= EWalletType.values.length) {
      throw StaleWalletTypeException(raw);
    }
    return EWalletType.values[raw];
  }
  throw StaleWalletTypeException(raw);
}

class Collection {
  final EthereumAddress id;
  final String name;
  final EthereumAddress? voucherAddress;
  final String? symbol;
  final int? chainId;
  bool? hasMinterRole;

  Collection(this.id, this.name,
      {this.voucherAddress, this.symbol, this.chainId, this.hasMinterRole});
}

class BlockchainCollectionList {
  final Map<int, List<Collection>> collections;
  bool? hasAnyMinterRole;

  BlockchainCollectionList(this.collections, {this.hasAnyMinterRole});
}

class BlockchainConfig {
  final String networkName;
  final String nativeTokenSymbol;
  final String rpcUrl;
  final String registryContract;
  final String openseaUrl;
  final String blockchainExplorerUrl;
  final String alchemyBaseUrl;

  BlockchainConfig({
    required this.networkName,
    required this.nativeTokenSymbol,
    required this.rpcUrl,
    required this.registryContract,
    required this.openseaUrl,
    required this.blockchainExplorerUrl,
    required this.alchemyBaseUrl,
  });
}

class TokenChainAndCollection {
  final int chainId;
  final EthereumAddress collectionId;
  final BigInt tokenId;

  bool get minted => chainId != 0 && collectionId != zeroAddress;

  TokenChainAndCollection(this.chainId, this.collectionId, this.tokenId);
}

class ChipInfoModel {
  ChipInfoModel({
    required this.chipEthereumAddress,
    required this.tokenId,
    required this.firstSlotKey,
    this.chipIsInitialized = false,
  });

  EthereumAddress chipEthereumAddress;
  BigInt tokenId;
  EthereumAddress firstSlotKey;
  bool chipIsInitialized;
}

class SignatureData {
  Uint8List hashedMsg;
  MsgSignature signature;

  BigInt tokenId;

  bool hasBeenUsedInSmartContract;

  SignatureData(
      {required this.hashedMsg,
      required this.signature,
      required this.tokenId ,
      this.hasBeenUsedInSmartContract = false});
}

enum WCSignType {
  message,
  personalMessage,
  typedMessageV2,
  typedMessageV3,
  typedMessageV4,
}

class EthereumSignMessage {
  final String data;
  final String address;
  final WCSignType type;

  const EthereumSignMessage({
    required this.data,
    required this.address,
    required this.type,
  });
}

enum AttachmentType { text, audio, image, video, url, other }

class Attachment {
  final String title; //file title set by user
  final String fileName; //file name including file extension
  final AttachmentType type;
  final bool isPrivate;
  final String url;
  final String backendUuid;
  final bool? isFromCreator;



  bool isContentEqual(Attachment orig) {
    return title == orig.title &&
        fileName == orig.fileName &&
        type == orig.type &&
        isPrivate == orig.isPrivate &&
        url == orig.url &&
        backendUuid == orig.backendUuid &&
        isFromCreator == orig.isFromCreator;
  }

  Attachment copyWith({
    String? title,
    String? fileName,
    AttachmentType? type,
    bool? isPrivate,
    String? url,
    String? backendUuid,
    bool? isFromCreator,
  }) {
    return Attachment(
      title: title ?? this.title,
      fileName: fileName ?? this.fileName,
      type: type ?? this.type,
      isPrivate: isPrivate ?? this.isPrivate,
      url: url ?? this.url,
      backendUuid: backendUuid ?? this.backendUuid,
      isFromCreator: isFromCreator ?? this.isFromCreator,
    );
  }

  const Attachment({
    required this.title,
    required this.fileName,
    required this.type,
    required this.isPrivate,
    required this.url,
    required this.backendUuid,
    this.isFromCreator,
  });
}

class UserSession {
  final String sessionId;
  final MsgSignature signatureData;
  final EthereumAddress userWalletAddress;
  final bool isOwnerCard;

  int get expiryDate => jwt.exp;

  late final JwtToken jwt;

  UserSession(
    this.sessionId,
    this.signatureData,
    this.userWalletAddress,
    this.isOwnerCard,
    this.jwt,
  );

  Map<String, dynamic> toJson() => {
        'sessionId': sessionId,
        'signatureData': msgSignatureToJson(signatureData),
        'userWalletAddress': userWalletAddress.hex,
        'isOwnerCard': isOwnerCard,
        'expiryDate': expiryDate.toString(),
        'jwt': jwt.toJson(),
      };

  UserSession.fromJson(Map<String, dynamic> json)
      : sessionId = json['sessionId'],
        signatureData = msgSignatureFromJson(json['signatureData']),
        userWalletAddress = EthereumAddress.fromHex(json['userWalletAddress']),
        isOwnerCard = json['isOwnerCard'],
        jwt = JwtToken.fromJson(json['jwt']);
}

class CreatorData {
  final String name;
  final String affiliation;
  final String email;
  final EthereumAddress walletAddress;
  final DateTime createdAt;
  final Token tokenForWhichCreatorDataWasRequested;

  const CreatorData({
    required this.name,
    required this.affiliation,
    required this.email,
    required this.walletAddress,
    required this.createdAt,
    required this.tokenForWhichCreatorDataWasRequested,
  });
}

typedef StringCallback = Function(String?);
typedef VoidStringCallback = void Function(String);

class InputFieldModel {
  final String? placeholder;
  final TextInputType? keyboardType;
  final VoidStringCallback setStateCallback;
  final StringCallback validator;

  InputFieldModel({
    this.placeholder = '',
    this.keyboardType = TextInputType.text,
    required this.setStateCallback,
    required this.validator,
  });
}
