import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:ownerchip_whitelabel/screens/NFTDetailsScreen.dart';
import 'package:ownerchip_whitelabel/services/nfc.services.dart';
import 'package:ownerchip_whitelabel/themes/colorSpecs.dart';
import 'package:ownerchip_whitelabel/utils/utils.dart';
import 'package:ownerchip_whitelabel/widgets/ui/CustomCard.dart';
import 'package:ownerchip_whitelabel/widgets/ui/CustomImage.dart';
import 'package:web3modal_flutter/web3modal_flutter.dart';

class GalleryItem extends StatelessWidget {
  final Map item;
  final ref;

  GalleryItem({
    Key? key,
    required this.item,
    required this.ref,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        final BigInt chipTokenId = BigInt.parse(item['tokenId']);
        final EthereumAddress chipEthereumAddress = EthereumAddress.fromHex(
            convertTokenIdToEthereumAddress(chipTokenId));
        setChipInfoProvider(ref, chipEthereumAddress, chipTokenId);

        Navigator.of(context).pushNamed(NFTDetailsScreen.routeName);
      },
      child: CustomCard(
        padding: const EdgeInsets.all(11),
        borderRadius: 19,
        children: [
          CustomImage(
            loading: false,
            imagePath: item['image']['originalUrl'],
            boxFit: BoxFit.cover,
            aspectRatio: 1,
          ),
          Text(
            item['name'].length > 10
                ? '${item['name'].substring(0, 10)}...'
                : item['name'],
            style: Theme.of(context).textTheme.headlineSmall!.copyWith(
                  color: CustomColors(dotenv.get('APP_ID')).accentColor,
                ),
          ),
        ],
      ),
    );
  }
}
