import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:walletconnect_dart/walletconnect_dart.dart';
import 'package:ownerchip_whitelabel/services/walletconnect.services.dart';
import 'package:ownerchip_whitelabel/services/ipfs.services.dart';
import 'package:ownerchip_whitelabel/services/web3.services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

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

final ownerChipObjectProvider = StateNotifierProvider.family<
    OwnerChipObjectNotifier, OwnerChipObject, ChipInfo>((ref, chip) {
  return OwnerChipObjectNotifier(chip.chipEthereumAddress, chip.tokenId);
});

//****NFT METADATA****

final nftMetadataProvider = FutureProvider.autoDispose
    .family<Map<String, dynamic>, BigInt>((ref, tokenId) async {
  String tokenUri = await getTokenUri(tokenId);
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
