import 'package:json_annotation/json_annotation.dart';
import 'package:ownerchip_whitelabel/domain/converters/ethereumAddressJsonConverter.dart';
import 'package:ownerchip_whitelabel/domain/rarible/raribleAssetType/raribleAssetType.dart';
import 'package:ownerchip_whitelabel/domain/rarible/raribleDataObject/raribleDataObject.dart';
import 'package:ownerchip_whitelabel/domain/rarible/raribleOrderFormAsset/raribleOrderFormAsset.dart';
import 'package:ownerchip_whitelabel/domain/rarible/rariblePayout/rariblePayout.dart';
import 'package:web3dart/web3dart.dart';

part 'raribleV2Order.g.dart';

@JsonSerializable(explicitToJson: true)
class RaribleV2Order {
  factory RaribleV2Order.fromJson(Map<String, dynamic> json) =>
      _$RaribleV2OrderFromJson(json);

  Map<String, dynamic> toJson() => _$RaribleV2OrderToJson(this);

  final String type = "RARIBLE_V2";
  final RaribleDataObject data;

  @EthereumAddressJsonConverter()
  final EthereumAddress maker;
  final RaribleOrderFormAsset make;
  final RaribleOrderFormAsset take;
  final BigInt salt;
  final int start;
  final int end;
  final String signature;

  RaribleV2Order(
      {required this.data,
      required this.maker,
      required this.make,
      required this.take,
      required this.salt,
      required this.start,
      required this.end,
      required this.signature});

  RaribleV2Order setSignature(String signature) {
    return RaribleV2Order(
        data: data,
        maker: maker,
        make: make,
        take: take,
        salt: salt,
        start: start,
        end: end,
        signature: signature);
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
      String? signature) {
    final RariblePayout payout = RariblePayout(
        account: payoutAddress,
        value: payoutValue); //seller address (controller contract)
    final RariblePayout originFees =
    RariblePayout(account: originFeesAddress, value: originFeesValue);
    final RaribleDataObject dataObject = RaribleDataObject(
        dataType: "RARIBLE_V2_DATA_V1",
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
        take: take,
        salt: salt,
        //now in seconds
        start: DateTime.now().millisecondsSinceEpoch ~/ 1000,
        //end now in 10 months; 2629800 = 1 month in seconds
        end: DateTime.now().millisecondsSinceEpoch ~/ 1000 + 2629800 * 10,
        signature: signature ?? '');
    return raribleV2Order;
  }

}
