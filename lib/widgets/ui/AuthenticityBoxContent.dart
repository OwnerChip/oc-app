import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:ownerchip_whitelabel/domain/classDefinition.dart';
import 'package:ownerchip_whitelabel/themes/colorSpecs.dart';
import 'package:ownerchip_whitelabel/utils/localization.helper.dart';
import 'package:ownerchip_whitelabel/widgets/popups/CustomPopup.dart';
import 'package:ownerchip_whitelabel/widgets/ui/InfoKeyValues.dart';
import 'package:web3dart/web3dart.dart';

class AuthenticityBoxContent extends StatelessWidget {
  const AuthenticityBoxContent({
    super.key,
    required this.creatorData,
  });

  final CreatorData creatorData;

  @override
  Widget build(BuildContext context) {
    //Text where one word is tappable (detects gestures)
    return Wrap(
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
            showCustomPopup(
                context,
                context.loc.creatorData,
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    InfoKeyValues(keyWidth: 77, valueWidth: 175, keys: [
                      'Name',
                      // 'Email',
                      'Affiliation'
                    ], values: [
                      creatorData.name,
                      // creatorData.email,
                      creatorData.affiliation
                    ])
                    // Row(
                    //   mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    //   children: [
                    //     Text('Name: '),
                    //     Text(creatorData.name),
                    //   ],
                    // ),
                    // Row(
                    //   mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    //   children: [
                    //     Text('Email: '),
                    //     Flexible(child: Text(creatorData.email)),
                    //   ],
                    // ),
                    // Row(
                    //   mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    //   children: [
                    //     Text('Org.: '),
                    //     Flexible(child: Text(creatorData.affiliation)),
                    //   ],
                    // ),
                  ],
                ));
          },
          child: Text(
            creatorData.name,
            style: Theme.of(context).textTheme.bodyText1!.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).primaryColorLight,
                ),
          ),
        ),
        //verified icon from material icons
        const SizedBox(
          width: 5,
        ),
        //verified icon from material icons
        Icon(
          size: 17,
          Icons.verified,
          color: CustomColors(dotenv.get('APP_ID')).accentColor,
        ),
      ],
    );
  }
}
