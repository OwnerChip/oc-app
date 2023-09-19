import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ownerchip_whitelabel/config/constants.dart';
import 'package:ownerchip_whitelabel/domain/classDefinition.dart';
import 'package:ownerchip_whitelabel/services/attachments.services.dart';
import 'package:web3dart/web3dart.dart';
import 'package:ownerchip_whitelabel/services/providers/walletconnectData.dart';
import 'package:ownerchip_whitelabel/services/providers/chipData.dart';
import 'package:ownerchip_whitelabel/services/providers/collectionsData.dart';
import 'package:ownerchip_whitelabel/services/providers/nftData.dart';
import 'package:ownerchip_whitelabel/services/providers/userData.dart';

//this provider fetches all attachments from backend, and saves them to localAttachmentsProvider!
//This is necessary to edit attachments locally!
final fetchAttachmentsProvider = FutureProvider.autoDispose((ref) async {
  //get tokenId from provider
  final ChipInfoModel chipInfo = ref.watch(chipInfoProvider);
  TokenInfoObject tokenInfo =
      await ref.read(findTokenProvider(chipInfo.tokenId).future);

  bool tokenExists = true;
  EthereumAddress nftOwner = zeroAddress;
  try {
    //check if connected wallet is nft owner
    nftOwner = await ref.read(nftOwnerProvider.future);
    print('nftOwner: $nftOwner');
  } catch (e) {
    print(e);
    if (e == 'No owner found.') {
      tokenExists =
          false; //if "No owner found." error is thrown, token does not exist
    }
  }
  final EthereumAddress userWalletAddress = ref.read(userAddressProvider);

  var response;

  //if token does not exist, the collectionId and chainId is given by the selected
  //collection and chain from selectedCollectionIdProvider and selectedChainIdProvider (selected on ChainSelectorScreen).
  //ATTENTION: This relies on the fact that attachments for non existing tokens are only fetched
  //after the user has selected a collection and chain on ChainSelectorScreen (e.g. on MetadataInputScreens)
  //IF token DOES exists, the collectionId is given by the tokenInfo (fetched from Blockchain)
  EthereumAddress collectionId;
  int? chainId = ref.read(selectedChainIdProvider);
  Collection? collection = ref.read(selectedCollectionIdProvider);
  if (!tokenExists && collection != null && chainId != null) {
    collectionId = collection.id;
    chainId = collection.chainId!;
  } else {
    collectionId = tokenInfo.collectionId;
    chainId = tokenInfo.chainId;
  }

  //if connected wallet is nft owner, get all (private and public) attachments
  //if token does not exist, the creator can fetch all attachments. This is
  //necessary to show all previously uploaded attachments in MetadataInputScreens
  if (!tokenExists || nftOwner == userWalletAddress) {
    SignatureData tokenSignatureData = ref.read(chipSignatureDataProvider);

    UserSession? userSession = ref.read(userSessionProvider);
    response = await getPublicAndPrivateAttachmentsFromBackend(
      userSession!,
      userWalletAddress,
      chainId,
      collectionId,
      chipInfo.tokenId,
    );
  } else {
    //get all public attachments
    response = await getPublicAttachmentsFromBackend(chipInfo.tokenId);
    print(response);
  }
  //create list of attachments
  List<Attachment> attachments = [];
  //create list of attachments
  for (var attachment in response.data) {
    attachments.add(Attachment(
      attachment['title'],
      attachment['name'],
      attachment['is_file'] ? AttachmentType.other : AttachmentType.url,
      attachment['url'],
      attachment['uuid'],
      isFromCreator: attachment['isFromCreator'],
      isPrivate: attachment['is_private'],
    ));
  }

  //set state of attachmentListProvider
  ref.read(localAttachmentsProvider.notifier).state = attachments;

  return attachments;
});

//This provider is used to display attachment data in the UI and to edit attachment data locally (which is then posted to backend)
final localAttachmentsProvider =
    StateProvider.autoDispose<List<Attachment>>((ref) {
  return [];
});

//provider with attachments only where isFromCreator == true
final creatorAttachmentsProvider =
    Provider.autoDispose<List<Attachment>>((ref) {
  final List<Attachment> attachments = ref.watch(localAttachmentsProvider);
  return attachments
      .where((e) => e.isFromCreator != null && e.isFromCreator!)
      .toList();
});

//provider with attachments only where isFromCreator == false
final ownerAttachmentsProvider = Provider.autoDispose<List<Attachment>>((ref) {
  final List<Attachment> attachments = ref.watch(localAttachmentsProvider);
  return attachments
      .where((e) => e.isFromCreator != null && !e.isFromCreator!)
      .toList();
});
