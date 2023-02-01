import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ownerchip_whitelabel/domain/classDefinition.dart';
import 'package:walletconnect_dart/walletconnect_dart.dart';
import 'package:ownerchip_whitelabel/services/walletconnect.services.dart';
import 'package:ownerchip_whitelabel/services/ipfs.services.dart';
import 'package:ownerchip_whitelabel/services/web3.services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:ownerchip_whitelabel/config/chains.dart';

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

//token ID provider
final tokenIdProvider =
    StateProvider.autoDispose<BigInt>((ref) => BigInt.from(0));

//chain ID provider
final chainIdProvider = StateProvider.autoDispose<int>((ref) => 0);

//collection ID provider from dropdown (admin app)
final collectionIdProvider = StateProvider.autoDispose<String>((ref) => "");

// provider that returns chainId + collection if tokenId exists
final findTokenProvider = FutureProvider.autoDispose
    .family<List<dynamic>, BigInt>((ref, tokenId) async {
  List<dynamic> res = [0, 0];
  // loop over keys of map of chain configs
  for (var chainId in chainConfig.keys) {
    // query registry
    var result = await getCollectionId(chainConfig[chainId]!.rpcUrl,
        chainConfig[chainId]!.registryContract, tokenId);
    if (result != null) {
      // if tokenId exists, return collectionID + chainId
      res = [chainId.toString(), result];
      break;
    }
  }
  return res;
});
//****CHIP INFO****

class ChipInfo {
  ChipInfo({this.chipEthereumAddress, this.tokenId});
  String? chipEthereumAddress;
  BigInt? tokenId;
}

class ChipInfoNotifier extends StateNotifier<ChipInfo> {
  ChipInfoNotifier() : super(ChipInfo());

  void setTokenId(BigInt tokenId) {
    state.tokenId = tokenId;
  }

  void setChipEthereumAddress(String chipEthereumAddress) {
    state.chipEthereumAddress = chipEthereumAddress;
  }
}

final chipInfoProvider =
    StateNotifierProvider<ChipInfoNotifier, ChipInfo>((ref) {
  return ChipInfoNotifier();
});

//****OWNERCHIP OBJECT****

class OwnerChipObject {
  OwnerChipObject(this.chipIsInitialized, this.nftOwner,
      this.chipEthereumAddress, this.tokenId);
  bool chipIsInitialized;
  String nftOwner;
  String? chipEthereumAddress;
  BigInt? tokenId;
}

class OwnerChipObjectNotifier extends StateNotifier<OwnerChipObject> {
  OwnerChipObjectNotifier(this.chipEthereumAddress, this.tokenId)
      : super(OwnerChipObject(false, '', chipEthereumAddress, tokenId));
  String? chipEthereumAddress;
  BigInt? tokenId;

  void setChipToInitialized(OwnerChipObject chip) {
    state.chipIsInitialized = true;
  }

  void updateNftOwner(String nftOwner) {
    state.nftOwner = nftOwner;
  }
}
s
final ownerChipObjectProvider = StateNotifierProvider.family<
    OwnerChipObjectNotifier, OwnerChipObject, ChipInfo>((ref, chip) {
  return OwnerChipObjectNotifier(chip.chipEthereumAddress, chip.tokenId);
});

//****NFT METADATA****

final nftMetadataProvider = FutureProvider.autoDispose
    .family<Map<String, dynamic>, TokenInfoObject>((ref, tokenInfo) async {
  String tokenUri = await getTokenUri(
      tokenInfo.rpcUrl, tokenInfo.collectionId, tokenInfo.tokenId);
  String cid = getCidFromIpfsLink(tokenUri);
  var result = await downloadMetadataFromIPFS(cid);
  return result;
});

final nftImageProvider = FutureProvider.autoDispose
    .family<String, TokenInfoObject>((ref, tokenInfo) async {
  final nftMetadata = await ref.watch(nftMetadataProvider(tokenInfo).future);
  String cid = getCidFromIpfsLink(nftMetadata['image']);
  String imageUri = "${dotenv.get('IPFS_GATEWAY')}$cid";
  return imageUri;
});

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
