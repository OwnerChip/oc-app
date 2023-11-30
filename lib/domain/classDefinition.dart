import 'dart:convert';

import 'package:ownerchip_whitelabel/services/signature.services.dart';
import 'package:walletconnect_flutter_v2/walletconnect_flutter_v2.dart';
import 'package:web3dart/web3dart.dart';
import 'package:flutter/services.dart';
import 'package:web3dart/crypto.dart';
import 'package:file_picker/file_picker.dart';

class MoreInfoButton {
  final String text;
  final String url;

  MoreInfoButton(this.text, this.url);
}

class WalletType {
  final String name;
  final String iconUri;
  final String deeplinkUri;

  WalletType(this.name, this.iconUri, this.deeplinkUri);

  Map<String, dynamic> toJson() => {
        'name': name,
        'iconUri': iconUri,
        'deeplinkUri': deeplinkUri,
      };

  WalletType.fromJson(Map<String, dynamic> json)
      : name = json['name'],
        iconUri = json['iconUri'],
        deeplinkUri = json['deeplinkUri'];
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
  final String rpcUrl;
  final String registryContract;
  final String openseaUrl;
  final String raribleUrl;
  final String blockchainExplorerUrl;
  final String? forwarderContract;

  BlockchainConfig(
      {required this.networkName,
      required this.rpcUrl,
      required this.registryContract,
      required this.openseaUrl,
      required this.raribleUrl,
      required this.blockchainExplorerUrl,
      this.forwarderContract});
}

class TokenInfoObject {
  final int chainId;
  final EthereumAddress collectionId;
  final BigInt tokenId;

  TokenInfoObject(this.chainId, this.collectionId, this.tokenId);
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

  SignatureData({required this.hashedMsg, required this.signature});
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

  UserSession(this.sessionId, this.signatureData, this.userWalletAddress,
      this.isOwnerCard, this.expiryDate);

  Map<String, dynamic> toJson() => {
        'sessionId': sessionId,
        'signatureData': msgSignatureToJson(signatureData),
        'userWalletAddress': userWalletAddress.hex,
        'isOwnerCard': isOwnerCard,
        'expiryDate': expiryDate.toString(),
      };

  UserSession.fromJson(Map<String, dynamic> json)
      : sessionId = json['sessionId'],
        signatureData = msgSignatureFromJson(json['signatureData']),
        userWalletAddress = EthereumAddress.fromHex(json['userWalletAddress']),
        isOwnerCard = json['isOwnerCard'],
        expiryDate = int.parse(json['expiryDate']);
}

class CreatorData {
  final String name;
  final String affiliation;
  final String email;
  final EthereumAddress walletAddress;
  final DateTime createdAt;

  const CreatorData({
    required this.name,
    required this.affiliation,
    required this.email,
    required this.walletAddress,
    required this.createdAt,
  });
}
