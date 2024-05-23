import 'package:ownerchip_whitelabel/domain/blockchainCollectionList/blockchainCollectionList.dart';
import 'package:ownerchip_whitelabel/domain/collection/collection.dart';
import 'package:web3dart/web3dart.dart';

// as fallback only!
final BlockchainCollectionList allCollections = BlockchainCollectionList({
  1: [
    Collection(
        EthereumAddress.fromHex('0xD0a61ca8F851e70AC50f7C33c943018A47104763'),
        "OwnerChip Collection"),
    Collection(
        EthereumAddress.fromHex("0xE587fb76509550a72Eb120b941F9235488aB6AEe"),
        "SteboArt"),
    Collection(
        EthereumAddress.fromHex("0x5C058D97C3d088114c913caEE134807a0b5c0852"),
        "ArtsyApes"),
  ],
  137: [
    Collection(
        EthereumAddress.fromHex('0x1787f9469238E2113CdF83e15F169FBA15F884f5'),
        "OwnerChip Demo"),
    Collection(
        EthereumAddress.fromHex('0xEF5B50BB76B416e7435C22A0c1Dec829da9839d1'),
        "OwnerChip Community"),
    Collection(
        EthereumAddress.fromHex("0xE95232cdA853989B86fF8beC94EaEfA78cF35668"),
        "SteboArt"),
    Collection(
        EthereumAddress.fromHex("0x5326064FD9a82EC2a095104E7c37c25D36155034"),
        "SteboArt Workshop 1"),
    Collection(
        EthereumAddress.fromHex("0x5662E8b29a8131Bd7A281a43BcfEfce1e369aa7C"),
        "SteboArt Workshop Heroes"),
    Collection(
        EthereumAddress.fromHex("0x9F0F89f4949B6ca233aB38F0FD1d5eFEE97aeF66"),
        "SteboArt Workshop CoolPeople"),
    Collection(
        EthereumAddress.fromHex("0x6366cf5b9caEA13D4a04Bb6fEb67dE293810C786"),
        "SteboArt Workshop Superstars"),
    Collection(
        EthereumAddress.fromHex("0xFA4c465D82B8419f3A8AF0ec615E1bcA1D86Ac63"),
        "ArtsyApes"),
  ],
  // 80001: [
  //   Collection(
  //       EthereumAddress.fromHex('0x91930a50a20625f1eb2c2Ce04535fDFF657B5b8a'),
  //       "Demo Collection"),
  //   Collection(
  //       EthereumAddress.fromHex('0x82a225C01F70828A415bB576f1C334928aE32b29'),
  //       "Stebo Demo"),
  //   Collection(
  //       EthereumAddress.fromHex('0x163a80d5D7E2e1d256D7083E4b04Cd873e30f6d2'),
  //       "Stebo Demo (old)"),
  // ]
});

/// helper function
Map<int, List<Collection>> groupCollectionsByChainId(
    List<dynamic> collections) {
  Map<int, List<Collection>> result = {};

  for (dynamic collection in collections) {
    //check if voucherAddress exists, if yes convert it to EthereumAddress
    final EthereumAddress? voucherAddress =
        collection['voucher_address'].isNotEmpty
            ? EthereumAddress.fromHex(collection['voucher_address'])
            : null;
    var col = Collection(
        EthereumAddress.fromHex(collection["address"]), collection["name"],
        voucherAddress: voucherAddress);
    int chainId = collection["chainId"];

    if (result.containsKey(chainId)) {
      result[chainId]!.add(col);
    } else {
      result[chainId] = [col];
    }
  }

  return result;
}
