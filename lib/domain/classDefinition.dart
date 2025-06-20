import 'dart:convert';

import 'package:ownerchip_whitelabel/config/constants.dart';
import 'package:ownerchip_whitelabel/config/wallets.dart';
import 'package:ownerchip_whitelabel/domain/fcm/fcm_token.dart';
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
        'type': type.index,
      };

  WalletType.fromJson(Map<String, dynamic> json)
      : name = json['name'],
        iconUri = json['iconUri'],
        type = EWalletType.values[json['type']];
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
  final String controllerContract;
  final String openseaUrl;
  final String raribleUrl;
  final String raribleEnum;
  final String blockchainExplorerUrl;
  final String alchemyBaseUrl;
  final String? forwarderContract;
  final bool internal;

  BlockchainConfig({
    required this.networkName,
    required this.nativeTokenSymbol,
    required this.rpcUrl,
    required this.registryContract,
    required this.controllerContract,
    required this.openseaUrl,
    required this.raribleUrl,
    required this.raribleEnum,
    required this.blockchainExplorerUrl,
    required this.alchemyBaseUrl,
    this.forwarderContract,
    this.internal = false,
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

  final bool isCertificateCard;

  int get expiryDate => jwt.exp;

  late final JwtToken jwt;
  final FCMToken? fcmToken;

  UserSession(
    this.sessionId,
    this.signatureData,
    this.userWalletAddress,
    this.isOwnerCard,
    this.isCertificateCard,
    this.jwt,
    this.fcmToken,
  );

  Map<String, dynamic> toJson() => {
        'sessionId': sessionId,
        'signatureData': msgSignatureToJson(signatureData),
        'userWalletAddress': userWalletAddress.hex,
        'isOwnerCard': isOwnerCard,
        'isCertificateCard': isCertificateCard,
        'expiryDate': expiryDate.toString(),
        'jwt': jwt.toJson(),
        'fcmToken': fcmToken?.toJson() ?? null,
      };

  UserSession.fromJson(Map<String, dynamic> json)
      : sessionId = json['sessionId'],
        signatureData = msgSignatureFromJson(json['signatureData']),
        userWalletAddress = EthereumAddress.fromHex(json['userWalletAddress']),
        isOwnerCard = json['isOwnerCard'],
        isCertificateCard = json['isCertificateCard'],
        jwt = JwtToken.fromJson(json['jwt']),
        fcmToken = json['fcmToken'] != null
            ? FCMToken.fromJson(json['fcmToken'])
            : null;
}

class CreatorData {
  final String name;
  final String affiliation;
  final String email;
  final EthereumAddress walletAddress;
  final DateTime createdAt;
  final bool hasActiveOffer;
  final Token tokenForWhichCreatorDataWasRequested;

  const CreatorData({
    required this.name,
    required this.affiliation,
    required this.email,
    required this.walletAddress,
    required this.createdAt,
    required this.hasActiveOffer,
    required this.tokenForWhichCreatorDataWasRequested,
  });
}

class RaribleHashAndEncodedData {
  final String typedDataHash;
  final String encodedData;

  RaribleHashAndEncodedData(this.typedDataHash, this.encodedData);
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
