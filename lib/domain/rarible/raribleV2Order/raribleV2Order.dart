import 'package:ownerchip_whitelabel/config/chains.dart';
import 'package:ownerchip_whitelabel/domain/blockchain_token.dart';
import 'package:ownerchip_whitelabel/domain/rarible/raribleAssetType/raribleAssetType.dart';
import 'package:ownerchip_whitelabel/domain/rarible/raribleDataObject/raribleDataObject.dart';
import 'package:ownerchip_whitelabel/domain/rarible/raribleOrderFormAsset/raribleOrderFormAsset.dart';
import 'package:ownerchip_whitelabel/domain/rarible/rariblePayout/rariblePayout.dart';
import 'package:ownerchip_whitelabel/services/rarible.services.dart';
import 'package:web3dart/web3dart.dart';

// part 'raribleV2Order.g.dart';

// @JsonSerializable(explicitToJson: true)
class RaribleV2Order {
  final String type = "RARIBLE_V2";
  final RaribleDataObject data;
  final EthereumAddress maker;
  final RaribleOrderFormAsset make;
  final RaribleOrderFormAsset takeDeprecated;
  final String take;
  final Map<String, dynamic> takeType;
  final BigInt salt;
  final int start;
  final int end;
  final String signature;

  final int chainId;

  final BlockchainToken? blockchainToken;

  RaribleV2Order({
    required this.data,
    required this.maker,
    required this.make,
    required this.take,
    required this.takeType,
    required this.takeDeprecated,
    required this.salt,
    required this.start,
    required this.end,
    required this.signature,
    required this.chainId,
    this.blockchainToken,
  });

  RaribleV2Order setSignature(String signature) {
    return RaribleV2Order(
      data: data,
      maker: maker,
      make: make,
      take: take,
      takeType: takeType,
      takeDeprecated: takeDeprecated,
      salt: salt,
      start: start,
      end: end,
      signature: signature,
      chainId: chainId,
      blockchainToken: blockchainToken,
    );
  }

  factory RaribleV2Order.makeRaribleV2Order(
    EthereumAddress payoutAddress,
    EthereumAddress originFeesAddress,
    BigInt tokenId,
    EthereumAddress makerAddress,
    int payoutValue,
    int originFeesValue,
    EthereumAddress voucherContractAddress,
    BigInt voucherTokenId,
    BigInt salePriceInCrypto,
    String? signature,
    int chainId,
    BlockchainToken? blockchainToken,
  ) {
    final RariblePayout payout = RariblePayout(
      account: payoutAddress,
      value: payoutValue,
      chainId: chainId,
    ); //seller address (controller contract)
    final RariblePayout originFees = RariblePayout(
      account: originFeesAddress,
      value: originFeesValue,
      chainId: chainId,
    );
    final RaribleDataObject dataObject = RaribleDataObject(
        dataType: "ETH_RARIBLE_V2",
        payouts: [payout],
        originFees: [originFees]);
    final EthereumAddress maker =
        makerAddress; //seller address (controller contract)
    final make = RaribleOrderFormAsset(
        assetType: RaribleAssetType(
            assetClass: "ERC721",
            contract: voucherContractAddress,
            tokenId: voucherTokenId),
        value: BigInt.from(1));
    final take = RaribleOrderFormAsset(
        assetType:
            RaribleAssetType(assetClass: "ETH", contract: null, tokenId: null),
        value: salePriceInCrypto);
    final BigInt salt = BigInt.from(DateTime.now().millisecondsSinceEpoch);
    final RaribleV2Order raribleV2Order = RaribleV2Order(
      data: dataObject,
      maker: maker,
      make: make,
      takeDeprecated: take,
      take: salePriceInCrypto.toString(),
      takeType: getRaribleAssetType(chainId, blockchainToken),
      salt: salt,
      //now in seconds
      start: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      //end now in 10 months; 2629800 = 1 month in seconds
      end: DateTime.now().millisecondsSinceEpoch ~/ 1000 + 2629800 * 10,
      signature: signature ?? '',
      chainId: chainId,
      blockchainToken: blockchainToken,
    );
    return raribleV2Order;
  }

  Map<String, dynamic> toJson() {
    final chain = chainConfig[chainId]!;
    return {
      '@type': type,
      'data': {
        '@type': data.dataType,
        'payouts': data.payouts.map((e) => e.toJson()).toList(),
        'originFees': data.originFees.map((e) => e.toJson()).toList(),
      },
      'maker': "ETHEREUM:${maker.hex}",
      'make': {
        'assetType': {
          '@type': make.assetType.assetClass,
          'contract': "ETHEREUM:${make.assetType.contract?.hex}",
          'tokenId': make.assetType.tokenId.toString(),
        },
        'value': make.value.toString(),
      },
      'take': {
        'assetType': takeType,
        'value': take.toString(),
      },
      'salt': salt.toString(),
      'startedAt': start,
      'endedAt': end,
      'signature': signature,
      "blockchain": chain.raribleEnum,
    };
  }

  Map<String, dynamic> toJsonDeprecated() {
    return {
      'type': type,
      'data': {
        'dataType': data.dataType,
        'payouts': data.payouts.map((e) => e.toJsonDeprecated()).toList(),
        'originFees': data.originFees.map((e) => e.toJsonDeprecated()).toList(),
      },
      'maker': maker.hex,
      'make': {
        'assetType': {
          'assetClass': make.assetType.assetClass,
          'contract': make.assetType.contract?.hex,
          'tokenId': make.assetType.tokenId.toString(),
        },
        'value': make.value.toString(),
      },
      'take': {
        'assetType': {
          'assetClass': takeType['@type'],
          'contract': takeType['contract']?.toString().split(':')[1],
          'tokenId': takeType['tokenId']?.toString(),
        },
        'value': take.toString(),
      },
      'salt': salt.toString(),
      'start': start,
      'end': end,
      'signature': signature,
    };
  }
}
