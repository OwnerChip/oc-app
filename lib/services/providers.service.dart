import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ownerchip_whitelabel/domain/classDefinition.dart';
import 'package:walletconnect_dart/walletconnect_dart.dart';
import 'package:ownerchip_whitelabel/services/walletconnect.services.dart';
import 'package:ownerchip_whitelabel/services/ipfs.services.dart';
import 'package:ownerchip_whitelabel/services/web3.services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:ownerchip_whitelabel/config/chains.dart';
import 'package:web3dart/web3dart.dart';
import 'package:ownerchip_whitelabel/utils/utils.dart';

//****WALLETCONNECT****

final walletConnectProvider =
    StateNotifierProvider<WalletConnector, WalletConnect>((ref) {
  return WalletConnector();
});

class WalletConnector extends StateNotifier<WalletConnect> {
  WalletConnector()
      : super(WalletConnect(
            bridge: 'https://bridge.walletconnect.org',
            clientMeta: const PeerMeta(
              name: 'OwnerChip Demo',
              description: 'Connecting physical objects to the blockchain.',
              url: 'https://walletconnect.org',
              // icons: ["${dotenv.get('IMAGE_ASSETS_BASE_URL')}/app_logo.png"]
            )));
  void resetWalletConnector() async {
    state = await createWalletConnector();
  }
}

//chain ID provider
final chainIdProvider = StateProvider.autoDispose<int>((ref) => 0);

//collection ID provider from dropdown (admin app)
final collectionIdProvider = StateProvider.autoDispose<String>((ref) => "");

//****CHIP INFO****

class ChipInfoNotifier extends StateNotifier<ChipInfoModel> {
  ChipInfoNotifier()
      : super(ChipInfoModel(
            chipEthereumAddress: EthereumAddress.fromHex(
                '0x0000000000000000000000000000000000000000'),
            tokenId: BigInt.from(0)));

  void setTokenId(BigInt tokenId) {
    state.tokenId = tokenId;
  }

  void setChipEthereumAddress(EthereumAddress chipEthereumAddress) {
    state.chipEthereumAddress = chipEthereumAddress;
  }

  void setChipToInitialized() {
    state.chipIsInitialized = true;
  }
}

final chipInfoProvider =
    StateNotifierProvider<ChipInfoNotifier, ChipInfoModel>((ref) {
  return ChipInfoNotifier();
});

// **** CHAIN ID + COLLECTION ID ****

// provider that returns chainId + collection if tokenId exists
final findTokenProvider = FutureProvider.autoDispose
    .family<List<dynamic>, BigInt>((ref, tokenId) async {
  List<dynamic> res = [
    0,
    EthereumAddress.fromHex('0x0000000000000000000000000000000000000000')
  ];
  // loop over keys of map of chain configs
  for (var chainId in chainConfig.keys) {
    // query registry
    EthereumAddress collectionId = await getCollectionId(
        chainConfig[chainId]!.rpcUrl,
        chainConfig[chainId]!.registryContract,
        tokenId);
    if (collectionId !=
        EthereumAddress.fromHex('0x0000000000000000000000000000000000000000')) {
      // if tokenId exists, return collectionID + chainId
      res = [chainId, collectionId.toString()];
      break;
    }
  }

  // return [137, '0x6fe0Fd3f6430DcFF517Cd939815Fab115B033679'];
  return res;

  //TODO: try catch for when no token is found!
});

//****NFT OWNER ****

final nftOwnerProvider =
    FutureProvider.autoDispose<EthereumAddress>((ref) async {
  // watch chipInfoProvider
  final chipInfo = ref.watch(chipInfoProvider);
  final config = await ref.watch(findTokenProvider(chipInfo.tokenId).future);
  EthereumAddress nftOwner = await getOwner(
      getRPCUrlFromChainId(config[0]), config[1], chipInfo.tokenId);
  return nftOwner;
});

//****NFT METADATA****

final nftMetadataProvider = FutureProvider.autoDispose
    .family<Map<String, dynamic>, BigInt>((ref, tokenId) async {
  //TODO: get chain ID and collection ID from dropdown menu UI!
  final chipInfo = ref.watch(chipInfoProvider);
  final config = await ref.watch(findTokenProvider(chipInfo.tokenId).future);
  String tokenUri =
      await getTokenUri(getRPCUrlFromChainId(config[0]), config[1], tokenId);
  String cid = getCidFromIpfsLink(tokenUri);
  var result = await downloadMetadataFromIPFS(cid);
  return result;
});

final nftImageProvider =
    FutureProvider.autoDispose.family<String, BigInt>((ref, tokenId) async {
  final nftMetadata = await ref.watch(nftMetadataProvider(tokenId).future);
  String cid = getCidFromIpfsLink(nftMetadata['image']);
  String imageUri = "${dotenv.get('IPFS_GATEWAY')}$cid";
  return imageUri;
});

//token ID provider
final tokenIdProvider =
    StateProvider.autoDispose<BigInt>((ref) => BigInt.from(0));

final blockchainExplorerUrlProvider = Provider.autoDispose<Uri>((ref) {
  final tokenId = ref.watch(tokenIdProvider);
  final chainId = ref.watch(chainIdProvider);
  final baseUrl = chainConfig[chainId]!.openseaUrl;
  final contractAddress = ref.watch(collectionIdProvider);
  String explorerUrl = "${baseUrl}token/$contractAddress?a=$tokenId";
  return Uri.parse(explorerUrl);
});

final openseaUrlProvider = Provider.autoDispose<Uri>((ref) {
  final tokenId = ref.watch(tokenIdProvider);
  final chainId = ref.watch(chainIdProvider);
  final baseUrl = chainConfig[chainId]!.openseaUrl;
  final contractAddress = ref.watch(collectionIdProvider);
  String openseaUrl = "$baseUrl/$contractAddress/$tokenId";
  return Uri.parse(openseaUrl);
});

final raribleUrlProvider = Provider.autoDispose<Uri>((ref) {
  final tokenId = ref.watch(tokenIdProvider);
  final chainId = ref.watch(chainIdProvider);
  final baseUrl = chainConfig[chainId]!.raribleUrl;
  final contractAddress = ref.watch(collectionIdProvider);
  String raribleUrl = "$baseUrl/$contractAddress:$tokenId";
  return Uri.parse(raribleUrl);
});
