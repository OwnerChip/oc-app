import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ownerchip_whitelabel/config/constants.dart';
import 'package:ownerchip_whitelabel/domain/classDefinition.dart';
import 'package:walletconnect_dart/walletconnect_dart.dart';
import 'package:ownerchip_whitelabel/services/walletconnect.services.dart';
import 'package:ownerchip_whitelabel/services/ipfs.services.dart';
import 'package:ownerchip_whitelabel/services/web3.services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:ownerchip_whitelabel/config/chains.dart';
import 'package:ownerchip_whitelabel/config/collections.dart';
import 'package:web3dart/web3dart.dart';
import 'package:ownerchip_whitelabel/utils/utils.dart';
import 'package:flutter/services.dart';
import 'package:web3dart/crypto.dart';

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

//**** SIGNATIURE DATA */

// final chipInfoProvider =
//     StateNotifierProvider<ChipInfoNotifier, ChipInfoModel>((ref) {
//   return ChipInfoNotifier();
// });

class SignatureDataNotifier extends StateNotifier<SignatureData> {
  SignatureDataNotifier()
      : super(SignatureData(
            hashedMsg: Uint8List(0),
            signature: MsgSignature(BigInt.from(0), BigInt.from(0), 0)));

  void setSignatureData(SignatureData signatureData) {
    state.hashedMsg = signatureData.hashedMsg;
    state.signature = signatureData.signature;
  }
}

final signatureDataProvider =
    StateNotifierProvider<SignatureDataNotifier, SignatureData>((ref) {
  return SignatureDataNotifier();
});

//****CHIP INFO****

class ChipInfoNotifier extends StateNotifier<ChipInfoModel> {
  ChipInfoNotifier()
      : super(ChipInfoModel(
            chipEthereumAddress: EthereumAddress.fromHex(zeroAddress),
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

final chainIdProvider = StateProvider.autoDispose<int>(
    (ref) => Collections(dotenv.get('APP_ID')).collections.keys.first);
// final chainIdProvider = StateProvider.autoDispose<int>((ref) => 1);

final collectionIdProvider = StateProvider.autoDispose<String>((ref) {
  final chainId = ref.watch(chainIdProvider);
  return Collections(dotenv.get('APP_ID')).collections[chainId]![0]['id']!;
});

// provider that returns chainId + collection if tokenId exists
final findTokenProvider = FutureProvider.autoDispose
    .family<TokenInfoObject, BigInt>((ref, tokenId) async {
  // TokenInfoObject res = TokenInfoObject(0, zeroAddress, tokenId); //default

  var result =
      await Future.wait<TokenInfoObject>(chainConfig.keys.map((chainId) async {
    var collectionId = await getCollectionId(chainConfig[chainId]!.rpcUrl,
        chainConfig[chainId]!.registryContract, tokenId);

    return TokenInfoObject(chainId, collectionId.toString(), tokenId);
  }));

  return result.firstWhere((element) => element.collectionId != zeroAddress,
      orElse: () => TokenInfoObject(0, zeroAddress, tokenId));
});

//****NFT OWNER ****

final nftOwnerProvider =
    FutureProvider.autoDispose<EthereumAddress>((ref) async {
  // watch chipInfoProvider
  final chipInfo = ref.watch(chipInfoProvider);
  final config = await ref.watch(findTokenProvider(chipInfo.tokenId).future);
  EthereumAddress nftOwner = await getOwner(
      getRPCUrlFromChainId(config.chainId),
      config.collectionId,
      chipInfo.tokenId);
  return nftOwner;
});

//****NFT METADATA****

final nftMetadataProvider = FutureProvider.autoDispose
    .family<Map<String, dynamic>, BigInt>((ref, tokenId) async {
  //TODO: get chain ID and collection ID from dropdown menu UI!
  final chipInfo = ref.watch(chipInfoProvider);
  final config = await ref.watch(findTokenProvider(chipInfo.tokenId).future);
  String tokenUri = await getTokenUri(
      getRPCUrlFromChainId(config.chainId), config.collectionId, tokenId);
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

final blockchainExplorerUrlProvider = Provider.autoDispose<Uri>((ref) {
  final chipInfo = ref.watch(chipInfoProvider);
  final chainId = ref.watch(chainIdProvider);
  final baseUrl = chainConfig[chainId]!.blockchainExplorerUrl;
  final contractAddress = ref.watch(collectionIdProvider);
  String explorerUrl = "$baseUrl/$contractAddress?a=${chipInfo.tokenId}";
  return Uri.parse(explorerUrl);
});

final openseaUrlProvider = Provider.autoDispose<Uri>((ref) {
  final chipInfo = ref.watch(chipInfoProvider);
  final chainId = ref.watch(chainIdProvider);
  final baseUrl = chainConfig[chainId]!.openseaUrl;
  final contractAddress = ref.watch(collectionIdProvider);
  String openseaUrl = "$baseUrl/$contractAddress/${chipInfo.tokenId}";
  return Uri.parse(openseaUrl);
});

final raribleUrlProvider = Provider.autoDispose<Uri>((ref) {
  final chipInfo = ref.watch(chipInfoProvider);
  final chainId = ref.watch(chainIdProvider);
  final baseUrl = chainConfig[chainId]!.raribleUrl;
  final contractAddress = ref.watch(collectionIdProvider);
  String raribleUrl = "$baseUrl/$contractAddress:${chipInfo.tokenId}";
  return Uri.parse(raribleUrl);
});
