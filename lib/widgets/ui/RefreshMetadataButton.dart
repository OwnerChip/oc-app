import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ownerchip_whitelabel/services/providers/attachmentsData.dart';
import 'package:ownerchip_whitelabel/services/providers/chipData.dart';
import 'package:ownerchip_whitelabel/services/providers/collectionsData.dart';
import 'package:ownerchip_whitelabel/services/providers/nftData.dart';
import 'package:ownerchip_whitelabel/themes/colorSpecs.dart';

class RefreshMetadataButton extends ConsumerStatefulWidget {
  RefreshMetadataButton({
    super.key,
  });

  @override
  ConsumerState<RefreshMetadataButton> createState() =>
      _RefreshMetadataButtonState();
}

class _RefreshMetadataButtonState extends ConsumerState<RefreshMetadataButton> {
  bool loading = false;

  @override
  Widget build(BuildContext context) {
    return loading
        ? const Text('Loading..')
        : GestureDetector(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Unable to load metadata. Try again.'),
                Icon(Icons.refresh,
                    color: CustomColors(dotenv.get('APP_ID')).accentColor)
              ],
            ),
            onTap: () async {
              try {
                setState(() {
                  loading = true;
                });
                final chipInfo = ref.read(chipInfoProvider);
                await ref.refresh(findTokenProvider(chipInfo.tokenId).future);
                await ref.refresh(nftMetadataProvider(chipInfo.tokenId).future);
                await ref.refresh(fetchAttachmentsProvider.future);
                await ref
                    .refresh(voucherContractAndTwinNftOwnerProvider.future);

                setState(() {
                  loading = true;
                });
              } catch (e) {
                setState(() {
                  loading = false;
                });
                print(e);
              }
            },
          );
  }
}
