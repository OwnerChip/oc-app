import 'package:ownerchip_whitelabel/config/wallets.dart';
import 'package:ownerchip_whitelabel/domain/tokenTypes.dart';
import 'package:ownerchip_whitelabel/services/signature.services.dart';
import 'package:walletconnect_flutter_v2/walletconnect_flutter_v2.dart';
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

  BlockchainConfig(
      {required this.networkName,
      required this.nativeTokenSymbol,
      required this.rpcUrl,
      required this.registryContract,
      required this.controllerContract,
      required this.openseaUrl,
      required this.raribleUrl,
      required this.raribleEnum,
      required this.blockchainExplorerUrl,
      required this.alchemyBaseUrl,
      this.forwarderContract});
}

class TokenChainAndCollection {
  final int chainId;
  final EthereumAddress collectionId;
  final BigInt tokenId;

  TokenChainAndCollection(this.chainId, this.collectionId, this.tokenId);
}

class ChipInfoModel {
  ChipInfoModel(
      {required this.chipEthereumAddress,
      required this.tokenId,
      this.chipIsInitialized = false});

  EthereumAddress chipEthereumAddress;
  BigInt tokenId;
  bool chipIsInitialized;
}

class SignatureData {
  Uint8List hashedMsg;
  MsgSignature signature;
  bool hasBeenUsedInSmartContract;

  SignatureData(
      {required this.hashedMsg,
      required this.signature,
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

  Attachment(this.title, this.fileName, this.type, this.url, this.backendUuid,
      {this.isPrivate = false, this.isFromCreator});
}

class UserSession {
  final String sessionId;
  final MsgSignature signatureData;
  final EthereumAddress userWalletAddress;
  final bool isOwnerCard;
  final int expiryDate;
  final String jwt;

  UserSession(
    this.sessionId,
    this.signatureData,
    this.userWalletAddress,
    this.isOwnerCard,
    this.expiryDate,
    this.jwt,
  );

  Map<String, dynamic> toJson() => {
        'sessionId': sessionId,
        'signatureData': msgSignatureToJson(signatureData),
        'userWalletAddress': userWalletAddress.hex,
        'isOwnerCard': isOwnerCard,
        'expiryDate': expiryDate.toString(),
        'jwt': jwt,
      };

  UserSession.fromJson(Map<String, dynamic> json)
      : sessionId = json['sessionId'],
        signatureData = msgSignatureFromJson(json['signatureData']),
        userWalletAddress = EthereumAddress.fromHex(json['userWalletAddress']),
        isOwnerCard = json['isOwnerCard'],
        expiryDate = int.parse(
          json['expiryDate'],
        ),
        jwt = json['jwt'];
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

class OfferItemInputData {
  final String tokenId;
  final String offerPrice;
  final String offerCurrency;
  final String sellerWalletAddress;
  final String sellerPayoutAddress;
  final String sellerEmail;
  final int validUntil;
  final String salt;
  final String encodedData;
  final String typedDataHash;
  final String chipSignature;
  final String marketplaceContract;
  final String offchainOfferId;

  const OfferItemInputData(
      {required this.tokenId,
      required this.offerPrice,
      required this.offerCurrency,
      required this.sellerWalletAddress,
      required this.sellerPayoutAddress,
      required this.sellerEmail,
      required this.validUntil,
      required this.salt,
      required this.encodedData,
      required this.typedDataHash,
      required this.chipSignature,
      required this.marketplaceContract,
      required this.offchainOfferId});

  Map<String, dynamic> toJson() => {
        'tokenId': tokenId,
        'offerPrice': offerPrice,
        'offerCurrency': offerCurrency,
        'sellerWalletAddress': sellerWalletAddress,
        'sellerPayoutAddress': sellerPayoutAddress,
        'sellerEmail': sellerEmail,
        'validUntil': validUntil,
        'salt': salt,
        'encodedData': encodedData,
        'typedDataHash': typedDataHash,
        'chipSignature': chipSignature,
        'marketplaceContract': marketplaceContract,
        'offchainOfferId': offchainOfferId
      };
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
