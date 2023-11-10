import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:ownerchip_whitelabel/domain/classDefinition.dart';
import 'package:ownerchip_whitelabel/themes/colorSpecs.dart';
import 'package:ownerchip_whitelabel/utils/localization.helper.dart';
import 'package:ownerchip_whitelabel/widgets/popups/CustomPopup.dart';
import 'package:ownerchip_whitelabel/widgets/ui/CustomOutlinedButton.dart';
import 'package:ownerchip_whitelabel/widgets/ui/DisplayLongStringWithCopy.dart';
import 'package:ownerchip_whitelabel/widgets/ui/InfoKeyValues.dart';
import 'package:ownerchip_whitelabel/utils/utils.dart';

class CreatorDataBoxContent extends StatelessWidget {
  const CreatorDataBoxContent({
    super.key,
    required this.creatorData,
  });

  final CreatorData creatorData;

  // void function
  void triggerPopup(BuildContext context) {
    showCustomPopup(
        context,
        context.loc.creatorData,
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            InfoKeyValues(keyWidth: 83, valueWidth: 169, keys: [
              'Name',
              'Affiliation',
              context.loc.createdAt,
              'Wallet'
            ], values: [
              creatorData.name,
              creatorData.affiliation,
              formatDate(creatorData.createdAt.toString().substring(0, 10)),
              DisplayLongStringWithCopy(
                string: creatorData.walletAddress.hex,
                textStyles: Theme.of(context).textTheme.headlineSmall,
              )
            ])
          ],
        ));
  }

  @override
  Widget build(BuildContext context) {
    //Text where one word is tappable (detects gestures)
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          runSpacing: 5,
          children: [
            Text(
              context.loc.digitalTwinVerifiedBy,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(
              height: 10,
            ),
            GestureDetector(
              onTap: () {
                triggerPopup(context);
              },
              child: Text(
                creatorData.name,
                style: Theme.of(context).textTheme.bodyText1!.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).primaryColorLight,
                    ),
              ),
            ),
            const SizedBox(
              width: 5,
            ),
            Icon(
              size: 17,
              Icons.verified,
              color: CustomColors(dotenv.get('APP_ID')).accentColor,
            ),
          ],
        ),
        const SizedBox(height: 10),
        CustomOutlinedButton(
            width: double.infinity,
            height: 28,
            buttonText: context.loc.showCreatorData,
            onPressed: () {
              triggerPopup(context);
            })
      ],
    );
  }
}
