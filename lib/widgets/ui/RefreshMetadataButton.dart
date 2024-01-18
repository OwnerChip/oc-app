import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nfc_manager/nfc_manager.dart';
import 'package:ownerchip_whitelabel/screens/HomeScreen.dart';
import 'package:ownerchip_whitelabel/services/providers/attachmentsData.dart';
import 'package:ownerchip_whitelabel/services/providers/chipData.dart';
import 'package:ownerchip_whitelabel/services/providers/nftData.dart';
import 'package:ownerchip_whitelabel/services/nfc.services.dart';
import 'package:ownerchip_whitelabel/themes/colorSpecs.dart';
import 'package:ownerchip_whitelabel/utils/localization.helper.dart';
import 'package:ownerchip_whitelabel/widgets/popups/returnSnackBarWidget.dart';
import 'package:ownerchip_whitelabel/widgets/ui/CustomRoundedButton.dart';

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
                var i = await ref
                    .refresh(findTokenProvider(chipInfo.tokenId).future);
                var d = await ref
                    .refresh(nftMetadataProvider(chipInfo.tokenId).future);
                var a = await ref.refresh(fetchAttachmentsProvider.future);
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
