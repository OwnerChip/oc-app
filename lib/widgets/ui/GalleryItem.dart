import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:ownerchip_whitelabel/domain/oc/oc_owned_nft.dart';
import 'package:ownerchip_whitelabel/screens/NFTDetailsScreen.dart';
import 'package:ownerchip_whitelabel/services/nfc.services.dart';
import 'package:ownerchip_whitelabel/themes/colorSpecs.dart';
import 'package:ownerchip_whitelabel/utils/utils.dart';
import 'package:ownerchip_whitelabel/widgets/ui/CustomCard.dart';
import 'package:ownerchip_whitelabel/widgets/ui/CustomImage.dart';
import 'package:reown_appkit/reown_appkit.dart';

class GalleryItem extends StatelessWidget {
  final OcOwnedNft item;
  final ref;

  const GalleryItem({
    super.key,
    required this.item,
    required this.ref,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        final BigInt chipTokenId = BigInt.parse(item.tokenId);
        final EthereumAddress chipEthereumAddress = EthereumAddress.fromHex(
            convertTokenIdToEthereumAddress(chipTokenId));
        setChipInfoProvider(ref, chipEthereumAddress, chipTokenId);

        Navigator.of(context).pushNamed(NFTDetailsScreen.routeName);
      },
      child: CustomCard(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        borderRadius: 19,
        children: [
          CustomImage(
            loading: false,
            imagePath: item.image.originalUrl,
            boxFit: BoxFit.cover,
            aspectRatio: 1,
          ),
          const SizedBox(
            height: 4,
          ),
          Flexible(
            child: Text(
              item.name ?? "",
              style: Theme.of(context).textTheme.headlineSmall!.copyWith(
                    color: CustomColors(dotenv.get('APP_ID')).accentColor,
                  ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
        ],
      ),
    );
  }
}
